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

#import "VTVersionTracker.h"
#import "VTPreferenceKeys.h" 
#import "VTSetupAssistant.h" 
#import <Virtue/VTTrigger.h> 
#import <Virtue/VTTriggerGroup.h> 
#import <Virtue/VTTriggerNotification.h> 
#import <Virtue/VTTriggerController.h> 
#import <Virtue/VTHotkeyTrigger.h> 
#import <Virtue/VTMouseTrigger.h> 
#import <Virtue/VTDesktop.h> 
#import <Virtue/VTDesktopFilesystemController.h> 
#import <Virtue/VTPreferences.h> 
#import <Zen/Zen.h> 

#pragma mark Version Strings 
#define VTVersionString_0_4			@"0.4"
#define VTVersionString_0_5_r_0		@"5.0r0"
#define VTVersionString_0_5_r_1		@"5.0r1"
#define VTVersionString_0_5_r_2		@"5.0r2"

#pragma mark -
@interface VTVersionTracker(Private) 
#pragma mark -
- (NSString*) runningVersion; 
- (NSString*) installedVersion; 
- (NSString*) latestVersion; 
#pragma mark -
- (void) callDelegate: (SEL) selector; 
#pragma mark -
- (void) upgradePreferences_0_5_r_1; 
- (void) upgradePreferences_0_4; 
- (void) upgradeDesktops_0_4; 
@end 

#pragma mark -
@implementation VTVersionTracker

- (id) init {
	if (self = [super init]) {
		mAssistant			= nil;
		mDelegate			= nil; 
		
		mInstalledVersion	= [[self installedVersion] retain]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	if (mAssistant) 
		[mAssistant close]; 
	ZEN_RELEASE(mAssistant); 
	ZEN_RELEASE(mInstalledVersion); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Operations 

- (void) performVersionCheck {
	// get version of installed and running system to determine if we need to update 
	NSString*			runningVersion		= [self runningVersion]; 
	NSString*			installedVersion	= [self installedVersion]; 
	
	if (installedVersion == nil) {
		// we will not display an assistant if there was no virtue installation found
		;
	}
	// if we had a version 0.4- installed, we update using the assistant 
	else if ([installedVersion isEqualToString: VTVersionString_0_4]) {
		[self upgradePreferences]; 
	}
	else if ([installedVersion isEqualToString: VTVersionString_0_5_r_1]) {
		// upgrade preferences without asking 
		[self upgradePreferences]; 
	}
	
	// no assistant means we are done and can run without any work 
	if (mAssistant == nil) {
		[self versionCheckSucceeded]; 
		return; 
	}
	
	// display assistant centered nicely so we wont miss it 
	[[mAssistant window] center]; 
	[mAssistant showWindow: self]; 
}

- (void) upgradePreferences {
	if ([mInstalledVersion isEqualToString: VTVersionString_0_4])
		[self upgradePreferences_0_4]; 
	else if ([mInstalledVersion isEqualToString: VTVersionString_0_5_r_1]) 
		[self upgradePreferences_0_5_r_1]; 
}

- (void) upgradeDesktops {
	if ([mInstalledVersion isEqualToString: VTVersionString_0_4])
		[self upgradeDesktops_0_4]; 
}

#pragma mark -
#pragma mark Delegate Methods 

- (void) setDelegate: (id) delegate {
	mDelegate = delegate; 
}

- (void) versionCheckSucceeded {
	[mAssistant close]; 
	ZEN_RELEASE(mAssistant); 
	
	[self callDelegate: @selector(versionCheckSucceeded)]; 
}

- (void) versionCheckAborted {
	[mAssistant close]; 
	ZEN_RELEASE(mAssistant); 

	[self callDelegate: @selector(versionCheckAborted)]; 
}

@end

#pragma mark -
@implementation VTVersionTracker (Private) 

- (void) callDelegate: (SEL) selector {
	if (mDelegate == nil)
		return; 
	if ([mDelegate respondsToSelector: selector] == NO)
		return; 
	
	[mDelegate performSelector: selector]; 
}

#pragma mark -
- (NSString*) installedVersion {
	// here we cannot ask the bundle, as we are already running and do not have 
	// access to the bundle, so we try to guess based on the settings 
	
	// Check for Virtue 0.5+ where we write the version to the preferences 
	NSString* versionString = [[NSUserDefaults standardUserDefaults] objectForKey: VTPreferencesVirtueVersionName]; 
	if ((versionString) && ([versionString length] != 0)) {
		return versionString; 
	}
	
	// check if there is anything installed and if so, assume it is 0.3 or 0.4, 
	// which we will treat the same here 
	if ([[NSUserDefaults standardUserDefaults] persistentDomainForName: [[NSBundle mainBundle] bundleIdentifier]]) 
		return VTVersionString_0_4; 
	
	// return nothing to indicate we have no chance of finding out
	return nil; 
}

- (NSString*) runningVersion {
	// that is easy, just ask our bundle 
	NSDictionary* bundleInformation = [[NSBundle mainBundle] infoDictionary]; 
	
	return [bundleInformation objectForKey: @"CFBundleVersion"]; 
}

- (NSString*) latestVersion {
	return nil; 
}

#pragma mark -

- (void) upgradePreferences_0_5_r_1 {
	// modify modifier keys needed for automatic switching 
	int modifier	= [[NSUserDefaults standardUserDefaults] integerForKey: VTDesktopFollowsApplicationFocusModifier]; 
	int modifiers	= 0; 
	
	if (modifier != 0) {
		if (modifier == 1) 
			modifiers |= NSShiftKeyMask; 
		if (modifier == 2) 
			modifiers |= NSAlternateKeyMask; 
		if (modifier == 3) 
			modifiers |= NSCommandKeyMask; 
		
		[[NSUserDefaults standardUserDefaults] setInteger: modifiers forKey: VTDesktopFollowsApplicationFocusModifier]; 
		[[NSUserDefaults standardUserDefaults] synchronize]; 
	}
}

- (void) upgradePreferences_0_4 {
	// we are nuking preferences for 0.4-
	[[NSUserDefaults standardUserDefaults] removePersistentDomainForName: @"net.sourceforge.virtue.Virtue"]; 
}

- (void) upgradeDesktops_0_4 {
}

@end 
