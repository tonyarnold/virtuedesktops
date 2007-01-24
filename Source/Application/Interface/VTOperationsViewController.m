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

#import "VTOperationsViewController.h"
#import "VTDesktopController.h"
#import "VTLayoutController.h"
#import "VTPreferences.h"
#import "NSUserDefaultsColor.h"
#import "NSUserDefaultsControllerKeyFactory.h"
#import "VTApplicationController.h"
#import <Zen/Zen.h> 

#pragma mark -
@interface VTOperationsViewController (Private) 
- (void) endSheet; 
- (void) setRepresentedWindow: (PNWindow*) window; 
- (void) setUpInterface; 
@end; 

#pragma mark -
@implementation VTOperationsViewController

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super initWithWindowNibName: @"Operations"]) {
		// init attributes 
		mRepresentedWindow		= nil; 
		mRepresentedApplication	= nil; 
		// our window used for tinting the target window 
		mOverlayWindow			= [[NSWindow alloc] 
									initWithContentRect: NSZeroRect 
											  styleMask: NSBorderlessWindowMask 
												backing: NSBackingStoreBuffered
												  defer: NO];
		
		// set up the window as we need it 
		[mOverlayWindow setLevel: NSFloatingWindowLevel];
		[mOverlayWindow setOpaque: NO];
		[mOverlayWindow setIgnoresMouseEvents: NO];
		[mOverlayWindow setDelegate: self]; 
		[mOverlayWindow setAlphaValue: 0.5]; 
		[mOverlayWindow setReleasedWhenClosed: NO]; 
		
		// update the window color 
		if ([[NSUserDefaults standardUserDefaults] boolForKey: VTOperationsTint] == NO) {
			[mOverlayWindow setBackgroundColor: [NSColor clearColor]]; 
		} else {
			[mOverlayWindow setBackgroundColor: [[NSUserDefaults standardUserDefaults] colorForKey: VTOperationsTintColor]];  
		}
		
		// mark overlay window as special so it dows not appear in our window 
		// list for desktops 
		[[PNWindow windowWithNSWindow: mOverlayWindow] setSpecial: YES]; 
		
		// register observers 
		[[NSUserDefaultsController sharedUserDefaultsController]
			addObserver: self 
			 forKeyPath: [NSUserDefaultsController pathForKey: VTOperationsTint]
				options: NSKeyValueObservingOptionNew
				context: NULL]; 
		[[NSUserDefaultsController sharedUserDefaultsController]
			addObserver: self 
			 forKeyPath: [NSUserDefaultsController pathForKey: VTOperationsTintColor]
				options: NSKeyValueObservingOptionNew
				context: NULL]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mOverlayWindow); 
	ZEN_RELEASE(mRepresentedApplication); 
	ZEN_RELEASE(mRepresentedWrapper); 
	ZEN_RELEASE(mRepresentedWindow); 
	
	// get rid of observer status 
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver: self forKeyPath: [NSUserDefaultsController pathForKey: VTOperationsTintColor]]; 
	[[NSUserDefaultsController sharedUserDefaultsController] removeObserver: self forKeyPath: [NSUserDefaultsController pathForKey: VTOperationsTint]]; 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 

- (PNWindow*) representedWindow {
	return mRepresentedWindow; 
}

- (PNApplication*) representedApplication {
	return mRepresentedApplication; 
}

- (VTApplicationWrapper*) representedWrapper {
	return mRepresentedWrapper; 
}	

- (VTDesktopController*) desktopController {
	return [VTDesktopController sharedInstance]; 
}

#pragma mark -
#pragma mark Actions 

- (IBAction) hideSheet: (id) sender {
	[self endSheet]; 
}

#pragma mark -
- (IBAction) setDesktopForWindow: (id) sender {
	[self endSheet];
	/* Move the currently represented window to the selected desktop */
	[mRepresentedWindow setDesktop: [sender representedObject]]; 
	
	/* move the represented window to the front */
	[[sender representedObject] orderWindowFront: mRepresentedWindow];	
	
	/* active selected desktop */
	[[VTDesktopController sharedInstance] activateDesktop: [sender representedObject]];
}

- (IBAction) setDesktopForApplication: (id) sender {
	[self endSheet]; 
	
	/* Move the application represented by this window to the selected desktop */
	[mRepresentedApplication setDesktop: [sender representedObject]]; 
}

#pragma mark -
#pragma mark Operations 

- (void) display {
	// fetch the mouse location 
	NSPoint mouseLocation   = [NSEvent mouseLocation]; 
	NSSize  screenSize		= [[NSScreen mainScreen] frame].size;
	
	mouseLocation.y = screenSize.height - mouseLocation.y;
	
	// try to find a matching window on the current desktop 
	VTDesktop*	activeDesktop		= [[VTDesktopController sharedInstance] activeDesktop]; 
	PNWindow*	windowUnderMouse	= [activeDesktop windowContainingPoint: mouseLocation]; 
	
	// if there is no window there, we are not doing anything 
	if (windowUnderMouse == nil)
		return; 
	
	// set our represented window to the window under the mouse pointer 
	[self setRepresentedWindow: windowUnderMouse];
	
	// move the represented window to the front 
	[activeDesktop orderWindowFront: mRepresentedWindow]; 
	
	// figure out the size of our overlay window matching the window under the mouse 
	NSRect windowRect = [mRepresentedWindow screenRectangle]; 
	windowRect.origin.y = screenSize.height - windowRect.origin.y;
	windowRect.origin.y -= windowRect.size.height;
	
	// set up the overlay window and show it  	
	[mOverlayWindow setFrame: windowRect display: NO]; 
	[mOverlayWindow orderFrontRegardless];
	
	// set up the interface 
	[self setUpInterface]; 
	
	// now we have set up everything ready to slide in the panel 
	[[NSApplication sharedApplication] beginSheet: [self window] modalForWindow: mOverlayWindow modalDelegate: self didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:) contextInfo: NULL]; 
	// and give the panel key focus 
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES]; 
	[[self window] makeKeyWindow]; 
}

