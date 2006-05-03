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
#import "VTNotificationBezel.h" 
#import "VTPreferencesViewController.h"
#import "VTOperationsViewController.h" 
#import "VTApplicationWatcherController.h"
#import "VTDesktopCollectionViewController.h" 
#import "VTPluginController.h"
#import "VTDesktopViewController.h"
#import "VTApplicationViewController.h" 

@interface VTApplicationDelegate : NSObject {
	// Outlets 
	IBOutlet NSMenu*							mStatusItemMenu; 
	IBOutlet NSMenu*							mStatusItemActiveDesktopItem; 
	IBOutlet NSMenuItem*					mStatusItemRemoveActiveDesktopItem; 
	IBOutlet NSTextField*					mVersionTextField;
	
	// Attributes 
	BOOL							mStartedUp; 
	BOOL							mConfirmQuitOverridden;
	NSStatusItem*			mStatusItem; 
	BOOL							mStatusItemMenuDesktopNeedsUpdate; 
	BOOL							mStatusItemMenuActiveDesktopNeedsUpdate;
	BOOL							mUpdatedDock;
	
	// Controllers 
	VTPreferencesViewController*		mPreferenceController;
	VTOperationsViewController*			mOperationsController; 
	VTApplicationWatcherController*	mApplicationWatcher; 
	VTPluginController*							mPluginController; 
	
	// Interface
	VTNotificationBezel*					mNotificationBezel; 
	VTDesktopViewController*			mDesktopInspector; 
	VTApplicationViewController*	mApplicationInspector; 
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
- (IBAction) deleteActiveDesktop: (id) sender; 
- (void) moveFrontApplicationToDirection: (VTDirection) direction;

@end
