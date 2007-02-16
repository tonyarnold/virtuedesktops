/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2007, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import <Cocoa/Cocoa.h>
#import <stdio.h>
#import <sys/param.h>

int main(int argc, char *argv[]) {
  char *val_buf, path_buf[MAXPATHLEN];

  val_buf = getenv("HOME");
  sprintf(path_buf,"%s/Library/Logs/VirtueDesktops.log",val_buf);
  freopen(path_buf,"a",stderr);
  
  return NSApplicationMain(argc,  (const char **) argv);
}
