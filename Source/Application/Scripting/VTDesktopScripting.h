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
#import "VTDesktop.h"

@interface VTDesktop(VTScripting)

#pragma mark -
#pragma mark NSScriptObjectSpecifier 
- (NSScriptObjectSpecifier*) objectSpecifier; 
- (NSNumber*) uniqueIdentifier; 

#pragma mark -
#pragma mark Scripting Commands 

- (void) activateDesktopCommand: (NSScriptCommand*) command; 

@end
