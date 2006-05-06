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
#import <Virtue/VTDesktopController.h>
#import <Virtue/VTDesktopDecorationController.h>
#import <Virtue/VTLayoutController.h>
#import <Virtue/VTTriggerController.h> 
#import <Virtue/VTApplicationController.h> 
#import <Virtue/VTPreferences.h>
#import <Virtue/VTNotifications.h>
#import <Virtue/NSUserDefaultsControllerKeyFactory.h>
#import <Zen/Zen.h> 
#import <Sparkle/Sparkle.h>

#import "VTApplicationDelegate.h"
#import "VTMatrixDesktopLayout.h" 
#import "VTDesktopViewController.h"
#import "VTApplicationViewController.h" 
#import "VTPreferenceKeys.h"

#import "DECInjector.h"

#import "../../../../Shared/Smart Crash Reports SDK/SmartCrashReportsInstall.h"

enum
{
	kVtMenuItemMagicNumber				= 666,
	kVtMenuItemRemoveMagicNumber	= 667,
};



@interface VTApplicationDelegate (Private) 
- (void) registerObservers; 
- (void) unregisterObservers; 
#pragma mark -
- (void) updateStatusItem; 
- (void) updateDesktopsMenu; 
- (void) updateActiveDesktopMenu; 
- (void) updateVersionNumbers;
#pragma mark -
- (void) showDesktopInspectorForDesktop: (VTDesktop*) desktop;  
- (void) invalidateQuitDialog:(NSNotification *)aNotification;
- (NSString*) preferencesFolder;
- (NSString*) applicationSupportFolder;
- (void) migrateOldPreferences;
@end 

@implementation VTApplicationDelegate

#pragma mark -
#pragma mark Initialize 

+ (void) initialize {
}


#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {		
		// init attributes
		mStartedUp = NO; 
		mConfirmQuitOverridden = NO;
		mStatusItem = nil; 
		mStatusItemMenuDesktopNeedsUpdate = YES; 
		mStatusItemMenuActiveDesktopNeedsUpdate = YES;
		// Let's make sure that Unsanity's Smart Crash Reports is installed before we begin
		Boolean authenticationWillBeRequired = FALSE;
		if (UnsanitySCR_CanInstall(&authenticationWillBeRequired))
			UnsanitySCR_Install(authenticationWillBeRequired ? kUnsanitySCR_GlobalInstall : 0);
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mStatusItem); 
	ZEN_RELEASE(mNotificationBezel); 
	ZEN_RELEASE(mPreferenceController); 
	ZEN_RELEASE(mOperationsController); 
	ZEN_RELEASE(mApplicationWatcher); 
	ZEN_RELEASE(mDesktopInspector); 
	ZEN_RELEASE(mApplicationInspector); 
	
	[[VTLayoutController sharedInstance] 
		removeObserver: self forKeyPath: @"activeLayout"]; 
	[[VTLayoutController sharedInstance] 
		removeObserver: self forKeyPath: @"activeLayout.desktops"]; 
	[[VTDesktopController sharedInstance] 
		removeObserver: self forKeyPath: @"desktops"]; 
	[[VTDesktopController sharedInstance] 
		removeObserver: self forKeyPath: @"activeDesktop"]; 
	[[NSUserDefaultsController sharedUserDefaultsController] 
		removeObserver: self forKeyPath: [NSUserDefaultsController pathForKey: VTVirtueShowStatusbarDesktopName]]; 
	[[NSUserDefaultsController sharedUserDefaultsController] 
		removeObserver: self forKeyPath: [NSUserDefaultsController pathForKey: VTVirtueShowStatusbarMenu]];
	
	//[mPluginController unloadPlugins]; 
	ZEN_RELEASE(mPluginController); 
	
	[self unregisterObservers]; 
	[super dealloc];
}

#pragma mark -
#pragma mark Bootstrapping 

