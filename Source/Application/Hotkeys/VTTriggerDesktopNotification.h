/******************************************************************************
* 
* VirtueDesktops 
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
#import "VTTriggerNotification.h"
#import "VTDesktop.h" 

@interface VTTriggerDesktopNotification : VTTriggerNotification {
	NSString* mNotificationFormat; 
	NSString* mDescriptionFormat; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) init;
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (void) setDesktop: (VTDesktop*) desktop; 
- (VTDesktop*) desktop; 

@end 