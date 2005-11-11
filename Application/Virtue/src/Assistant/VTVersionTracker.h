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

@class VTSetupAssistant; 

#define VTVersionUpgradeOkName		 0
#define VTVersionUpgradeCancelName	-1

@interface VTVersionTracker : NSObject {
	id						mDelegate; 
	VTSetupAssistant*		mAssistant; 
	NSString*				mInstalledVersion; 
}

#pragma mark -
#pragma mark Lifetime 
-  (id) init; 

#pragma mark -
#pragma mark Operations 
- (void) performVersionCheck; 

- (void) upgradePreferences; 
- (void) upgradeDesktops; 

- (void) setDelegate: (id) delegate; 

#pragma mark -
#pragma mark Delegate Methods 
- (void) versionCheckSucceeded; 
- (void) versionCheckAborted; 

@end
