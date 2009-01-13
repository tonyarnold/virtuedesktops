/******************************************************************************
*
* Virtue
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2007, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
*
*****************************************************************************/
#import "VTDesktopBackgroundHelper.h"
#import "VTDesktopController.h"
#import "VTDesktopDecorationController.h"
#import "VTLayoutController.h"
#import "VTTriggerController.h"
#import "VTApplicationController.h"
#import "VTPreferences.h"
#import "VTNotifications.h"
#import "NSUserDefaultsControllerKeyFactory.h"
#import "VTFileSystemExtensions.h"
#import <Peony/Peony.h>
#import <Zen/Zen.h>
#import <Sparkle/Sparkle.h>
#import <Growl/Growl.h>

#import "VTApplicationDelegate.h"
#import "VTMatrixDesktopLayout.h"
#import "VTDesktopViewController.h"
#import "VTApplicationViewController.h"
#import "VTPreferenceKeys.h"

#import "DECInjector.h"

enum
{
	kVtMenuItemMagicNumber			= 666,
	kVtMenuItemRemoveMagicNumber	= 667,
};



@interface VTApplicationDelegate (Private)
- (void) registerObservers;
- (void) unregisterObservers;
#pragma mark -
- (void) updateStatusItem;
- (void) updateDesktopsMenu;
- (void) updateActiveDesktopMenu;
#pragma mark -
- (void) showDesktopInspectorForDesktop: (VTDesktop*) desktop;
- (void) invalidateQuitDialog:(NSNotification *)aNotification;
- (void) migrateOldPreferences;
@end