- (void) bootstrap {
	// This registers us to recieve NSWorkspace notifications, even though we are have LSUIElement enabled
	[NSApplication sharedApplication];
	
	// Inject dock extension code into the Dock process
	dec_inject_code();
	
	// Migrate old sourceforge identified preferences to new plist
	[self migrateOldPreferences];
	
	// Set-up default preferences 
	[VTPreferences registerDefaults]; 
	
	// and ensure we have our version information in there 
	[[NSUserDefaults standardUserDefaults] setObject: [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"VTPreferencesVirtueVersionName"]; 
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// Load plugins 
	mPluginController = [[VTPluginController alloc] init]; 
	[mPluginController loadPlugins]; 
		
	// Create controllers 
	[VTDesktopController sharedInstance];
	[VTDesktopDecorationController sharedInstance]; 
	[[VTDesktopController sharedInstance] deserializeDesktops]; 
	[VTTriggerController sharedInstance]; 
	[VTLayoutController sharedInstance]; 
	[VTApplicationController sharedInstance]; 
	
	mPreferenceController	= [[VTPreferencesViewController alloc] init];
	mOperationsController	= [[VTOperationsViewController alloc] init];
	mApplicationWatcher		= [[VTApplicationWatcherController alloc] init];
	mDesktopInspector			= [[VTDesktopViewController alloc] init];
	mApplicationInspector	= [[VTApplicationViewController alloc] init];
		
	// Interface controllers 
	mNotificationBezel = [[VTNotificationBezel alloc] init];
	
	// Make sure we have our default matrix layout created 
	NSArray*					layouts = [[VTLayoutController sharedInstance] layouts]; 
	VTDesktopLayout*	layout	= nil; 
	
	if (layouts) {
		NSEnumerator*	iterator = [layouts objectEnumerator];
		while (layout = [iterator nextObject]) {
			if ([NSStringFromClass([layout class]) isEqualToString: @"VTMatrixDesktopLayout"])
				break; 
		}
	}
	
	if (layout == nil) {
		VTMatrixDesktopLayout* matrixLayout = [[VTMatrixDesktopLayout alloc] init]; 
		[[VTLayoutController sharedInstance] attachLayout: matrixLayout]; 
		
		if ([[VTLayoutController sharedInstance] activeLayout] == nil)
			[[VTLayoutController sharedInstance] setActiveLayout: matrixLayout]; 
		
		[[VTLayoutController sharedInstance] synchronize]; 
		[matrixLayout release]; 
	}
	
	// Create decoration prototype 
	VTDesktopDecoration* decorationPrototype = [[[VTDesktopDecoration alloc] initWithDesktop: nil] autorelease];
	// Try to read it from our preferences, if it is not there, use the empty one 
	if ([[NSUserDefaults standardUserDefaults] dictionaryForKey: VTPreferencesDecorationTemplateName] != nil) {
		NSDictionary* dictionary = [[NSUserDefaults standardUserDefaults] dictionaryForKey: VTPreferencesDecorationTemplateName]; 
		[decorationPrototype decodeFromDictionary: dictionary]; 
	}
	
	[[VTDesktopController sharedInstance] setDecorationPrototype: decorationPrototype]; 	
	[[VTDesktopController sharedInstance] setUsesDecorationPrototype: 
		[[NSUserDefaults standardUserDefaults] boolForKey: VTPreferencesUsesDecorationTemplateName]]; 
	// and bind setting 
	[[NSUserDefaults standardUserDefaults] setBool: [[VTDesktopController sharedInstance] usesDecorationPrototype] forKey: VTPreferencesUsesDecorationTemplateName];  
	
	[[VTDesktopController sharedInstance] bind: @"usesDecorationPrototype" toObject: [NSUserDefaultsController sharedUserDefaultsController] withKeyPath: [NSUserDefaultsController pathForKey: VTPreferencesUsesDecorationTemplateName] options: nil]; 
	[[NSUserDefaultsController sharedUserDefaultsController] bind: [NSUserDefaultsController pathForKey: VTPreferencesUsesDecorationTemplateName] toObject: [VTDesktopController sharedInstance] withKeyPath: @"usesDecorationPrototype" options: nil]; 
	
	// Decode application preferences
	NSDictionary* applicationDict = [[NSUserDefaults standardUserDefaults] objectForKey: VTPreferencesApplicationsName]; 
	if (applicationDict)
		[[VTApplicationController sharedInstance] decodeFromDictionary: applicationDict]; 
	
	// and scan for initial applications 
	[[VTApplicationController sharedInstance] scanApplications]; 

	// Udate status item 
	[self updateStatusItem]; 
	
	// Update items in menu 
	[self updateDesktopsMenu]; 
	[self updateActiveDesktopMenu]; 
		
	// Register observers 
	[[VTLayoutController sharedInstance]
		addObserver: self
		 forKeyPath: @"activeLayout"
			options: NSKeyValueObservingOptionNew
			context: NULL];
	
	[[VTLayoutController sharedInstance]
		addObserver: self
		 forKeyPath: @"activeLayout.desktops"
			options: NSKeyValueObservingOptionNew 
			context: NULL];
	
	[[VTDesktopController sharedInstance] 
		addObserver: self 
		 forKeyPath: @"desktops" 
			options: NSKeyValueObservingOptionNew 
			context: NULL];
	
	[[VTDesktopController sharedInstance]
		addObserver: self
		 forKeyPath: @"activeDesktop"
			options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
			context: NULL];
	
	[[[VTDesktopController sharedInstance] activeDesktop]
			addObserver: self
			 forKeyPath: @"applications"
				options: NSKeyValueObservingOptionNew
				context: NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController]
			addObserver: self
			 forKeyPath: [NSUserDefaultsController pathForKey: VTVirtueShowStatusbarDesktopName]
				options: NSKeyValueObservingOptionNew
				context: NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController]
			addObserver: self
			 forKeyPath: [NSUserDefaultsController pathForKey: VTVirtueShowStatusbarMenu]
				options: NSKeyValueObservingOptionNew
				context: NULL];
		
	// Register private observers 
	[self registerObservers];
	[self updateVersionNumbers];
	mStartedUp = YES; 
}

