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

#import "VTApplicationWatcherController.h"
#import "VTApplicationController.h"
#import "VTApplicationWrapper.h"
#import "VTPreferenceKeys.h" 
#import "VTDesktopController.h"
#import "VTPreferences.h"
#import "VTModifiers.h"
#import <Peony/Peony.h> 
#import <Zen/Zen.h>

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
													 name:kPnApplicationDidActive 
												   object:nil]; 
		
		
		[self setupAppChangeNotification];
		
		// register for notifications of application launches
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(onApplicationDidLaunch:) name: @"NSWorkspaceDidLaunchApplicationNotification" object: nil]; 
		[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(onApplicationWillLaunch:) name: @"NSWorkspaceWillLaunchApplicationNotification" object: nil]; 

		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopDidChange:) name: kPnOnDesktopDidActivate object: nil];
	
		// Set finder PSN (mFinderPSN)
		[self findFinderApplication];
		
		// Set our own PSN 
		GetProcessForPID([[NSProcessInfo processInfo] processIdentifier], &mPSN);
        
        // Initialize mActivatedPSN
        mActivatedPSN.lowLongOfPSN = kNoProcess;
		return self; 
	}
	
	return nil; 
}

- (void) setupAppChangeNotification {
	EventTypeSpec spec = { kEventClassApplication, kEventAppFrontSwitched };
	
	OSStatus err = InstallApplicationEventHandler(NewEventHandlerUPP(handleAppFrontSwitched), 1, &spec, (void*)self, NULL);	
	if (err) {
		ZNLog( @"Failed to install event handler 'handleAppFrontSwitched' - application changes will not be detected.");
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
- (void) onApplicationDidActivate: (NSNotification*) notification
{
    Boolean same;
    ProcessSerialNumber oldPSN = mActivatedPSN;

	// If a new window has appeared and the applicatioin is bound on a desktop, we have to make sure the new window is on the good desktop
	// get psn 
	OSErr result; 
	result = GetFrontProcess(&mActivatedPSN);
	if (result) {
		ZNLog( @"Error fetching PSN of application"); 
		return;
	}
    
    result = SameProcess(&oldPSN, &mActivatedPSN, &same);
    if (result) {
        same = FALSE;
    }
	
	// Update the desktop to be sure the new window has been registered before looking for its application.
    VTApplicationWrapper *wrapper = [[VTApplicationController sharedInstance] applicationForPSN:&mActivatedPSN];
	VTDesktop* desktop = [[VTDesktopController sharedInstance] activeDesktop];
	[desktop updateDesktop];
    	
	// Is the application bound to a desktop ?
	PNApplication*  application = [desktop applicationForPSN: mActivatedPSN];
	PNDesktop*     appliDesktop = [application desktop];

    // The previous application has been hidden or terminated, activate the next application
    // and the new application is not on the current desktop --> let choose a new active application
    // on the current desktop
    if (oldPSN.lowLongOfPSN != kNoProcess && [desktop applicationForPSN:oldPSN] == nil && application == nil
        && !IsProcessVisible(&oldPSN) && [desktop activateTopApplication]) {
        return;
    }
    
    if (appliDesktop == nil && [wrapper boundDesktop] != nil) {
        appliDesktop = [wrapper boundDesktop];
    }
    
    // It is bound to another desktop...
	if (application != nil && appliDesktop != nil) {
		// And it is not the current desktop --> change the desktop
        if (!same && [appliDesktop identifier] != [desktop identifier]) {
			[application  setDesktop:appliDesktop];
            [appliDesktop updateDesktop];
            [appliDesktop setActiveApplication:application];
        // It is the current desktop --> confirm the activation
		} else {
            [desktop setActiveApplication:application];
            [application activate];
			return; // The desktop of the current application is the active desktop... do nothing
		}
	}
	
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
	
	// as a dirty workaround, we will disable switches to the finder, except a modifier was used 
	if (neededModifiers == 0) {
		// if this is the Finder, we abort here 
		result = SameProcess(&mActivatedPSN, &mFinderPSN, &same); 
		if (result)
			ZNLog( @"Error comparing PSN of applications"); 
				
		if (same == TRUE)
			return;
		
		// if this is VirtueDesktops itself, we also abort here 
		// @TODO: Move ignore list out of here 
		result = SameProcess(&mActivatedPSN, &mPSN, &same); 
		
		if (same == TRUE)
			return;
	}
	
	// If we know where the application is, so this is useless to iterate through all desktops.
	if (appliDesktop == nil) {
		// we will now walk all desktops to fetch their applications and build up an array so we can then decide where to switch to 
		NSEnumerator*	desktopIter	= [[[VTDesktopController sharedInstance] desktops] objectEnumerator]; 
	
		while (desktop = [desktopIter nextObject]) {
			application	= [desktop applicationForPSN:mActivatedPSN]; 
		
			if (application != nil) {
				// check if this is the current desktop, and if it is, we will abort immediately
				if ([[[VTDesktopController sharedInstance] activeDesktop] isEqual: desktop]) {
                    [desktop setActiveApplication:application];
					return; 
                }
        
				// Don't want to switch on new window, just like finder
				if (neededModifiers == 0 && [application isUnfocused])
					return;
			
                appliDesktop = desktop;
				break;
			}
            application = nil;
		}
    }
	if (appliDesktop == nil) {
        return;
    }
    if (application == nil) {
        application = [appliDesktop applicationForPSN:mActivatedPSN];
    }
	// switch... 
    if (application != nil) {
        [appliDesktop setActiveApplication:application];
    }
	[[VTDesktopController sharedInstance] activateDesktop: (VTDesktop*)appliDesktop];
}

- (void) onApplicationWillLaunch: (NSNotification*) notification {
	// Ok, I am in a dilemma here. I want to send applications to a predefined desktop upon launch, possibly before or really short after they appear on the screen. However at the time of this notification, we do not know about the application's windows. We could offer switching to the desktop for a start.. not really useful I guess...
}

- (void) onApplicationDidLaunch: (NSNotification*) notification {
	// Same here...
}

- (void) onDesktopDidChange: (NSNotification*) notification
{
	// check if the new desktop has any applications, and if it does not, change to the finder process 
	VTDesktop*	desktop	= [notification object];
    if ([desktop applicationForPSN:mActivatedPSN] == nil && ![desktop activateTopApplication]) {
        SetFrontProcess(&mFinderPSN); 
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