@implementation VTApplicationDelegate

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
		[[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
		
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
	
	[mPluginController unloadPlugins];
	ZEN_RELEASE(mPluginController);
  
	[self unregisterObservers];
	[super dealloc];
}

#pragma mark -
#pragma mark Bootstrapping
- (void) bootstrap {
	// This registers us to recieve NSWorkspace notifications, even though we are have LSUIElement enabled
	[NSApplication sharedApplication];
  
  // Retrieve the current version of the DockExtension, and whether it is currently loaded into the Dock process
	int dockCodeIsInjected		= 0;
	int dockCodeMajorVersion	= 0;
	int dockCodeMinorVersion	= 0;
	dec_info(&dockCodeIsInjected,&dockCodeMajorVersion,&dockCodeMinorVersion);
  
	// Inject dock extension code into the Dock process if it hasn't been already
	if (dockCodeIsInjected != 1) {
		if (dec_inject_code() != 0) {
#if defined(__i386__) 
      if ([self checkExecutablePermissions] == NO) {
        
        // @TODO@ Localise this alert
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText: NSLocalizedString(@"VTPermsNeedsAttention", @"Alert title")];
        [alert addButtonWithTitle: NSLocalizedString(@"VTPermsOKButton", @"Go ahead and fix permissions")];
        [alert addButtonWithTitle: NSLocalizedString(@"VTPermsIgnoreButton", @"Ignore the alert and continue without fixing permissions")];
        [alert setInformativeText: NSLocalizedString(@"VTPermsMessage", @"Longer description about what will happen")];
        [alert setAlertStyle: NSWarningAlertStyle];
        [alert setDelegate: self];
        if ([alert runModal] == NSAlertFirstButtonReturn) {
          [self fixExecutablePermissions: self];
        }
      }
#endif /* __i386__ */
			[[NSUserDefaults standardUserDefaults] setBool: NO forKey: @"DockExtensionLoaded"];
		} else {
			[[NSUserDefaults standardUserDefaults] setBool: YES forKey: @"DockExtensionLoaded"];
		}
	}
	
	// @TODO: Remove this transitional migration code in 0.7+
	// This method migrates any old sourceforge identified preferences to new plist
	[self migrateOldPreferences];
	
	// Set-up default preferences
	[VTPreferences registerDefaults];

	// and ensure we have our version information in there
	[[NSUserDefaults standardUserDefaults] setObject: [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forKey:@"VTPreferencesVirtueVersionName"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// Load plugin controller, then any plugins present in our search path(s)
	mPluginController = [[VTPluginController alloc] init];
	[mPluginController loadPlugins];
	
	// Read our desktops from disk (if they exist), otherwise populate the defaults
	[VTDesktopController			sharedInstance];
	[[VTDesktopController			sharedInstance] deserializeDesktops];
	
	// Create/Instantiate our controllers
	[VTDesktopBackgroundHelper      sharedInstance];
	[VTDesktopDecorationController	sharedInstance];
	[VTTriggerController            sharedInstance];
	[VTLayoutController             sharedInstance];
	[VTApplicationController        sharedInstance];
	
	mPreferenceController	= [[VTPreferencesViewController alloc] init];
	mOperationsController	= [[VTOperationsViewController alloc] init];
	mApplicationWatcher		= [[VTApplicationWatcherController alloc] init];
	mDesktopInspector     = [[VTDesktopViewController alloc] init];
	mApplicationInspector	= [[VTApplicationViewController alloc] init];
	
	// Interface controllers
	mNotificationBezel = [[VTNotificationBezel alloc] init];
	
	// Make sure we have our default matrix layout created
	NSArray*          layouts = [[VTLayoutController sharedInstance] layouts];
	VTDesktopLayout*	layout	= nil;
	
	if (layouts) {
		NSEnumerator* iterator = [layouts objectEnumerator];
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
	[[VTDesktopController sharedInstance] setUsesDecorationPrototype: [[NSUserDefaults standardUserDefaults] boolForKey: VTPreferencesUsesDecorationTemplateName]];
	
	// and bind setting
	[[NSUserDefaults standardUserDefaults] setBool: [[VTDesktopController sharedInstance] usesDecorationPrototype] forKey: VTPreferencesUsesDecorationTemplateName];
	
	[[VTDesktopController sharedInstance] bind: @"usesDecorationPrototype" toObject: [NSUserDefaultsController sharedUserDefaultsController] withKeyPath: [NSUserDefaultsController pathForKey: VTPreferencesUsesDecorationTemplateName] options: nil];
	
	
	//Motion Sensor
	[[NSUserDefaults standardUserDefaults] setBool: [[NSUserDefaults standardUserDefaults] boolForKey: VTMotionSensorEnabled] forKey: VTMotionSensorEnabled];
	// Bind the motion sensitivity preferences to the motion controller object
	[[VTMotionController sharedInstance] bind: @"isEnabled" toObject: [NSUserDefaultsController sharedUserDefaultsController] withKeyPath: [NSUserDefaultsController pathForKey: VTMotionSensorEnabled] options: nil];
	
	[[NSUserDefaults standardUserDefaults] setFloat: [[NSUserDefaults standardUserDefaults] floatForKey: VTMotionSensorSensitivity] forKey: VTMotionSensorSensitivity];
	[[VTMotionController sharedInstance] bind: @"sensorSensitivity" toObject: [NSUserDefaultsController sharedUserDefaultsController] withKeyPath: [NSUserDefaultsController pathForKey: VTMotionSensorSensitivity] options: nil];
	
	
	// ALSensor
	[[NSUserDefaults standardUserDefaults] setBool: [[NSUserDefaults standardUserDefaults] boolForKey: VTLightSensorEnabled] forKey: VTLightSensorEnabled];
	// Bind the motion sensitivity preferences to the motion controller object
	[[VTLightSensorController sharedInstance] bind: @"isEnabled" toObject: [NSUserDefaultsController sharedUserDefaultsController] withKeyPath: [NSUserDefaultsController pathForKey: VTLightSensorEnabled] options: nil];
	
	[[NSUserDefaults standardUserDefaults] setFloat: [[NSUserDefaults standardUserDefaults] floatForKey: VTLightSensorSensitivity] forKey: VTLightSensorSensitivity];
	[[VTLightSensorController sharedInstance] bind: @"sensorSensitivity" toObject: [NSUserDefaultsController sharedUserDefaultsController] withKeyPath: [NSUserDefaultsController pathForKey: VTLightSensorSensitivity] options: nil];
	
	// Decode application preferences…
	NSDictionary* applicationDict = [[NSUserDefaults standardUserDefaults] objectForKey: VTPreferencesApplicationsName];
	if (applicationDict)
		[[VTApplicationController sharedInstance] decodeFromDictionary: applicationDict];
	
	// …and scan for initial applications
	[[VTApplicationController sharedInstance] scanApplications];
	
	// Update status item
	[self updateStatusItem];
	
	// Update items within the status menu
	[self updateDesktopsMenu];
	[self updateActiveDesktopMenu];
	
	// Register observers
	[[VTLayoutController sharedInstance] addObserver: self forKeyPath: @"activeLayout" options: NSKeyValueObservingOptionNew context: NULL];
	
	[[VTLayoutController sharedInstance] addObserver: self forKeyPath: @"activeLayout.desktops" options: NSKeyValueObservingOptionNew context: NULL];
	
	[[VTDesktopController sharedInstance] addObserver: self forKeyPath: @"desktops" options: NSKeyValueObservingOptionNew context: NULL];
	
	[[VTDesktopController sharedInstance] addObserver: self forKeyPath: @"activeDesktop" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context: NULL];
	
	[[[VTDesktopController sharedInstance] activeDesktop] addObserver: self forKeyPath: @"applications" options: NSKeyValueObservingOptionNew context: NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver: self forKeyPath: [NSUserDefaultsController pathForKey: VTVirtueShowStatusbarDesktopName] options: NSKeyValueObservingOptionNew context: NULL];
	
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver: self forKeyPath: [NSUserDefaultsController pathForKey: VTVirtueShowStatusbarMenu] options: NSKeyValueObservingOptionNew context: NULL];
	
  NSBundle *myBundle = [NSBundle bundleForClass: [VTApplicationDelegate class]];
  NSString *growlPath = [[myBundle privateFrameworksPath] stringByAppendingPathComponent:@"Growl.framework"];
  NSBundle *growlBundle = [NSBundle bundleWithPath: growlPath];
  if (growlBundle && [growlBundle load]) {
    // Register ourselves as a Growl delegate
    [GrowlApplicationBridge setGrowlDelegate:self];
  } else {
    NSLog(@"Could not load Growl.framework");
  }
    
	// Register private observers
	[self registerObservers];
  
  // Enable hotkeys/triggers
  [[VTTriggerController sharedInstance] setEnabled: YES];
	
	// We're all startup up!
	mStartedUp = YES;
  
  // If this is the first time the user has used VirtueDesktops, show a welcome screen to set the most important options.
  if ([[NSUserDefaults standardUserDefaults] boolForKey: VTVirtueWelcomeShown] == NO) {
    [mWelcomePanel center];
    [self showWelcomePanel: nil];
    [[NSUserDefaults standardUserDefaults] setBool: YES forKey: VTVirtueWelcomeShown];
  }
}

- (NSString*) versionString {
	return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
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
	[mPreferenceController showWindow: self];
}

- (IBAction) showHelp: (id) sender {
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
	[[NSApplication sharedApplication] showHelp: sender];
}

#pragma mark -
- (IBAction) showDesktopInspector: (id) sender {
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
	[self showDesktopInspectorForDesktop: [[VTDesktopController sharedInstance] activeDesktop]];
}

- (IBAction) showApplicationInspector: (id) sender {
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
	[mApplicationInspector showWindow: sender];
}

- (IBAction) showStatusbarMenu: (id) sender {
	[self updateStatusItem];
}

- (IBAction) showWelcomePanel: (id) sender {
  [[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
  [mWelcomePanel makeKeyAndOrderFront: sender];
}

#pragma mark -
- (IBAction) showAboutPanel: (id) sender
{
  [[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
  [mAboutPanel makeKeyAndOrderFront: sender];
}

- (IBAction) sendFeedback: (id) sender {
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: [NSString stringWithFormat:@"mailto:tony@tonyarnold.com?subject=VirtueDesktops%%20Feedback%%20[%@]", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]]];
}

- (IBAction) showWebsite: (id) sender {
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://virtuedesktops.info"]];
}

- (IBAction) showForums: (id) sender {
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://forums.cocoaforge.com/viewforum.php?f=22"]];
}

- (IBAction) showDonationsPage: (id) sender {
	[[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://virtuedesktops.info/index.php/donations"]];
}

#pragma mark -
- (IBAction) deleteActiveDesktop: (id) sender {
	// fetch index of active desktop to delete
	int desktopIndex = [[[VTDesktopController sharedInstance] desktops] indexOfObject: [[VTDesktopController sharedInstance] activeDesktop]];
	// and get rid of it
	[[VTDesktopController sharedInstance] removeObjectFromDesktopsAtIndex: desktopIndex];
}

- (BOOL) checkExecutablePermissions {
	NSDictionary	*applicationAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:[[NSBundle mainBundle] executablePath] traverseLink: YES];
	
	// We expect 2755 as octal (1517 as decimal, -rwxr-sr-x as extended notation)
	return ([applicationAttributes filePosixPermissions] == 1517 && [[applicationAttributes fileGroupOwnerAccountName] isEqualToString: @"procmod"]);
}

- (IBAction) fixExecutablePermissions: (id) sender {
	// If we were not able to inject code, with fix the executable by changing it's group to procmod (9) and by setting the set-group-ID-on-execution bit
	fixVirtueDesktopsExecutable([[[NSBundle mainBundle] executablePath] fileSystemRepresentation]);	
	
	[[NSUserDefaults standardUserDefaults] setBool: YES	forKey: @"PermissionsFixed"];
	// We override asking us whether we want to quit, because the user really doesn't have any choice.
	mConfirmQuitOverridden = YES;
	
	// Thanks to Allan Odgaard for this restart code, which is much more clever than mine was.
        setenv("LAUNCH_PATH", [[[NSBundle mainBundle] bundlePath] UTF8String], 1);
        system("/bin/bash -c '{ for (( i = 0; i < 3000 && $(echo $(/bin/ps -xp $PPID|/usr/bin/wc -l))-1; i++ )); do\n"
         "    /bin/sleep .2;\n"
         "  done\n"
         "  if [[ $(/bin/ps -xp $PPID|/usr/bin/wc -l) -ne 2 ]]; then\n"
         "    /usr/bin/open \"${LAUNCH_PATH}\"\n"
         "  fi\n"
         "} &>/dev/null &'");
	[[NSApplication sharedApplication] terminate:self];
}

#pragma mark -
#pragma mark NSAlert delegate

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
  if (returnCode == NSAlertFirstButtonReturn) {
    [self fixExecutablePermissions: self];
  }
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
		
		// Display an alert to make sure the user knows what they are doing
		NSAlert* alertWindow = [[NSAlert alloc] init];
		
		// Set-up
		[alertWindow setAlertStyle:			NSInformationalAlertStyle];
		[alertWindow setMessageText:		NSLocalizedString(@"VTQuitConfirmationDialogMessage", @"Short message of the dialog")];
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

    int desktopId   = [VTDesktop firstDesktopIdentifier] + [[[VTDesktopController sharedInstance] desktops] count] - 1;
    if ([target identifier] >= desktopId) {
      [PNDesktop setDesktopId:desktopId];
    } else {
      desktopId = [target identifier];
    }
    
		while (desktop = [desktopIter nextObject]) {
			if ([desktop identifier] == desktopId)
				continue;
			
			PNWindowList *list = [[PNWindowPool sharedWindowPool] windowsOnDesktopId:[desktop identifier]];
      [list setDesktopId:desktopId];
      [list release];
		}
	}
	
	// Reset desktop picture to the default
	[[VTDesktopBackgroundHelper sharedInstance] setBackground: [[VTDesktopBackgroundHelper sharedInstance] defaultBackground]];
	
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
	[self moveFrontApplicationInDirection: kVtDirectionEast];
}

- (void) onMoveApplicationToDesktopWest: (NSNotification*) notification {
	[self moveFrontApplicationInDirection: kVtDirectionWest];
}

- (void) onMoveApplicationToDesktopSouth: (NSNotification*) notification {
	[self moveFrontApplicationInDirection: kVtDirectionSouth];
}

- (void) onMoveApplicationToDesktopNorth: (NSNotification*) notification {
	[self moveFrontApplicationInDirection: kVtDirectionNorth];
}

- (void) moveFrontApplicationInDirection: (VTDirection) direction {
	VTDesktop* moveToDesktop = [[VTDesktopController sharedInstance] getDesktopInDirection: direction];
	VTDesktop* activeDesktop = [[VTDesktopController sharedInstance] activeDesktop];
	
	ProcessSerialNumber activePSN;
	OSErr result = GetFrontProcess(&activePSN);
	PNApplication* application    = [activeDesktop applicationForPSN: activePSN];

	if (application != nil) {
		[application setDesktop: moveToDesktop];
		[[[VTDesktopController sharedInstance] activeDesktop] updateDesktop];
		[moveToDesktop updateDesktop];
		[[VTDesktopController sharedInstance] activateDesktop: moveToDesktop];
		result = SetFrontProcess(&activePSN);
		return;
	}
}

- (void) onSendWindowBack: (NSNotification*) notification {
	[[VTDesktopController sharedInstance] sendWindowUnderCursorBack];
}

- (void) onSendWindowLeft: (NSNotification*) notification {
  [[VTDesktopController sharedInstance] moveWindowUnderCursorToDesktop: [[VTDesktopController sharedInstance] getDesktopInDirection: kVtDirectionWest]];
}

- (void) onSendWindowRight: (NSNotification*) notification {
  [[VTDesktopController sharedInstance] moveWindowUnderCursorToDesktop: [[VTDesktopController sharedInstance] getDesktopInDirection: kVtDirectionEast]];
}

- (void) onSendWindowUp: (NSNotification*) notification {
  [[VTDesktopController sharedInstance] moveWindowUnderCursorToDesktop: [[VTDesktopController sharedInstance] getDesktopInDirection: kVtDirectionNorth]];
}

- (void) onSendWindowDown: (NSNotification*) notification {
  [[VTDesktopController sharedInstance] moveWindowUnderCursorToDesktop: [[VTDesktopController sharedInstance] getDesktopInDirection: kVtDirectionSouth]];
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

- (void) onDesktopDidChange: (NSNotification*) notification
{
  [self updateStatusItem];
  [self updateDesktopsMenu];
  [self updateActiveDesktopMenu];
}

#pragma mark -
#pragma mark KVO Sinks

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)anObject change:(NSDictionary *)theChange context:(void *)theContext
{
	if ([keyPath isEqualToString: @"desktops"] || [keyPath isEqualToString: @"activeLayout"] || [keyPath isEqualToString: @"activeLayout.desktops"]) 
  {
		mStatusItemMenuDesktopNeedsUpdate = YES;
	}
	else if ([keyPath isEqualToString: @"activeDesktop"]) 
  {
		mStatusItemMenuDesktopNeedsUpdate = YES;
		mStatusItemMenuActiveDesktopNeedsUpdate = YES;
		
		VTDesktop* newDesktop = [theChange objectForKey: NSKeyValueChangeNewKey];
		VTDesktop* oldDesktop = [theChange objectForKey: NSKeyValueChangeOldKey];
    
		// unregister from the old desktop and reregister at the new one
		if (oldDesktop)
			[oldDesktop removeObserver: self forKeyPath: @"applications"];
		
		[newDesktop addObserver: self forKeyPath: @"applications" options: NSKeyValueObservingOptionNew context: NULL];
		
		[self updateStatusItem];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey: VTGrowlEnabled] == YES)
      [self performSelector: @selector(postGrowlNotification) withObject: nil afterDelay: 1.0];
    
	}
	else if ([keyPath isEqualToString: @"applications"]) 
  {
		mStatusItemMenuDesktopNeedsUpdate = YES;
		mStatusItemMenuActiveDesktopNeedsUpdate = YES;
	}
	else if ([keyPath hasSuffix: VTVirtueShowStatusbarMenu]) 
  {
		[self updateStatusItem];
	}
	else if ([keyPath hasSuffix: VTVirtueShowStatusbarDesktopName]) 
  {
		[self updateStatusItem];
	}
}

#pragma mark Growl

/*!
* @brief Returns the application name Growl will use
 */
- (NSString *)applicationNameForGrowl
{
	return @"VirtueDesktops";
}

/*!
* @brief Registration information for Growl
 *
 * Returns information that Growl needs, like which notifications we will post and our application name.
 */
- (NSDictionary *)registrationDictionaryForGrowl
{
	NSMutableArray *allNotes = [NSMutableArray arrayWithObjects: @"Desktop changed", nil];
	NSDictionary	*growlReg = [NSDictionary dictionaryWithObjectsAndKeys: allNotes, GROWL_NOTIFICATIONS_ALL, allNotes, GROWL_NOTIFICATIONS_DEFAULT, nil];
	
	return growlReg;
}

- (void)postGrowlNotification {
  // Only post notifications if growl is installed and running
  [GrowlApplicationBridge notifyWithTitle: [NSString stringWithFormat: NSLocalizedString(@"VTGrowlDesktopChangedMessage", @"Message shown when changing desktops"), [[[VTDesktopController sharedInstance] activeDesktop] name]] description: nil notificationName: NSLocalizedString(@"VTGrowlDesktopChangedTitle", @"Title shown when changing desktops") iconData: nil priority: 0 isSticky: NO clickContext: nil];
}

@end

#pragma mark -
@implementation VTApplicationDelegate (Private)

- (void) registerObservers {
	// register observers for requests
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onSwitchToDesktopNorth:) name: VTRequestChangeDesktopToNorthName object: nil];
	[[NSNotificationCenter defaultCenter]	addObserver: self selector: @selector(onSwitchToDesktopNortheast:) name: VTRequestChangeDesktopToNortheastName object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onSwitchToDesktopNorthwest:) name: VTRequestChangeDesktopToNorthwestName object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onSwitchToDesktopEast:) name: VTRequestChangeDesktopToEastName object: nil];
	[[NSNotificationCenter defaultCenter]	addObserver: self selector: @selector(onSwitchToDesktopSouth:) name: VTRequestChangeDesktopToSouthName object: nil];
	[[NSNotificationCenter defaultCenter]	addObserver: self selector: @selector(onSwitchToDesktopSoutheast:) name: VTRequestChangeDesktopToSoutheastName object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onSwitchToDesktopSouthwest:) name: VTRequestChangeDesktopToSouthwestName object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onSwitchToDesktopWest:) name: VTRequestChangeDesktopToWestName object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onSwitchToDesktop:) name: VTRequestChangeDesktopName object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onSendWindowBack:) name: VTRequestSendWindowBackName object: nil];
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onSendWindowLeft:) name: VTRequestMoveWindowLeft object: nil];
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onSendWindowRight:) name: VTRequestMoveWindowRight object: nil];
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onSendWindowUp:) name: VTRequestMoveWindowUp object: nil];
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onSendWindowDown:) name: VTRequestMoveWindowDown object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onShowPager:) name: VTRequestShowPagerName object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onShowPagerSticky:) name: VTRequestShowPagerAndStickName object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onShowOperations:) name: VTRequestDisplayOverlayName object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onShowDesktopInspector:) name: VTRequestInspectDesktopName object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onShowApplicationInspector:) name: VTRequestInspectApplicationsName object: nil];    
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onShowPreferences:) name: VTRequestInspectPreferencesName object: nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(invalidateQuitDialog:) name: NSWorkspaceWillPowerOffNotification object: [NSWorkspace sharedWorkspace]];
  [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector(invalidateQuitDialog:) name: SUUpdaterWillRestartNotification object:nil];
	
	/** observers for moving applications */
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onMoveApplicationToDesktopEast:) name: VTRequestApplicationMoveToEast object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onMoveApplicationToDesktopWest:) name: VTRequestApplicationMoveToWest object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onMoveApplicationToDesktopSouth:) name: VTRequestApplicationMoveToSouth object: nil];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onMoveApplicationToDesktopNorth:) name: VTRequestApplicationMoveToNorth  object: nil];
	/** end of moving applications */
  
  [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopDidChange:) name: PNDesktopDidChangeName object: nil];
}