- (NSString*) versionString {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersionString"];
}

- (NSString*) revisionString {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

#pragma mark -
#pragma mark Controllers 

- (VTDesktopController*) desktopController {
	return [VTDesktopController sharedInstance]; 
}

- (VTDesktopDecorationController*) desktopDecorationController {
	return [VTDesktopDecorationController sharedInstance]; 
}


#pragma mark -
#pragma mark Actions 

- (IBAction) showPreferences: (id) sender {
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES]; 
	NSWindow *prefWindow = [mPreferenceController window];
	[mPreferenceController showWindow: self];

	
}

- (IBAction) showHelp: (id) sender {
	[[NSApplication sharedApplication] showHelp: sender]; 
}

#pragma mark -
- (IBAction) showDesktopInspector: (id) sender {
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES]; 
	[self showDesktopInspectorForDesktop: [[VTDesktopController sharedInstance] activeDesktop]]; 
}

- (IBAction) showApplicationInspector: (id) sender {
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES]; 

	[mApplicationInspector window]; 
	[mApplicationInspector showWindow: sender]; 
}

- (IBAction) showStatusbarMenu: (id) sender {
	[self updateStatusItem]; 
}

#pragma mark -
- (IBAction) sendFeedback: (id) sender {
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: [NSString stringWithFormat:@"mailto:tony@tonyarnold.com?subject=VirtueDesktops%%20[%@]", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]]];
}

- (IBAction) showWebsite: (id) sender {
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://virtuedesktops.info"]];
}

- (IBAction) showForums: (id) sender {
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://forums.cocoaforge.com/viewforum.php?f=22"]];
}

- (IBAction) showDonationsPage: (id) sender {
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://virtuedesktops.info/donations"]];
}

#pragma mark -
- (IBAction) deleteActiveDesktop: (id) sender {
	// fetch index of active desktop to delete 
	int index = [[[VTDesktopController sharedInstance] desktops] indexOfObject: [[VTDesktopController sharedInstance] activeDesktop]]; 
	// and get rid of it 
	[[VTDesktopController sharedInstance] removeObjectFromDesktopsAtIndex: index]; 
}


#pragma mark -
#pragma mark NSApplication delegates 

- (void) applicationWillFinishLaunching: (NSNotification*) notification {}

- (void) applicationDidFinishLaunching: (NSNotification*) notification {
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
	[self bootstrap]; 
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *)sender {
	// Check if we are started up already 
	if (mStartedUp == NO) 
		return NSTerminateNow; 
	
	
	// Check if we should confirm that we are going to quit 
	if ([[NSUserDefaults standardUserDefaults] boolForKey: VTVirtueWarnBeforeQuitting] == YES && mConfirmQuitOverridden == NO) {
		[[NSApplication sharedApplication] activateIgnoringOtherApps: YES]; 
		
		// Display an alert to make sure the user knows what he is doing 
		NSAlert* alertWindow = [[NSAlert alloc] init]; 
		
		// Set-up 
		[alertWindow setAlertStyle:				NSInformationalAlertStyle]; 
		[alertWindow setMessageText:			NSLocalizedString(@"VTQuitConfirmationDialogMessage", @"Short message of the dialog")]; 
		[alertWindow setInformativeText:	NSLocalizedString(@"VTQuitConfirmationDialogDescription", @"Longer description about what will happen")];
		[alertWindow addButtonWithTitle:	NSLocalizedString(@"VTQuitConfirmationDialogCancel", @"Cancel Button")];
		[alertWindow addButtonWithTitle:	NSLocalizedString(@"VTQuitConfirmationDialogOK", @"OK Button")];
		
		int returnValue = [alertWindow runModal]; 
		
		[alertWindow release]; 
		
		if (returnValue == NSAlertFirstButtonReturn)
			return NSTerminateCancel; 
	}
	
	// Begin shutdown by moving all windows to the current desktop 
	if ([[NSUserDefaults standardUserDefaults] boolForKey: VTWindowsCollectOnQuit] == YES) {
		NSEnumerator*	desktopIter = [[[VTDesktopController sharedInstance] desktops] objectEnumerator]; 
		VTDesktop*		desktop		= nil; 
		VTDesktop*		target		= [[VTDesktopController sharedInstance] activeDesktop]; 
		
		while (desktop = [desktopIter nextObject]) {
			if ([desktop isEqual: target]) 
				continue; 
			
			[desktop moveAllWindowsToDesktop: target];
			if ([desktop defaultDesktopBackgroundPath] != nil)
				[desktop applyDefaultDesktopBackground];
		}
	}
	
	// and write out preferences to be sure 
	[[NSUserDefaults standardUserDefaults] synchronize]; 
	// persist desktops 
	[[VTDesktopController sharedInstance] serializeDesktops]; 
	// persist hotkeys 
	[[VTTriggerController sharedInstance] synchronize];
	// persist layouts 
	[[VTLayoutController sharedInstance] synchronize]; 
	
	
	return NSTerminateNow; 
}

