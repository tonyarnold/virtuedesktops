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
#import <Virtue/VTDesktop.h>

@interface VTDesktop(VTScripting)

#pragma mark -
#pragma mark NSScriptObjectSpecifier 
- (NSScriptObjectSpecifier*) objectSpecifier; 
- (NSNumber*) uniqueIdentifier; 

#pragma mark -
#pragma mark Scripting Commands 

- (void) activateDesktopCommand: (NSScriptCommand*) command; 

@end
