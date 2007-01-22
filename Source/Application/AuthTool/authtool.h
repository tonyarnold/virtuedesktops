/*
 *  authtool.h
 *  VirtueDesktops
 *
 *  Created by Tony on 14/06/06.
 *  Copyright 2007 boomBalada! Productions. All rights reserved.
 *
 */

#include <Security/Authorization.h>
#include <sys/param.h>

#if defined(DEBUG)
# define IFDEBUG(code)		code
#else
# define IFDEBUG(code)		/* no-op */
#endif


// Command structure
typedef struct MyAuthorizedCommand
{
  // Arguments to operate on
  char file[MAXPATHLEN];
} MyAuthorizedCommand;


// Exit codes (positive values) and return codes from exec function
enum
{
  kMyAuthorizedCommandInternalError = -1,
  kMyAuthorizedCommandSuccess = 0,
  kMyAuthorizedCommandExecFailed,
  kMyAuthorizedCommandChildError,
  kMyAuthorizedCommandAuthFailed,
  kMyAuthorizedCommandOperationFailed
};
