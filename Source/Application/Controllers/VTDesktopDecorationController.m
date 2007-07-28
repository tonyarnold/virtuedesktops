/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import <ApplicationServices/ApplicationServices.h>
#import "VTDesktopDecorationController.h"
#import "VTDesktopDecorationView.h" 
#import "VTDesktopController.h" 
#import "VTPreferences.h" 
#import "NSUserDefaultsColor.h" 
#import <Peony/Peony.h> 
#import <Zen/Zen.h>
#import <Zen/ZNEffectWindow.h>

#define kVTNonActiveWindowLevel		(-5000) 

#pragma mark -
@interface VTDesktopDecorationController (Private)
- (NSWindow*) createWindowForDesktop: (VTDesktop*) desktop withDecoration: (VTDesktopDecoration*) decoration; 
@end 

#pragma mark -
@implementation VTDesktopDecorationController

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		// Create the window dictionary and update it immediately 
		mWindows							= [[NSMutableDictionary dictionary] retain];
		mDecorations					= [[NSMutableDictionary dictionary] retain];
		mDesktopWindowLevel		= kCGMinimumWindowLevel + 25;
		
		// We are observing desktop changes, see 'onDesktopWillChange' for more information on why 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopWillChange:) name: kPnOnDesktopWillActivate object: nil];
    
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopDidChange:) name: kPnOnDesktopDidActivate object: nil];

		return self;
	}
	
	return nil;
}

- (void) dealloc
{
	ZEN_RELEASE(mWindows);
	ZEN_RELEASE(mDecorations);
	[super dealloc];
}

+ (VTDesktopDecorationController*) sharedInstance {
	static VTDesktopDecorationController* ms_INSTANCE = nil; 
	
	if (ms_INSTANCE == nil)
		ms_INSTANCE = [[VTDesktopDecorationController alloc] init]; 
	
	return ms_INSTANCE; 
}

#pragma mark -
#pragma mark Attributes 

- (NSArray*) decorations {
	return [mDecorations allValues]; 
}

- (VTDesktopDecoration*) decorationForDesktop: (VTDesktop*) desktop {
	return [mDecorations objectForKey: [NSNumber numberWithInt: [desktop identifier]]]; 
}

#pragma mark -
- (int) desktopWindowLevel {
	return mDesktopWindowLevel; 
}

- (void) setDesktopWindowLevel: (int) level {
	mDesktopWindowLevel = level; 
	
	NSWindow* activeDesktopWindow = [mWindows objectForKey: [NSNumber numberWithInt: [[[VTDesktopController sharedInstance] activeDesktop] identifier]]]; 
	[activeDesktopWindow setLevel: (mDesktopWindowLevel + 1)];
}

#pragma mark -
#pragma mark Operations 

- (void) hide {}

- (void) show {}
 
- (void) attachDecoration: (VTDesktopDecoration*) decoration {
	VTDesktop* desktop = [decoration desktop]; 
  NSWindow* window = [self createWindowForDesktop: desktop withDecoration: decoration];
	[mWindows setObject: window forKey: [NSNumber numberWithInt: [desktop identifier]]]; 
	[mDecorations setObject: decoration forKey: [NSNumber numberWithInt: [desktop identifier]]]; 
	[decoration setControlView: [window contentView]]; 
}

- (void) detachDecorationForDesktop: (VTDesktop*) desktop {
	NSWindow* window = [mWindows objectForKey: [NSNumber numberWithInt: [desktop identifier]]]; 
  [window orderOut: self]; 
	[mWindows removeObjectForKey: [NSNumber numberWithInt: [desktop identifier]]]; 
	[mDecorations removeObjectForKey: [NSNumber numberWithInt: [desktop identifier]]]; 
}

#pragma mark -
#pragma mark Notification Sink 

- (void) onDesktopWillChange: (NSNotification*) notification {
	// Get the desktop that will deactivate and set its decoration window to a more standard window level (in this case kVTNonActiveWindowLevel, or -5000). We need to set the window level higher, as windows with levels around kCGDesktopIconWindowLevel and lower will become the 'sticky', and appear on all desktops; this appears to be a 'feature' (nee 'bug') of the apple window manager -- rdar://4455434/ -- however, as Apple doesn't use the NSWorkspace switching for anything other than fast user switching (which will only ever have a single desktop picture per user), they see no reason to fix it. Seems fair, given that I seem to have managed a workaround ;)
  
  
	VTDesktop*	desktop			= [[VTDesktopController sharedInstance] activeDesktop]; 
	NSWindow*		window			= [mWindows objectForKey: [NSNumber numberWithInt: [desktop identifier]]];
	[window setLevel: kVTNonActiveWindowLevel];
}

- (void) onDesktopDidChange: (NSNotification*) notification {
	// See 'onDesktopWillChange' for an explanation of what is going on here
	VTDesktop*  desktopToActivate		= [notification object]; 
	NSWindow*		window							= [mWindows objectForKey: [NSNumber numberWithInt: [desktopToActivate identifier]]];
	PNWindow*   pnWindow             = [PNWindow windowWithNSWindow: [mWindows objectForKey: [NSNumber numberWithInt: [desktopToActivate identifier]]]];
  
	[window orderWindow: NSWindowBelow relativeTo: 0];
	[window setLevel: (kCGDesktopIconWindowLevel - 1)];
	
	[pnWindow setIgnoredByExpose: YES];
	[pnWindow setSticky: NO];
}

@end 

#pragma mark -
@implementation VTDesktopDecorationController (Private)

- (NSWindow*) createWindowForDesktop: (VTDesktop*) desktop withDecoration: (VTDesktopDecoration*) decoration
{
	NSScreen* mainScr = [NSScreen mainScreen];
	
	// Create a new window 
	NSWindow* window = [[[NSWindow alloc] initWithContentRect: [mainScr frame] 
                                                  styleMask: NSBorderlessWindowMask 
                                                    backing: NSBackingStoreBuffered
                                                      defer: NO] autorelease];

	if ([desktop visible])
		[window setLevel: (kCGDesktopIconWindowLevel - 1)];
	else
		[window setLevel: kVTNonActiveWindowLevel]; 
	
	[window setOpaque: NO];
	
	// Create the view and tell it to ignore any mouse events 
	NSRect frameRect = [window contentRectForFrameRect: [window frame]];
	VTDesktopDecorationView* view = [[[VTDesktopDecorationView alloc] initWithFrame: frameRect 
                                                                   withDecoration: decoration] autorelease];
	
	// Attach the view to our window 
	[window setContentView: view];
	[window setBackgroundColor: [NSColor clearColor]]; 	
	[window setIgnoresMouseEvents: YES];
	[window setFrame: frameRect display: NO];
	[window setAlphaValue: 0.0f];
	[window display];
	[window orderWindow: NSWindowBelow relativeTo: 0];
	
  // Now get a PeonyWindow reference to this window so we can do our magic with it
	PNWindow* pnWindow = [PNWindow windowWithNSWindow: window];
	
	// By making the PNWindow/NSWindow 'special', the window will not show up in the window lists of the available desktops, and thus not appear in the pager or desktop application window lists
	[pnWindow setSpecial: YES]; 
	[pnWindow setDesktop: desktop];
	[pnWindow setIgnoredByExpose: YES];
	[pnWindow setSticky: NO];
	[window setAlphaValue: 1.0f];
  [pnWindow release];
  
	return window; 
}

@end