- (void) unregisterObservers {
  [[VTLayoutController sharedInstance] removeObserver: self forKeyPath: @"activeLayout"];
	[[VTLayoutController sharedInstance] removeObserver: self forKeyPath: @"activeLayout.desktops"];
	[[VTDesktopController sharedInstance] removeObserver: self forKeyPath: @"desktops"];
	[[VTDesktopController sharedInstance] removeObserver: self forKeyPath: @"activeDesktop"];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver: self forKeyPath: [NSUserDefaultsController pathForKey: VTVirtueShowStatusbarDesktopName]];
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver: self forKeyPath: [NSUserDefaultsController pathForKey: VTVirtueShowStatusbarMenu]];
  
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver: self];
}

#pragma mark -

- (void) updateStatusItem {
	if ([[NSUserDefaults standardUserDefaults] boolForKey: VTVirtueShowStatusbarMenu] == YES) {
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
			NSString *stringTitle = [NSString stringWithFormat: @"[%@]", [[[VTDesktopController sharedInstance] activeDesktop] name]];
			NSAttributedString *attributedStringTitle = [[NSAttributedString alloc] initWithString: stringTitle attributes: [NSDictionary dictionaryWithObjectsAndKeys: [NSFont labelFontOfSize: 0], NSFontAttributeName, [NSColor darkGrayColor], NSForegroundColorAttributeName, nil]];
			
			[mStatusItem setAttributedTitle: attributedStringTitle];
      [attributedStringTitle release];
		}
		else {
			[mStatusItem setTitle: @""];
		}
	}
	else {
		if (mStatusItem) {
			// remove the status item from the status bar and get rid of it
			[[NSStatusBar systemStatusBar] removeStatusItem: mStatusItem];
			[mStatusItem release];
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
	
	// now we can read the items
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
		
		menuItem = [[NSMenuItem alloc] initWithTitle: ([desktop name] == nil ? @" " : [desktop name]) action: @selector(onMenuDesktopSelected:) keyEquivalent: @""];
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
	NSArray*        menuItems     = [mStatusItemActiveDesktopItem itemArray];
	NSEnumerator*   menuItemIter	= [menuItems objectEnumerator];
	NSMenuItem*     menuItem      = nil;
	
	while (menuItem = [menuItemIter nextObject]) {
		// check if the menu item is marked by us, and if so, we will remove it
		if ([menuItem tag] == kVtMenuItemMagicNumber)
			[mStatusItemActiveDesktopItem removeItem: menuItem];
	}
	
	NSArray*        applications    = [[[VTDesktopController sharedInstance] activeDesktop] applications];
	NSEnumerator*   applicationIter = [applications objectEnumerator];
	PNApplication*	application     = nil;
	
	while (application = [applicationIter nextObject]) {
		NSString*	applicationTitle	= [application name];
		// do not add nil or empty application titles to the menu
		if ((applicationTitle == nil) || ([applicationTitle length] == 0))
			continue;
    
		
		menuItem = [[NSMenuItem alloc] initWithTitle: applicationTitle action: nil keyEquivalent: @""];
		[menuItem setRepresentedObject: application];
		[menuItem setEnabled: YES];
    
    NSImage*	applicationIcon		= [application icon];
    [applicationIcon setSize: NSMakeSize(32.0,32.0)];
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
		menuItem = [[NSMenuItem alloc]
		initWithTitle: NSLocalizedString(@"VTStatusbarMenuNoApplication", @"No applications placeholder")
           action: nil
		keyEquivalent: @""];
		[menuItem setEnabled: NO];
		[menuItem setTag: kVtMenuItemMagicNumber];
		
		[mStatusItemActiveDesktopItem addItem: menuItem];
		// get rid of temporary instance
		[menuItem release];
	}
}

#pragma mark -

- (void) showDesktopInspectorForDesktop: (VTDesktop*) desktop {
	// and activate ourselves
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
	// show the window we manage there
  [[mDesktopInspector window] center];
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
- (void) migrateOldPreferences
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	NSString *oldPlist = [[VTFileSystemExtensions preferencesFolder] stringByAppendingPathComponent:@"net.sourceforge.virtue.Virtue.plist"];
	NSString *newPlist = [[VTFileSystemExtensions preferencesFolder] stringByAppendingPathComponent:@"info.virtuedesktops.VirtueDesktops.plist"];
	
	if	(![fileManager fileExistsAtPath: newPlist] && [fileManager fileExistsAtPath: oldPlist])
	{
		[fileManager movePath: oldPlist toPath: newPlist handler: nil];
	}
	
	NSString *oldAppSupportFolder = [[VTFileSystemExtensions applicationSupportFolder] stringByAppendingPathComponent:@"Virtue"];
	NSString *newAppSupportFolder = [[VTFileSystemExtensions applicationSupportFolder] stringByAppendingPathComponent:@"VirtueDesktops"];
	
	if	(![fileManager fileExistsAtPath: newAppSupportFolder] && [fileManager fileExistsAtPath: oldAppSupportFolder])
	{
		[fileManager movePath: oldAppSupportFolder toPath: newAppSupportFolder handler: nil];
	}
  
  // Check for VTDesktops in standard prefs - if it doesn't exist, read in the data from the old virtuedata file (if that exists)
  if ([[[NSUserDefaults standardUserDefaults] objectForKey: @"VTDesktops"] count] == 0) {
    NSString *file = [[[VTFileSystemExtensions applicationSupportFolder] stringByAppendingPathComponent: @"Desktops.virtuedata"] retain];
    if ([fileManager fileExistsAtPath: file]) {
      NSArray *serialisedDesktops = [[[NSArray alloc] initWithContentsOfFile: file] autorelease];
      // write to preferences 
      [[NSUserDefaults standardUserDefaults] setObject: [serialisedDesktops copy] forKey: @"VTDesktops"]; 
      
      // and sync 
      [[NSUserDefaults standardUserDefaults] synchronize];
    }
    [file release];
  }
}

@end
