/******************************************************************************
* 
* Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import <Cocoa/Cocoa.h>
#import "VTApplicationDelegate.h" 

@interface VTApplicationDelegate(VTScripting)

- (BOOL) application: (NSApplication*) sender delegateHandlesKey: (NSString*) key; 

@end