/**
* @brief	Called upon reopening request by the user
 *
 * This implementation will show the preferences window, maybe we can make the 
 * action that should be carried out configurable, but for now this one is fine
 *
 */ 
- (BOOL) applicationShouldHandleReopen: (NSApplication*) theApplication hasVisibleWindows: (BOOL) flag {
	[self showPreferences: self];
	return NO;
}


- (BOOL) validateMenuItem:(id <NSMenuItem>)anItem {
	if (anItem == mStatusItemRemoveActiveDesktopItem) {	
		// if the number of desktops is 1 (one) we will disable the entry, otherwise 
		// enable it. 
		int numberOfDesktops = [[[VTDesktopController sharedInstance] desktops] count]; 
		
		return (numberOfDesktops > 1); 
	}
	
	return YES; 
}

- (void) menuNeedsUpdate: (NSMenu*) menu {
	if (menu != mStatusItemMenu)
		return; 
	
	// check if we need to update any menu entries and do so 
	if (mStatusItemMenuDesktopNeedsUpdate)
		[self updateDesktopsMenu]; 
	if (mStatusItemMenuActiveDesktopNeedsUpdate)
		[self updateActiveDesktopMenu]; 
}

#pragma mark -
#pragma mark Targets 

- (void) onMenuDesktopSelected: (id) sender {
	// fetch the represented object 
	VTDesktop* desktop = [sender representedObject]; 
	
	// and activate 
	[[VTDesktopController sharedInstance] activateDesktop: desktop]; 
}

- (void) onMenuApplicationWindowSelected: (id) sender {
}

#pragma mark -
#pragma mark Request Sinks

- (void) onSwitchToDesktopNorth: (NSNotification*) notification {
	[[VTDesktopController sharedInstance] activateDesktopInDirection: kVtDirectionNorth]; 
}

- (void) onSwitchToDesktopNortheast: (NSNotification*) notification {
	[[VTDesktopController sharedInstance] activateDesktopInDirection: kVtDirectionNortheast]; 
}

- (void) onSwitchToDesktopNorthwest: (NSNotification*) notification {
	[[VTDesktopController sharedInstance] activateDesktopInDirection: kVtDirectionNorthwest]; 
}

- (void) onSwitchToDesktopSouth: (NSNotification*) notification {
	[[VTDesktopController sharedInstance] activateDesktopInDirection: kVtDirectionSouth]; 
}

- (void) onSwitchToDesktopSoutheast: (NSNotification*) notification {
	[[VTDesktopController sharedInstance] activateDesktopInDirection: kVtDirectionSoutheast]; 
}

- (void) onSwitchToDesktopSouthwest: (NSNotification*) notification {
	[[VTDesktopController sharedInstance] activateDesktopInDirection: kVtDirectionSouthwest]; 
}

- (void) onSwitchToDesktopEast: (NSNotification*) notification {
	[[VTDesktopController sharedInstance] activateDesktopInDirection: kVtDirectionEast]; 
}

- (void) onSwitchToDesktopWest: (NSNotification*) notification {
	[[VTDesktopController sharedInstance] activateDesktopInDirection: kVtDirectionWest]; 
}

- (void) onSwitchToDesktop: (NSNotification*) notification {
	VTDesktop* targetDesktop = [[notification userInfo] objectForKey: VTRequestChangeDesktopParamName]; 
	// ignore empty desktop parameters 
	if (targetDesktop == nil)
		return; 
	
	[[VTDesktopController sharedInstance] activateDesktop: targetDesktop]; 
}

