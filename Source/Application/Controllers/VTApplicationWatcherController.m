/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2006, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTApplicationWatcherController.h"
#import "VTPreferenceKeys.h" 
#import <Virtue/VTDesktopController.h> 
#import <Virtue/VTPreferences.h>
#import <Virtue/VTModifiers.h> 
#import <Peony/Peony.h> 

@interface VTApplicationWatcherController(Private) 
- (void) findFinderApplication; 
@end 


@implementation VTApplicationWatcherController

#pragma mark Instance 

static OSStatus handleAppFrontSwitched(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData);

- (id) init {
	if (self = [super init]) {
		// register for notifications of application focus changes  
		[[NSNotificationCenter defaultCenter] addObserver:self 
																						 selector:@selector(onApplicationDidActivate:) 
																								 name: kPnApplicationDidActive 
																							 object: nil]; 
		
		
		[self setupAppChangeNotification];
		
		// register for notifications of application launches
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(onApplicationDidLaunch:) name: @"NSWorkspaceDidLaunchApplicationNotification" object: nil]; 
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(onApplicationWillLaunch:) name: @"NSWorkspaceWillLaunchApplicationNotification" object: nil]; 

		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopDidChange:) name: kPnOnDesktopDidActivate object: nil];
	
		// Set finder PSN (mFinderPSN)
		[self findFinderApplication];
		
		// Set our own PSN 
		GetProcessForPID([[NSProcessInfo processInfo] processIdentifier], &mPSN); 

		// ..and now set our marker to NO (initially)
		mFocusTriggeredSwitch = NO; 
		
		return self; 
	}
	
	return nil; 
}

- (void) setupAppChangeNotification {
	EventTypeSpec spec = { kEventClassApplication, kEventAppFrontSwitched };
	
	OSStatus err = InstallApplicationEventHandler(NewEventHandlerUPP(handleAppFrontSwitched), 1, &spec, (void*)self, NULL);	
	if (err) {
		NSLog(@"Failed to install event handler 'handleAppFrontSwitched' - application changes will not be detected.");
	}
}

- (void) dealloc {
	// unregister observers 
	[[NSDistributedNotificationCenter defaultCenter] removeObserver: self]; 
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self]; 
	[[NSNotificationCenter defaultCenter] removeObserver: self]; 
	
	// super
	[super dealloc]; 
}


#pragma mark -
#pragma mark Notification sinks 

/**
 * @brief	Called by the notification center when an application becomes active 
 *
 * The method currently implements the following strategy: 
 * - Switch to the application if the application does not have windows open on other windows 
 * - If a modifier was specified, only switch if the modifier is pressed 
 * - If we do not know about the application, do not do anything 
 *
 * Bugs 
 *
 * - If we deactivate a window by clicking on the desktop, the Finder process get the focus, which is bad if we got a Finder window open on another desktop, as VirtueDesktops will think you want to activate this app and switch. One workaround would be to deactivate Finder switching all together.. 
 *
 * Workaround 
 * 
 * - We currently disable switches to the Finder process (com.apple.finder) except in cases where they were triggered by a modifier key switch, thus forced by the user. 
 * 
 */
- (void) onApplicationDidActivate: (NSNotification*) notification {
	// first of all we check preferences, as this can save us some work here 
	if ([[NSUserDefaults standardUserDefaults] boolForKey: VTDesktopFollowsApplicationFocus] == NO)
		return; 
	
	// now get the modifier preference 
	int neededModifiers = [[NSUserDefaults standardUserDefaults] integerForKey: VTDesktopFollowsApplicationFocusModifier]; 
	// if it is not None, check against currently pressed modifiers 
	if (neededModifiers != 0) {
		// get actually pressed modifier 
		int pressedModifier = GetCurrentKeyModifiers(); 
		
		// and check against needed modifier 
		if ((neededModifiers & NSShiftKeyMask) && (!(pressedModifier & (1 << shiftKeyBit))))
			return; 
		if ((neededModifiers & NSCommandKeyMask) && (!(pressedModifier & (1 << cmdKeyBit))))
			return; 
		if ((neededModifiers & NSAlternateKeyMask) && (!(pressedModifier & (1 << optionKeyBit))))
			return; 
		if ((neededModifiers & NSControlKeyMask) && (!(pressedModifier & (1 << controlKeyBit))))
			return; 
	}
	
	// get psn 
	OSErr result; 
	
	result = GetFrontProcess(&mActivatedPSN);
	if (result) {
		NSLog(@"Error fetching PSN of application"); 
		return;
	}
	
	// as a dirty workaround, we will disable switches to the finder, except a modifier was used 
	if (neededModifiers == 0) {
		Boolean same; 
		
		// if this is the Finder, we abort here 
		result = SameProcess(&mActivatedPSN, &mFinderPSN, &same); 
		if (result)
			NSLog(@"Error comparing PSN of applications"); 
				
		if (same == TRUE)
			return; 
		
		// if this is VirtueDesktops itself, we also abort here 
		// @TODO: Move ignore list out of here 
		result = SameProcess(&mActivatedPSN, &mPSN, &same); 
		
		if (same == TRUE)
			return; 
	}
	
	// we will now walk all desktops to fetch their applications and build up an array so we can then decide where to switch to 
	NSEnumerator*	desktopIter	= [[[VTDesktopController sharedInstance] desktops] objectEnumerator]; 
	VTDesktop*		desktop		= nil; 
	NSMutableArray*	desktops	= [NSMutableArray array]; 
	
	while (desktop = [desktopIter nextObject]) {
		// fetch all applications 
		NSEnumerator*	applicationIter	= [[desktop applications] objectEnumerator]; 
		PNApplication*	application		= nil; 
		
		while (application = [applicationIter nextObject]) {
			// now fetch the owner psn and compare with the passed one for a match
			Boolean				same; 
			ProcessSerialNumber currentPsn = [application psn]; 
			
			SameProcess(&currentPsn, &mActivatedPSN, &same); 
			
			// got it...
			if (same == TRUE) {
				// check if this is the current desktop, and if it is, we will abort immediately
				if ([[[VTDesktopController sharedInstance] activeDesktop] isEqual: desktop])
					return; 
        
        // Don't want to switch on new window, just like finder
        if (neededModifiers == 0 && [application isUnfocused])
          return;
				
				[desktops addObject: desktop]; 
			}
		}
	}
	
	// if we did not find any desktops, something went wrong, so just ignore 
	if ([desktops count] == 0)
		return; 
	
	// now check if we got more than one and do not switch if we did 
	if ([desktops count] > 1)
		return; 

	// set marker 
	mFocusTriggeredSwitch = YES; 
	
	// switch... 
	[[VTDesktopController sharedInstance] activateDesktop: [desktops objectAtIndex: 0]]; 
}

