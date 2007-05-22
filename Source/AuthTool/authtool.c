/*
 *  authtool.c
 *  VirtueDesktops
 *
 *  Created by Tony on 14/06/06.
 *  Copyright 2007 boomBalada! Productions. All rights reserved.
 *
 */

#include "authtool.h"

#include <Security/AuthorizationTags.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <sys/fcntl.h>
#include <sys/errno.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <mach-o/dyld.h>
#include <grp.h> 

/* Get procmod group identifier */
static int
getProcmodGid()
{
   struct group* groupDesc;
   groupDesc = getgrnam("procmod");
   if (groupDesc) {
       return groupDesc->gr_gid;
   }
   return 9;
}

/* Perform the operation specified in myCommand. */
static bool
performOperation(const MyAuthorizedCommand * myCommand)
{
  /* XXX perform the actual operation here */
	
	char info[MAXPATHLEN];
	struct stat st;
	
  IFDEBUG(fprintf(stderr, "Tool performing command on path %s.\n", myCommand->file);)
  IFDEBUG(fprintf(stderr, "uid = %d, euid = %d\n", getuid(), geteuid());)
    
  // Stat the file to get the uid and the mode
  if (stat(myCommand->file, &st)) {
    snprintf(info, MAXPATHLEN, "stat %s", myCommand->file);
    perror(info);
    return false;
  }
	
	
	// Set group to procmod
	if (chown(myCommand->file, st.st_uid, getProcmodGid())) {
		snprintf(info, MAXPATHLEN, "chown %s", myCommand->file);
		perror(info);
		return false;
	}	
	
	// Set the set-group-ID-on-execution bit
	if (chmod(myCommand->file, st.st_mode | S_ISGID)) {
		snprintf(info, MAXPATHLEN, "chmod %s", myCommand->file);
		perror(info);
		return false;
	}
	
  return true;
}

int
main(int argc, char * const *argv)
{
  OSStatus status;
  AuthorizationRef auth;
  int bytesRead;
  MyAuthorizedCommand myCommand;
  
  uint32_t path_to_self_size = 0;
  char *path_to_self = NULL;
  
  path_to_self_size = MAXPATHLEN;
  if (! (path_to_self = malloc(path_to_self_size)))
    exit(kMyAuthorizedCommandInternalError);
  if (_NSGetExecutablePath(path_to_self, &path_to_self_size) == -1)
  {
    /* Try again with actual size */
    if (! (path_to_self = realloc(path_to_self, path_to_self_size + 1)))
      exit(kMyAuthorizedCommandInternalError);
    if (_NSGetExecutablePath(path_to_self, &path_to_self_size) != 0)
      exit(kMyAuthorizedCommandInternalError);
  }                
  
  if (argc == 2 && !strcmp(argv[1], "--self-repair"))
  {
    /*  Self repair code.  We ran ourselves using AuthorizationExecuteWithPrivileges()
    so we need to make ourselves setuid root to avoid the need for this the next time around. */
    
    struct stat st;
    int fd_tool;
    
    /* Recover the passed in AuthorizationRef. */
    if (AuthorizationCopyPrivilegedReference(&auth, kAuthorizationFlagDefaults))
      exit(kMyAuthorizedCommandInternalError);
    
    /* Open tool exclusively, so noone can change it while we bless it */
    fd_tool = open(path_to_self, O_NONBLOCK|O_RDONLY|O_EXLOCK, 0);
    
    if (fd_tool == -1)
    {
      IFDEBUG(fprintf(stderr, "Exclusive open while repairing tool failed: %d.\n", errno);)
      exit(kMyAuthorizedCommandInternalError);
    }
    
    if (fstat(fd_tool, &st))
      exit(kMyAuthorizedCommandInternalError);
    
    if (st.st_uid != 0)
      fchown(fd_tool, 0, st.st_gid);
    
    /* Disable group and world writability and make setuid root. */
    fchmod(fd_tool, (st.st_mode & (~(S_IWGRP|S_IWOTH))) | S_ISUID);
    
    close(fd_tool);
    
    IFDEBUG(fprintf(stderr, "Tool self-repair done.\n");)
      
  }
  else
  {
    AuthorizationExternalForm extAuth;
    
    /* Read the Authorization "byte blob" from our input pipe. */
    if (read(0, &extAuth, sizeof(extAuth)) != sizeof(extAuth))
      exit(kMyAuthorizedCommandInternalError);
    
    /* Restore the externalized Authorization back to an AuthorizationRef */
    if (AuthorizationCreateFromExternalForm(&extAuth, &auth))
      exit(kMyAuthorizedCommandInternalError);
    
    /* If we are not running as root we need to self-repair. */
    if (geteuid() != 0)
    {
      int status;
      int pid;
      FILE *commPipe = NULL;
      char *arguments[] = { "--self-repair", NULL };
      char buffer[1024];
      int bytesRead;
      
      /* Set our own stdin and stdout to be the communication channel with ourself. */
      
      IFDEBUG(fprintf(stderr, "Tool about to self-exec through AuthorizationExecuteWithPrivileges.\n");)
        
        if (AuthorizationExecuteWithPrivileges(auth, path_to_self, kAuthorizationFlagDefaults, arguments, &commPipe))
          exit(kMyAuthorizedCommandInternalError);
      
      /* Read from stdin and write to commPipe. */
      for (;;)
      {
        bytesRead = read(0, buffer, 1024);
        if (bytesRead < 1) break;
        fwrite(buffer, 1, bytesRead, commPipe);
      }
      
      /* Flush any remaining output. */
      fflush(commPipe);
      
      /* Close the communication pipe to let the child know we are done. */
      fclose(commPipe);
      
      /* Wait for the child of AuthorizationExecuteWithPrivileges to exit. */
      pid = wait(&status);
      if (pid == -1 || ! WIFEXITED(status))
        exit(kMyAuthorizedCommandInternalError);
      
      /* Exit with the same exit code as the child spawned by AuthorizationExecuteWithPrivileges() */
      exit(WEXITSTATUS(status));
    }
  }
  
  /* No need for it anymore */
  if (path_to_self)
    free(path_to_self);
  
  /* Read a 'MyAuthorizedCommand' object from stdin. */
  bytesRead = read(0, &myCommand, sizeof(MyAuthorizedCommand));
  
  /* Make sure that we received a full 'MyAuthorizedCommand' object */
  if (bytesRead == sizeof(MyAuthorizedCommand))
  {
    AuthorizationItem right = { kAuthorizationRightExecute, 0, NULL, 0 } ;
    AuthorizationRights rights = { 1, &right };
    AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed
      | kAuthorizationFlagExtendRights;
    
    /* Check to see if the user is allowed to perform the tasks stored in 'myCommand'. This may
      or may not prompt the user for a password, depending on how the system is configured. */
    
    IFDEBUG(fprintf(stderr, "Tool authorizing right %s for command.\n", kAuthorizationRightExecute);)
      
      if (status = AuthorizationCopyRights(auth, &rights, kAuthorizationEmptyEnvironment, flags, NULL))
      {
        IFDEBUG(fprintf(stderr, "Tool authorizing command failed authorization: %ld.\n", status);)
        exit(kMyAuthorizedCommandAuthFailed);
      }
    
    /* Peform the opertion stored in 'myCommand'. */
    if (!performOperation(&myCommand))
      exit(kMyAuthorizedCommandOperationFailed);
  }
  else
  {
    exit(kMyAuthorizedCommandChildError);
  }
  
  exit(kMyAuthorizedCommandSuccess);
}