- (void) onMoveApplicationToDesktopEast: (NSNotification*) notification {
	[self moveFrontApplicationToDirection: kVtDirectionEast];
}

- (void) onMoveApplicationToDesktopWest: (NSNotification*) notification {
	[self moveFrontApplicationToDirection: kVtDirectionWest];
}

- (void) onMoveApplicationToDesktopSouth: (NSNotification*) notification {
	[self moveFrontApplicationToDirection: kVtDirectionSouth];
}

- (void) onMoveApplicationToDesktopNorth: (NSNotification*) notification {
	[self moveFrontApplicationToDirection: kVtDirectionNorth];
}

- (void) moveFrontApplicationToDirection: (VTDirection) direction {	
	VTDesktop* moveToDesktop = [[VTDesktopController sharedInstance] getDesktopInDirection: direction];
	VTDesktop* activeDesktop = [[VTDesktopController sharedInstance] activeDesktop];
	NSEnumerator* applicationIter = [[activeDesktop applications] objectEnumerator]; 
	PNApplication* application = nil;
	
	ProcessSerialNumber activePSN;
	OSErr result = GetFrontProcess(&activePSN);
	
	while (application = [applicationIter nextObject]) {
		ProcessSerialNumber currentPSN = [application psn];
		Boolean same;
	
		result = SameProcess(&activePSN, &currentPSN, &same);		
		if (same == TRUE) {
			[application setDesktop: moveToDesktop];
			[[[VTDesktopController sharedInstance] activeDesktop] updateDesktop];
			[moveToDesktop updateDesktop];
			[[VTDesktopController sharedInstance] activateDesktop: moveToDesktop];
			result = SetFrontProcess(&currentPSN);
			return;
		}
	}
}

#pragma mark -
- (void) onShowPager: (NSNotification*) notification {
	[[[[VTLayoutController sharedInstance] activeLayout] pager] display: NO]; 
}

- (void) onShowPagerSticky: (NSNotification*) notification {
	[[[[VTLayoutController sharedInstance] activeLayout] pager] display: YES]; 
}

#pragma mark -
- (void) onShowOperations: (NSNotification*) notification {
	[mOperationsController window]; 
	[mOperationsController display]; 
}

#pragma mark -
- (void) onShowDesktopInspector: (NSNotification*) notification {
	[self showDesktopInspector: self]; 
}

- (void) onShowPreferences: (NSNotification*) notification {
	[self showPreferences: self]; 
}

- (void) onShowApplicationInspector: (NSNotification*) notification {
	[self showApplicationInspector: self]; 
}



#pragma mark -
#pragma mark KVO Sinks 

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)anObject change:(NSDictionary *)theChange context:(void *)theContext
{
	if ([keyPath isEqualToString: @"desktops"] || [keyPath isEqualToString: @"activeLayout"] || [keyPath isEqualToString: @"activeLayout.desktops"]) {
		mStatusItemMenuDesktopNeedsUpdate = YES; 
	}
	else if ([keyPath isEqualToString: @"activeDesktop"]) {
		mStatusItemMenuDesktopNeedsUpdate = YES; 
		mStatusItemMenuActiveDesktopNeedsUpdate = YES; 

		VTDesktop* newDesktop = [theChange objectForKey: NSKeyValueChangeNewKey];  
		VTDesktop* oldDesktop = [theChange objectForKey: NSKeyValueChangeOldKey];
		
		// unregister from the old desktop and reregister at the new one 
		if (oldDesktop)
			[oldDesktop removeObserver: self forKeyPath: @"applications"]; 
		[newDesktop addObserver: self
					 forKeyPath: @"applications"
						options: NSKeyValueObservingOptionNew
						context: NULL]; 
		
		[self updateStatusItem]; 
	}
	else if ([keyPath isEqualToString: @"applications"]) {
		mStatusItemMenuDesktopNeedsUpdate = YES; 
		mStatusItemMenuActiveDesktopNeedsUpdate = YES; 
	}
	else if ([keyPath hasSuffix: VTVirtueShowStatusbarMenu]) {
		[self updateStatusItem]; 
	}
	else if ([keyPath hasSuffix: VTVirtueShowStatusbarDesktopName]) {
		[self updateStatusItem]; 
	}
}

@end

#pragma mark -
@implementation VTApplicationDelegate (Private) 

