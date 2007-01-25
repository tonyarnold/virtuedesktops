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

#import <Foundation/Foundation.h>
#import "VTTriggerGroup.h" 
#import "VTTriggerNotification.h" 

@interface VTTriggerController : NSObject  {
	VTTriggerGroup*	mNotifications;			//!< Our root group 
	BOOL            mIsEnabled;         //!< If set to false, no trigger events will be generated 
}

#pragma mark -
#pragma mark Lifetime 

+ (VTTriggerController*) sharedInstance;  

#pragma mark -
#pragma mark Attributes  

- (NSArray*) items;
- (VTTriggerGroup*) root; 

#pragma mark -
- (NSArray*) notificationsWithName: (NSString*) name; 
- (VTTriggerGroup*) groupWithName: (NSString*) name; 

#pragma mark -
- (void) setEnabled: (BOOL) enabled; 
- (BOOL) isEnabled; 

#pragma mark -
#pragma mark Operations 

- (void) addGroup: (VTTriggerGroup*) group; 
- (void) addNotification: (VTTriggerNotification*) notification; 

#pragma mark -
- (void) synchronize; 


@end