#pragma mark -
#pragma mark NSWindowController delegates 

- (void) windowDidLoad {
	// setup controllers 
	[mController setContent: self]; 
	// panel setup 
	[[self window] setDelegate: self];	
}

#pragma mark -
#pragma mark NSWindow Delegates 

- (void) windowDidResignKey: (NSNotification*) notification {
	[self endSheet]; 
}

#pragma mark -
#pragma mark Modal Delegate

- (void) sheetDidEnd: (NSWindow*) sheet returnCode: (int) returnCode contextInfo: (void*) contextInfo {
}

#pragma mark -
#pragma mark KVO Sink 

- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) anObject change: (NSDictionary*) theChange context: (void*) theContext {
	if ([keyPath isEqualToString: [NSUserDefaultsController pathForKey: VTOperationsTint]]) {
		// update the window color 
		if ([[NSUserDefaults standardUserDefaults] boolForKey: VTOperationsTint] == NO)
			[mOverlayWindow setBackgroundColor: [NSColor clearColor]]; 
		else
			[mOverlayWindow setBackgroundColor: [[NSUserDefaults standardUserDefaults] colorForKey: VTOperationsTintColor]];  
		
		[mOverlayWindow display]; 
	}
	else if ([keyPath isEqualToString: [NSUserDefaultsController pathForKey: VTOperationsTintColor]]) {
		// update the window color 
		if ([[NSUserDefaults standardUserDefaults] boolForKey: VTOperationsTint] == NO)
			[mOverlayWindow setBackgroundColor: [NSColor clearColor]]; 
		else
			[mOverlayWindow setBackgroundColor: [[NSUserDefaults standardUserDefaults] colorForKey: VTOperationsTintColor]];  
		
		[mOverlayWindow display]; 
	}
}

@end

#pragma mark -
@implementation VTOperationsViewController (Private) 

- (void) endSheet {
	[self close]; 
	// send end sheet message to application 
	[[NSApplication sharedApplication] endSheet: [self window] returnCode: NSOKButton]; 
	// hide the overlay window right now
	[mOverlayWindow orderOut: self]; 
}

- (void) setRepresentedWindow: (PNWindow*) window
{
	[self willChangeValueForKey: @"representedApplication"]; 
	[self willChangeValueForKey: @"representedWrapper"]; 
	
	// the window 
	ZEN_ASSIGN(mRepresentedWindow, window); 
	ZEN_RELEASE(mRepresentedApplication); 
	ZEN_RELEASE(mRepresentedWrapper); 
		
	if (mRepresentedWindow) {
		// find us the application 
		NSEnumerator*	applicationIter = [[[[VTDesktopController sharedInstance] activeDesktop] applications] objectEnumerator]; 
		PNApplication*	application		= nil; 
	
		while (application = [applicationIter nextObject]) {
			if ([application pid] == [mRepresentedWindow ownerPid]) 
				break; 
		}	
		
		if (application) {
			// the application 
			mRepresentedApplication = [application retain]; 
			mRepresentedWrapper		= [[[VTApplicationController sharedInstance] applicationForPath: [application path]] retain]; 
		}
	}
	
	[self didChangeValueForKey: @"representedWrapper"]; 
	[self didChangeValueForKey: @"representedApplication"]; 
}

- (void) setUpInterface {
	// popup button setup 
	NSArray*	desktops		= [[[VTLayoutController sharedInstance] activeLayout] orderedDesktops]; 
	int			menuItemCount	= [desktops count];
	int			menuItemIndex	= 0; 

	[mApplicationDesktopButton removeAllItems]; 
	[mApplicationDesktopButton setAutoenablesItems: NO]; 
	[mWindowDesktopButton removeAllItems]; 
	[mWindowDesktopButton setAutoenablesItems: NO]; 

	for (menuItemIndex = 0; menuItemIndex < menuItemCount; menuItemIndex++) {
		VTDesktop*  desktop		= [desktops objectAtIndex: menuItemIndex]; 
		
		[mApplicationDesktopButton addItemWithTitle: [desktop name]]; 
		[mWindowDesktopButton addItemWithTitle: [desktop name]]; 
		
		NSMenuItem* application = [mApplicationDesktopButton itemWithTitle: [desktop name]]; 
		NSMenuItem* window		= [mWindowDesktopButton itemWithTitle: [desktop name]]; 
		
		[application setTarget: self]; 
		[application setAction: @selector(setDesktopForApplication:)]; 
		[application setKeyEquivalentModifierMask: NSCommandKeyMask]; 
		[application setKeyEquivalent: [NSString stringWithFormat: @"%i", menuItemIndex + 1]]; 
		[application setEnabled: YES]; 
		[application setRepresentedObject: desktop]; 

		[window setKeyEquivalentModifierMask: NSCommandKeyMask | NSAlternateKeyMask]; 
		[window setKeyEquivalent: [NSString stringWithFormat: @"%i", menuItemIndex + 1]]; 
		[window setTarget: self]; 
		[window setAction: @selector(setDesktopForWindow:)]; 
		[window setEnabled: YES]; 
		[window setRepresentedObject: desktop]; 
	}
	
	int selectedItemIndex = [desktops indexOfObject: [[VTDesktopController sharedInstance] activeDesktop]]; 
	[mApplicationDesktopButton selectItemAtIndex: selectedItemIndex]; 
	[mWindowDesktopButton selectItemAtIndex: selectedItemIndex]; 
}
@end 