- (void) registerObservers {
	// register observers for requests 
	[[NSNotificationCenter defaultCenter]
		addObserver: self selector: @selector(onSwitchToDesktopNorth:) name: VTRequestChangeDesktopToNorthName object: nil]; 
	[[NSNotificationCenter defaultCenter]
		addObserver: self selector: @selector(onSwitchToDesktopNortheast:) name: VTRequestChangeDesktopToNortheastName object: nil];
	[[NSNotificationCenter defaultCenter]
		addObserver: self selector: @selector(onSwitchToDesktopNorthwest:) name: VTRequestChangeDesktopToNorthwestName object: nil];
	[[NSNotificationCenter defaultCenter]
		addObserver: self selector: @selector(onSwitchToDesktopEast:) name: VTRequestChangeDesktopToEastName object: nil]; 
	[[NSNotificationCenter defaultCenter]
		addObserver: self selector: @selector(onSwitchToDesktopSouth:) name: VTRequestChangeDesktopToSouthName object: nil];
	[[NSNotificationCenter defaultCenter]
		addObserver: self selector: @selector(onSwitchToDesktopSoutheast:) name: VTRequestChangeDesktopToSoutheastName object: nil];
	[[NSNotificationCenter defaultCenter]
		addObserver: self selector: @selector(onSwitchToDesktopSouthwest:) name: VTRequestChangeDesktopToSouthwestName object: nil];
	[[NSNotificationCenter defaultCenter]
		addObserver: self selector: @selector(onSwitchToDesktopWest:) name: VTRequestChangeDesktopToWestName object: nil]; 
	[[NSNotificationCenter defaultCenter]
		addObserver: self selector: @selector(onSwitchToDesktop:) name: VTRequestChangeDesktopName object: nil]; 
	
	[[NSNotificationCenter defaultCenter]
		addObserver: self selector: @selector(onShowPager:) name: VTRequestShowPagerName object: nil]; 
	[[NSNotificationCenter defaultCenter]
		addObserver: self selector: @selector(onShowPagerSticky:) name: VTRequestShowPagerAndStickName object: nil]; 
	
	[[NSNotificationCenter defaultCenter]
		addObserver: self selector: @selector(onShowOperations:) name: VTRequestDisplayOverlayName object: nil];

	[[NSNotificationCenter defaultCenter]
		addObserver: self selector: @selector(onShowDesktopInspector:) name: VTRequestInspectDesktopName object: nil]; 

	[[NSNotificationCenter defaultCenter]
		addObserver: self selector: @selector(onShowPreferences:) name: VTRequestInspectPreferencesName object: nil]; 
	
	[[[NSWorkspace sharedWorkspace] notificationCenter] 
		addObserver: self selector: @selector(invalidateQuitDialog:) name: NSWorkspaceWillPowerOffNotification object: [NSWorkspace sharedWorkspace]];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self selector: @selector(invalidateQuitDialog:) name: SUUpdaterWillRestartNotification object:nil];
		
	/** observers for moving applications */
	[[NSNotificationCenter defaultCenter]
		addObserver: self 
		selector: @selector(onMoveApplicationToDesktopEast:) 
		name: VTRequestApplicationMoveToEast 
		object: nil];

	[[NSNotificationCenter defaultCenter]
		addObserver: self 
		selector: @selector(onMoveApplicationToDesktopWest:) 
		name: VTRequestApplicationMoveToWest 
		object: nil];

	[[NSNotificationCenter defaultCenter]
		addObserver: self 
		selector: @selector(onMoveApplicationToDesktopSouth:) 
		name: VTRequestApplicationMoveToSouth 
		object: nil];

	[[NSNotificationCenter defaultCenter]
		addObserver: self 
		selector: @selector(onMoveApplicationToDesktopNorth:) 
		name: VTRequestApplicationMoveToNorth 
		object: nil];
	/** end of moving applications */
}

- (void) unregisterObservers {
	[[NSNotificationCenter defaultCenter] removeObserver: self]; 
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self];
}

#pragma mark -

