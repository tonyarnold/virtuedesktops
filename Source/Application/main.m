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
  id pool = [NSAutoreleasePool new];
  
  NSString *applicationName = [NSString stringWithFormat: @"Library/Logs/%@.log", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"]]; 
  NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent: applicationName];
	freopen([logPath fileSystemRepresentation], "a", stderr);
  
  [pool release];
  
  return NSApplicationMain(argc,  (const char **) argv);
}
