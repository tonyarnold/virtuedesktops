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

#import "VTSetupAssistant.h"
#import <Zen/Zen.h> 
#include "DECInjector.h"

#pragma mark -
@implementation VTSetupAssistant

- (id) initWithTracker: (VTVersionTracker*) tracker {
	if (self = [super initWithWindowNibName: @"VirtueAssistant"]) {
		mActionTriggeredChange		= NO; 
		mUpdatedDock				= NO; 
		mUpdatedPreferences			= NO; 
		mUpdatedDesktops			= NO; 
		
		mShouldUpgradeDock			= NO; 
		mShouldUpgradeDesktops		= YES; 
		mShouldUpgradePreferences	= YES; 
		
		ZEN_ASSIGN(mTracker, tracker); 
		
		[mPreviousButton setEnabled: NO];
		[mNextButton setEnabled: YES]; 
		
		return self; 
	}
	
	return nil; 
}

#pragma mark -
#pragma mark Attributes 
- (void) setUpgradeDock: (BOOL) flag {
	mShouldUpgradeDock = flag; 
	
	if (mShouldUpgradeDock == NO) {
		// remove the tab page alltogether 
		[mTabs removeTabViewItem: mUpgradeDockItem]; 
	}

}

- (void) setUpgradePreferences: (BOOL) flag {
	mShouldUpgradePreferences = flag; 
	
	if ((mShouldUpgradePreferences == NO) && (mShouldUpgradeDesktops == NO)) {
		[mTabs removeTabViewItem: mUpgradePreferencesItem]; 
		return; 
	}
	
	// set enabled state 
	[mUpgradePreferencesButton setEnabled: flag]; 
}

- (void) setUpgradeDesktops: (BOOL) flag {
	mShouldUpgradeDesktops = flag; 

	if ((mShouldUpgradePreferences == NO) && (mShouldUpgradeDesktops == NO)) {
		[mTabs removeTabViewItem: mUpgradePreferencesItem]; 
		return; 
	}
	
	// set enabled state 
	[mUpgradeDesktopsButton setEnabled: flag]; 
}

#pragma mark -
#pragma mark Actions 
- (IBAction) selectNextTab: (id) sender {
	// enable tab changing 
	mActionTriggeredChange = YES; 
	
	// check if we should trigger updates 
	if ([[[mTabs selectedTabViewItem] identifier] isEqualToString: @"settings"]) {
		if ((mShouldUpgradePreferences) && (mUpdatedPreferences == NO) && ([mUpgradePreferencesButton state] == NSOnState)) {
			[mUpgradePreferencesButton setEnabled: NO]; 
			[mTracker upgradePreferences]; 
			mUpdatedPreferences = YES; 
		}
		if ((mShouldUpgradeDesktops) && (mUpdatedDesktops == NO) && ([mUpgradeDesktopsButton state] == NSOnState)) {
			[mUpgradeDesktopsButton setEnabled: NO]; 
			[mTracker upgradeDesktops]; 
			mUpdatedDesktops = YES; 
		}
		
	}

	[mTabs selectNextTabViewItem: sender]; 
}

- (IBAction) selectPrevTab: (id) sender {
	// enable tab changing 
	mActionTriggeredChange = YES; 
	
	[mTabs selectPreviousTabViewItem: sender]; 
}

#pragma mark -
- (IBAction) upgradeDock: (id) sender {
	[mUpgradeDockButton setEnabled: NO]; 
	
	[mCurrentOperation setHidden: NO]; 
	[mProgress setHidden: NO]; 
	[mProgress startAnimation: self]; 
	
	// first, kill the dock 
	dec_kill_dock(); 
	// now try to restart it 
	[self doUpgradeDock]; 
}

#pragma mark -
- (IBAction) upgradeDone: (id) sender {
	[mTracker versionCheckSucceeded]; 
}

- (IBAction) upgradeKill: (id) sender {
	[mTracker versionCheckAborted]; 
}

#pragma mark -
#pragma mark NSTabView Delegate 

- (BOOL)tabView: (NSTabView*) tabView shouldSelectTabViewItem: (NSTabViewItem*) tabViewItem {
	// if we initiated this change, allow. but prevent our humble user from clicking 
	// on the tabs 
	if (mActionTriggeredChange == NO)
		return NO; 
	
	return YES; 
}

- (void) tabView: (NSTabView*) tabView didSelectTabViewItem: (NSTabViewItem*) tabViewItem {
	// reset trigger state 
	mActionTriggeredChange = NO; 
	
	if ([[tabViewItem identifier] isEqualToString: @"upgrade"]) {
		// disable buttons until we upgraded the dock 
		if (mUpdatedDock == NO) {
			[mPreviousButton setEnabled: NO]; 
			[mNextButton setEnabled: NO]; 
			
			return; 
		}
	}
	if ([[tabViewItem identifier] isEqualToString: @"finish"]) {
		[mKillButton setHidden: YES]; 
		[mDoneButton setHidden: NO]; 
		[mPreviousButton setHidden: YES]; 
		[mNextButton setHidden: YES]; 
		
		return; 
	}	
	
	// update buttons 
	if ([tabView indexOfTabViewItem: tabViewItem] == 0)
		[mPreviousButton setEnabled: NO]; 
	else
		[mPreviousButton setEnabled: YES]; 
}

- (void) doUpgradeDock {
	int isInjected	= 0; 
	int minor		= 0; 
	int major		= 0; 
	
	dec_info(&isInjected, &major, &minor);
	NSLog("Dock code is already injected: %i", isInjected);
	// restart dock 
	if (isInjected != 1)
		dec_inject_code(); 
	
	dec_info(&isInjected, &major, &minor);
	
	
	
	if (isInjected == 1) {
		[mProgress stopAnimation: self];
		[mProgress setHidden: YES]; 
		[mCurrentOperation setHidden: YES]; 
		
		// update buttons 
		[mPreviousButton setEnabled: YES]; 
		[mNextButton setEnabled: YES]; 
		
		mUpdatedDock = YES; 

		return; 
	}
	
	[NSTimer scheduledTimerWithTimeInterval: 0.5 target: self selector: @selector(doUpgradeDock) userInfo: nil repeats: NO]; 
}


@end 