- (void) updateStatusItem {
	BOOL showStatusItem = [[NSUserDefaults standardUserDefaults] boolForKey: VTVirtueShowStatusbarMenu];	
	
	if (showStatusItem == YES) {
		// create if necessary 
		if (mStatusItem == nil) {
			// set up the status bar and attach the menu 
			NSStatusBar* statusBar = [NSStatusBar systemStatusBar];
			
			// fetch the item and prepare it 
			mStatusItem = [[statusBar statusItemWithLength: NSVariableStatusItemLength] retain];
			
			// set up the status item 
			[mStatusItem setMenu: mStatusItemMenu];
			[mStatusItem setImage: [NSImage imageNamed: @"imageVirtue.png"]]; 
			[mStatusItem setAlternateImage: [NSImage imageNamed: @"imageVirtueHighlighted.png"]]; 
			[mStatusItem setHighlightMode: YES];
		}
		
		// check if we should set the desktop name as the title 
		if ([[NSUserDefaults standardUserDefaults] boolForKey: VTVirtueShowStatusbarDesktopName] == YES) {
			NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys: 
				[NSFont labelFontOfSize: 0], NSFontAttributeName,
				[NSColor darkGrayColor], NSForegroundColorAttributeName, 
				nil]; 
			
			NSString*			title			= [NSString stringWithFormat: @"[%@]", [[[VTDesktopController sharedInstance] activeDesktop] name]];
			NSAttributedString* attributedTitle = [[[NSAttributedString alloc] initWithString: title attributes: attributes] autorelease]; 
			
			[mStatusItem setAttributedTitle: attributedTitle]; 
		}
		else {
			[mStatusItem setTitle: @""];
		}
	}
	else {
		if (mStatusItem) {
			// remove the status item from the status bar and get rid of it 
			[[NSStatusBar systemStatusBar] removeStatusItem: mStatusItem]; 
			ZEN_RELEASE(mStatusItem); 			
		}
	}
}

- (void) updateDesktopsMenu {
	// we dont need to do this if there is no status item 
	if (mStatusItem == nil)
		return; 
	
	mStatusItemMenuDesktopNeedsUpdate = NO; 
	
	// first remove all items that have no associated object
	NSArray*				menuItems			= [mStatusItemMenu itemArray]; 
	NSEnumerator*   menuItemIter	= [menuItems objectEnumerator]; 
	NSMenuItem*			menuItem			= nil; 
	
	while (menuItem = [menuItemIter nextObject]) {
		// check if we should remove the item 
		if ([[menuItem representedObject] isKindOfClass: [VTDesktop class]]) {
			[mStatusItemMenu removeItem: menuItem]; 
		}
	}
	
	// now we can readd the items 
	NSEnumerator*	desktopIter		= [[[[[VTLayoutController sharedInstance] activeLayout] desktops] objectEnumerator] retain]; 
	NSString*			uuid					= nil; 
	VTDesktop*		desktop				= nil; 
	int						currentIndex	= 0; 
	
	while (uuid = [desktopIter nextObject]) {
		// get desktop 
		desktop = [[VTDesktopController sharedInstance] desktopWithUUID: uuid]; 
		
		// we will only include filled slots and skip emtpy ones 
		if (desktop == nil)
			continue; 
		
		NSMenuItem* menuItem = [[NSMenuItem alloc] 
			initWithTitle: ([desktop name] == nil ? @" " : [desktop name])
			action: @selector(onMenuDesktopSelected:)
			keyEquivalent: @""];
		[menuItem setRepresentedObject: desktop]; 
		[menuItem setEnabled: YES]; 
		
		// decide on which image to set 
		if ([desktop visible] == YES)
			[menuItem setImage: [NSImage imageNamed: @"imageDesktopActive.png"]]; 
		else if ([[desktop windows] count] == 0)
			[menuItem setImage: [NSImage imageNamed: @"imageDesktopEmpty.png"]];
		else 
			[menuItem setImage: [NSImage imageNamed: @"imageDesktopPopulated.png"]]; 
		
		[mStatusItemMenu insertItem: menuItem atIndex: currentIndex++];
		// free temporary instance 
		[menuItem release]; 
	}
	
	[desktopIter release]; 
}

