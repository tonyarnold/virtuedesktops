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

#import <Growl/Growl.h>
#import <Cocoa/Cocoa.h>
#import "VTMotionController.h"
#import "VTLightSensorController.h"
#import "VTNotificationBezel.h" 
#import "VTPreferencesViewController.h"
#import "VTOperationsViewController.h" 
#import "VTApplicationWatcherController.h"
#import "VTDesktopCollectionViewController.h" 
#import "VTPluginController.h"
#import "VTDesktopViewController.h"
#import "VTApplicationViewController.h" 

@protocol GrowlApplicationBridgeDelegate;

@interface VTApplicationDelegate : NSObject <GrowlApplicationBridgeDelegate> {
	// Outlets 
	IBOutlet NSMenu*			mStatusItemMenu; 
	IBOutlet NSMenu*			mStatusItemActiveDesktopItem; 
	IBOutlet NSMenuItem*	mStatusItemRemoveActiveDesktopItem; 
	IBOutlet NSTextField*	mVersionTextField;
  IBOutlet NSPanel*     mAboutPanel;
  IBOutlet NSPanel*     mWelcomePanel;
  
	
	// Attributes 
	BOOL						mStartedUp; 
	BOOL						mConfirmQuitOverridden;
	NSStatusItem*		mStatusItem; 
	BOOL						mStatusItemMenuDesktopNeedsUpdate; 
	BOOL						mStatusItemMenuActiveDesktopNeedsUpdate;
	BOOL						mUpdatedDock;
	
	// Controllers 
	VTPreferencesViewController*		mPreferenceController;
	VTOperationsViewController*			mOperationsController; 
	VTApplicationWatcherController*		mApplicationWatcher; 
	VTPluginController*					mPluginController; 
	
	// Interface
	VTNotificationBezel*			mNotificationBezel; 
	VTDesktopViewController*		mDesktopInspector; 
	VTApplicationViewController*	mApplicationInspector; 
	VTMotionController*				mMotionController;
  VTLightSensorController*  mLightSensorController;
}

- (NSString*) versionString;
- (NSString*) revisionString;
#pragma mark -
#pragma mark Actions 
- (IBAction) showPreferences: (id) sender; 
- (IBAction) showHelp: (id) sender; 

#pragma mark -
- (IBAction) showDesktopInspector: (id) sender; 
- (IBAction) showApplicationInspector: (id) sender; 
- (IBAction) showStatusbarMenu: (id) sender; 

#pragma mark -
- (IBAction) showAboutPanel: (id) sender;
- (IBAction) sendFeedback: (id) sender; 
- (IBAction) showWebsite: (id) sender; 
- (IBAction) showForums: (id) sender; 
- (IBAction) showDonationsPage: (id) sender; 
- (IBAction) showWelcomePanel: (id) sender;

#pragma mark -
- (IBAction) deleteActiveDesktop: (id) sender; 
- (BOOL) checkExecutablePermissions;
- (IBAction) fixExecutablePermissions: (id) sender;
- (void) moveFrontApplicationInDirection: (VTDirection) direction;

#pragma mark Growl
- (void)postGrowlNotification;
@end
