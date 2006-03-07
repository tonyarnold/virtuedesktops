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

#import <CoreGraphics/CGWindowLevel.h>
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
		// create the windows dictionary and update it immediately 
		mWindows							= [[NSMutableDictionary dictionary] retain]; 
		mDecorations					= [[NSMutableDictionary dictionary] retain]; 
		mDesktopWindowLevel		= kCGMinimumWindowLevel + 25;
		
		// we are observing desktop changes, as we have to work around a nice 
		// feature of the apple window manager... 
		[[NSNotificationCenter defaultCenter]
			addObserver: self selector: @selector(onDesktopWillChange:) name: kPnOnDesktopWillActivate object: nil]; 
		[[NSNotificationCenter defaultCenter]
			addObserver: self selector: @selector(onDesktopDidChange:) name: kPnOnDesktopDidActivate object: nil]; 

		return self; 
	}
	
	return nil; 
}

- (void) dealloc
{
	// get rid of windows 
	ZEN_RELEASE(mWindows); 
	ZEN_RELEASE(mDecorations); 
	
	// super...
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

- (void) hide {
}

- (void) show {
}
 
- (void) attachDecoration: (VTDesktopDecoration*) decoration {
	VTDesktop* desktop = [decoration desktop]; 
	
	// create the decoration window 
	NSWindow* window = [self createWindowForDesktop: desktop withDecoration: decoration];

	// add the window and the decoration to our list 
	[mWindows setObject: window forKey: [NSNumber numberWithInt: [desktop identifier]]]; 
	[mDecorations setObject: decoration forKey: [NSNumber numberWithInt: [desktop identifier]]]; 

	// initialize the decoration 
	// set the decorations control view 
	[decoration setControlView: [window contentView]]; 
}

- (void) detachDecorationForDesktop: (VTDesktop*) desktop {
	NSWindow* window = [mWindows objectForKey: [NSNumber numberWithInt: [desktop identifier]]]; 
	[window orderOut: self]; 
	
	// remove the window 
	[mWindows removeObjectForKey: [NSNumber numberWithInt: [desktop identifier]]]; 
	// remove the decoration 
	[mDecorations removeObjectForKey: [NSNumber numberWithInt: [desktop identifier]]]; 
}

#pragma mark -
#pragma mark Notification Sink 

- (void) onDesktopWillChange: (NSNotification*) notification {
	// get the desktop that will deactivate and set its decoration window to our
	// standard -5000 level. we have to set the window level higher, as a window
	// with level INT_MIN+25 (the one used to put the window behind icons) will
	// make the window sticky; seems to be a 'feature' of the apple window manager
	VTDesktop*	desktop			= [[VTDesktopController sharedInstance] activeDesktop]; 
	NSWindow*		window			= [mWindows objectForKey: [NSNumber numberWithInt: [desktop identifier]]];
	[window setLevel: kVTNonActiveWindowLevel];
}

- (void) onDesktopDidChange: (NSNotification*) notification {
	// see onDesktopWillChange: on why we are doing the stuff we are doing
	VTDesktop*	desktopToActivate		= [notification object]; 
	NSWindow*		window							= [mWindows objectForKey: [NSNumber numberWithInt: [desktopToActivate identifier]]];
	PNWindow* peonyWindow						= [PNWindow windowWithNSWindow: [mWindows objectForKey: [NSNumber numberWithInt: [desktopToActivate identifier]]]];
	[peonyWindow setLevel: (mDesktopWindowLevel + 1)];
	[peonyWindow setIgnoredByExpose: YES];
	[peonyWindow setSticky: NO];	
}

@end 

#pragma mark -
@implementation VTDesktopDecorationController (Private)

- (NSWindow*) createWindowForDesktop: (VTDesktop*) desktop withDecoration: (VTDesktopDecoration*) decoration
{
	NSScreen* mainScreen = [NSScreen mainScreen];
	
	// the window 
	NSWindow* window = [[[NSWindow alloc] initWithContentRect: [mainScreen frame] 
																															styleMask: NSBorderlessWindowMask 
																																backing: NSBackingStoreBuffered
																																	defer: NO] autorelease];

	if ([desktop visible])
		[window setLevel: (mDesktopWindowLevel + 1)];
	else
		[window setLevel: kVTNonActiveWindowLevel]; 
	
	[window setOpaque: NO];
	
	// create the view and set it to ignore mouse events 
	NSRect frameRect = [window contentRectForFrameRect: [window frame]];
	VTDesktopDecorationView* view = [[[VTDesktopDecorationView alloc] initWithFrame: frameRect withDecoration: decoration] autorelease];
	
	// attach view to window 
	[window setContentView: view];
	[window setBackgroundColor: [NSColor clearColor]]; 	
	[window setIgnoresMouseEvents: YES];
	[window setFrame: frameRect display: NO];
	[window setAlphaValue: 0.0f];
	[window display];
	[window orderWindow: NSWindowBelow relativeTo: 0];
	
	PNWindow* desktopNameWindow = [PNWindow windowWithNSWindow: window];
	
	// By making it special, it will not show up in the window lists of the available desktops 
	[desktopNameWindow setSpecial: YES]; 
	[desktopNameWindow setDesktop: desktop];
	[desktopNameWindow setIgnoredByExpose: YES];
	[desktopNameWindow setSticky: NO];
	[window setAlphaValue: 1.0];
	
	return window; 
}

@end