- (void) updateActiveDesktopMenu
{
	// we dont need to do this if there is no status item 
	if (mStatusItem == nil)
		return; 
	
	mStatusItemMenuActiveDesktopNeedsUpdate = NO; 
	
	// first remove all items that have no associated object
	NSArray*		menuItems		= [mStatusItemActiveDesktopItem itemArray]; 
	NSEnumerator*   menuItemIter	= [menuItems objectEnumerator]; 
	NSMenuItem*		menuItem		= nil; 
	
	while (menuItem = [menuItemIter nextObject]) {
		// check if the menu item is marked by us, and if so, we will remove it 
		if ([menuItem tag] == kVtMenuItemMagicNumber)
			[mStatusItemActiveDesktopItem removeItem: menuItem]; 
	}
	
	NSArray*		applications	= [[[VTDesktopController sharedInstance] activeDesktop] applications]; 
	NSEnumerator*   applicationIter = [applications objectEnumerator]; 
	PNApplication*	application		= nil; 
	
	NSSize			iconSize; 
	iconSize.width	= 16; 
	iconSize.height = 16;
	
	while (application = [applicationIter nextObject]) {
		NSString*	applicationTitle	= [application name]; 
		NSImage*	applicationIcon		= [application icon]; 
		[applicationIcon setSize: iconSize]; 
		
		// do not add nil or empty application titles to the menu 
		if ((applicationTitle == nil) || ([applicationTitle length] == 0))
			continue; 
		
		NSMenuItem* menuItem = [[NSMenuItem alloc] 
			initWithTitle: applicationTitle 
			action: nil
			keyEquivalent: @""];
		[menuItem setRepresentedObject: application]; 
		[menuItem setEnabled: YES]; 
		[menuItem setImage: applicationIcon];  
		[menuItem setTag: kVtMenuItemMagicNumber]; 
		[menuItem setTarget: self]; 
		[menuItem setAction: @selector(onMenuApplicationWindowSelected:)]; 
				
		[mStatusItemActiveDesktopItem addItem: menuItem]; 
		// get rid of temporary instance 
		[menuItem release]; 
	}
	
	// if there were no entries to be made, we will add a placeholder 
	if ([applications count] == 0) {
		NSMenuItem* menuItem = [[NSMenuItem alloc] 
			initWithTitle: NSLocalizedString(@"VTStatusbarMenuNoApplication", @"No Applications placeholder")
			action: nil
			keyEquivalent: @""];
		[menuItem setEnabled: NO]; 
		[menuItem setTag: kVtMenuItemMagicNumber]; 
		
		[mStatusItemActiveDesktopItem addItem: menuItem]; 
		// get rid of temporary instance 
		[menuItem release]; 
	}
}

- (void) updateVersionNumbers {
	[mVersionTextField setStringValue:[NSString stringWithFormat:@"Version %@ (%@)", [self versionString], [self revisionString]]];
}

#pragma mark -

- (void) showDesktopInspectorForDesktop: (VTDesktop*) desktop {
	// and activate ourselves
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES]; 
	// show the window we manage there 
	[mDesktopInspector window]; 
	[mDesktopInspector showWindowForDesktop: desktop]; 
}

#pragma mark -

- (void) invalidateQuitDialog:(NSNotification *)aNotification
{
	// If we're shutting down, logging out, restarting or auto-updating via Sparkle, we don't want to ask the user if we should quit. They have already made that decision for us.
	mConfirmQuitOverridden = YES;
}


#pragma mark -

- (NSString *)preferencesFolder {
	NSString *preferencesFolder = nil;
	FSRef foundRef;
	OSErr err = FSFindFolder(kUserDomain, kPreferencesFolderType, kDontCreateFolder, &foundRef);
	if (err != noErr) {
		NSRunAlertPanel(@"Alert", @"Can't find preferences folder", @"Quit", nil, nil);
		[[NSApplication sharedApplication] terminate:self];
	} else {
		unsigned char path[PATH_MAX];
		FSRefMakePath(&foundRef, path, sizeof(path));
		preferencesFolder = [NSString stringWithUTF8String:(char *)path];
	}
	return preferencesFolder;
}

- (NSString*) applicationSupportFolder {
	NSString *applicationSupportFolder = nil;
	FSRef foundRef;
	OSErr err = FSFindFolder(kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, &foundRef);
	if (err != noErr) {
		NSRunAlertPanel(@"Alert", @"Can't find application support folder", @"Quit", nil, nil);
		[[NSApplication sharedApplication] terminate:self];
	} else {
		unsigned char path[PATH_MAX];
		FSRefMakePath(&foundRef, path, sizeof(path));
		applicationSupportFolder = [NSString stringWithUTF8String:(char *)path];
	}
	return applicationSupportFolder;
}

- (void) migrateOldPreferences
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSString *oldPlist = [[self preferencesFolder] stringByAppendingPathComponent:@"net.sourceforge.virtue.Virtue.plist"];
	NSString *newPlist = [[self preferencesFolder] stringByAppendingPathComponent:@"info.virtuedesktops.VirtueDesktops.plist"];
	
	if	(![fileManager fileExistsAtPath: newPlist] && [fileManager fileExistsAtPath: oldPlist]) 
	{
		[fileManager movePath: oldPlist
									 toPath: newPlist
									handler: nil];
	}
	
	NSString *oldAppSupportFolder = [[self applicationSupportFolder] stringByAppendingPathComponent:@"Virtue"];
	NSString *newAppSupportFolder = [[self applicationSupportFolder] stringByAppendingPathComponent:@"VirtueDesktops"];
	
	if	(![fileManager fileExistsAtPath: newAppSupportFolder] && [fileManager fileExistsAtPath: oldAppSupportFolder]) 
	{
		[fileManager movePath: oldAppSupportFolder
									 toPath: newAppSupportFolder
									handler: nil];
	}
}

@end 