- (void) onApplicationWillLaunch: (NSNotification*) notification {
	// Ok, I am in a dilemma here. I want to send applications to a predefined desktop upon launch, possibly before or really short after they appear on the screen. However at the time of this notification, we do not know about the application's windows. We could offer switching to the desktop for a start.. not really useful I guess...
}

- (void) onApplicationDidLaunch: (NSNotification*) notification {
	// Same here...
}

- (void) onDesktopDidChange: (NSNotification*) notification {
	// If the switch was triggered via activation, give the activated process front process status and abort 
	if (mFocusTriggeredSwitch) 
  {
		mFocusTriggeredSwitch = NO;
		SetFrontProcess(&mActivatedPSN); 
		
		return; 
	}
	// reset our flag 
	mFocusTriggeredSwitch = NO; 	

	
	// check if the new desktop has any applications, and if it does not, change to the finder process 
	VTDesktop*			desktop							= [notification object];
	PNApplication*	firstNonHiddenApp   = nil; 
	NSArray*				applications				= [desktop applications]; 
	int							applicationCount		= [applications count]; 
	int							i										= 0; 
	int							realCount						= 0; 
	
	// count non-hidden applications and remember the first non-hidden application we encounter for later use 
	for (i=0; i<applicationCount; i++) {
		if ([[applications objectAtIndex: i] isHidden] == NO) {
			realCount++; 
			
			if (firstNonHiddenApp == nil)
				firstNonHiddenApp = [[applications objectAtIndex: i] retain]; 
		}
	}
	
	// more than one application means, we have at least one application but the finder active, so lets return 
	if (realCount <= 1) {
		if ((realCount > 0) && (firstNonHiddenApp)) {
			// we now have to check if the one non-application is the finder 
			ProcessSerialNumber applicationPSN = [firstNonHiddenApp psn]; 
			Boolean				same; 
		
			SameProcess(&applicationPSN, &mFinderPSN, &same); 
			if (same == TRUE)
				SetFrontProcess(&mFinderPSN); 
		} else {
			// if we come here, we have to activate the Finder 
			SetFrontProcess(&mFinderPSN); 
			[firstNonHiddenApp release]; 
			
			return; 
		}
	}
		
	[firstNonHiddenApp release]; 
	
	// Now take care of activating the first non-hidden application showing the topmost window 
	int count = [[desktop windows] count]; 
	int index = 0; 
	
	if (count == 0)
		return; 

	// we will exclude applications that were set as "hidden", that is why we have to loop here
	while (index < count) {
		PNWindow*       frontWindow				= [[desktop windows] objectAtIndex: index];
		PNApplication*	frontWindowOwner	= [desktop applicationForPid: [frontWindow ownerPid]]; 
		
		if ([frontWindowOwner isHidden] == NO) {
			ProcessSerialNumber frontWindowOwnerPsn = [frontWindow ownerPsn];
			SetFrontProcess(&frontWindowOwnerPsn); 		
			
			break; 
		}
		
		index++; 
	}
  
  
}

- (void) appDidChange {
	[[NSNotificationCenter defaultCenter]
			postNotificationName: kPnApplicationDidActive 
										object: [[NSWorkspace sharedWorkspace] activeApplication]];		
}


@end

@implementation VTApplicationWatcherController(Private)

- (void) findFinderApplication {
	NSArray*		applications			= [[NSWorkspace sharedWorkspace] launchedApplications]; 
	NSEnumerator*	applicationIter	= [applications objectEnumerator];  
	NSDictionary*	application			= nil; 
	
	while (application = [applicationIter nextObject]) {
		if ([[application objectForKey: @"NSApplicationBundleIdentifier"] isEqualToString: @"com.apple.finder"]) {
			// Fetch the finder's PSN 
			mFinderPSN.highLongOfPSN = [[application objectForKey: @"NSApplicationProcessSerialNumberHigh"] longValue]; 
			mFinderPSN.lowLongOfPSN  = [[application objectForKey: @"NSApplicationProcessSerialNumberLow"] longValue]; 
			
			return; 
		}
	}
}

@end 
static OSStatus handleAppFrontSwitched(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData) {
	[(id)inUserData appDidChange];
	return 0;
}
