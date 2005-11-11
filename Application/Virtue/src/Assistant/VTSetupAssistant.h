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
#import "VTVersionTracker.h" 

@interface VTSetupAssistant : NSWindowController {
// outlets 
	IBOutlet NSButton*				mNextButton; 
	IBOutlet NSButton*				mPreviousButton; 
	IBOutlet NSButton*				mUpgradeDockButton;
	IBOutlet NSButton*				mUpgradePreferencesButton; 
	IBOutlet NSButton*				mUpgradeDesktopsButton; 
	IBOutlet NSProgressIndicator*	mProgress; 
	IBOutlet NSTextField*			mCurrentOperation; 
	IBOutlet NSTabView*				mTabs; 
	IBOutlet NSTabViewItem*			mUpgradeDockItem; 
	IBOutlet NSTabViewItem*			mUpgradePreferencesItem; 
	IBOutlet NSButton*				mDoneButton; 
	IBOutlet NSButton*				mKillButton; 
	
// ivars 
	BOOL							mActionTriggeredChange; 
	BOOL							mUpdatedDock; 
	BOOL							mUpdatedPreferences; 
	BOOL							mUpdatedDesktops; 
	
	BOOL							mShouldUpgradeDock; 
	BOOL							mShouldUpgradePreferences; 
	BOOL							mShouldUpgradeDesktops;
	
	VTVersionTracker*				mTracker; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) initWithTracker: (VTVersionTracker*) tracker; 

#pragma mark -
#pragma mark Attributes 
- (void) setUpgradeDock: (BOOL) flag; 
- (void) setUpgradePreferences: (BOOL) flag; 
- (void) setUpgradeDesktops: (BOOL) flag; 

#pragma mark -
#pragma mark Actions 
- (IBAction) selectNextTab: (id) sender; 
- (IBAction) selectPrevTab: (id) sender; 

#pragma mark -
- (IBAction) upgradeDock: (id) sender; 
- (IBAction) upgradeDone: (id) sender; 
- (IBAction) upgradeKill: (id) sender; 

@end
