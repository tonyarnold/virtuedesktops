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

#import "VTDesktopProtector.h"
#import "VTDesktopController.h"
#import "VTNotifications.h" 
#import <Peony/Peony.h> 
#import <Zen/Zen.h> 


@interface VTDesktopProtectorView : NSView
@end

#pragma mark -
@implementation VTDesktopProtectorView

- (BOOL) isOpaque {
	return NO; 
}

- (void) drawRect: (NSRect) aRect {
	[[NSColor clearColor] set]; 
	[NSBezierPath fillRect: aRect]; 
}

@end

#pragma mark -
@interface VTDesktopProtector(Private) 
- (void) applyEnabled; 
- (void) createWindowForDesktop: (VTDesktop*) desktop; 
@end 

#pragma mark -
@implementation VTDesktopProtector

#pragma mark -
#pragma mark Lifetime 
- (id) init {
	if (self = [super init]) {
		mEnabled				= NO; 
		mDesktopProtectionViews = nil; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mDesktopProtectionViews); 
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 
- (void) setEnabled: (BOOL) flag {
	mEnabled = flag; 
	
	[self applyEnabled]; 
}

- (BOOL) isEnabled {
	return mEnabled; 
}

@end

#pragma mark -
@implementation VTDesktopProtector(Private) 

- (void) applyEnabled {
	if (mEnabled == NO) {
		// get rid of our windows
		ZEN_RELEASE(mDesktopProtectionViews); 
		// and resign observer status 
		[[NSNotificationCenter defaultCenter] removeObserver: self]; 
		
		return; 
	}
	
	mDesktopProtectionViews = [[NSMutableDictionary alloc] init]; 
	
	// walk through our desktops and create a view for each one
	NSEnumerator*	desktopIter		= [[[VTDesktopController sharedInstance] desktops] objectEnumerator]; 
	VTDesktop*		desktop			= nil; 
	
	while (desktop = [desktopIter nextObject]) {
		[self createWindowForDesktop: desktop]; 
	}
	
	// we are observing desktop changes, as we have to work around a nice feature of the apple window manager... 
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopWillChange:) name: kPnOnDesktopWillActivate object: nil]; 
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopDidChange:) name: kPnOnDesktopDidActivate object: nil]; 
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopCreated:) name: VTDesktopDidAddNotification object: nil]; 
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopDeleted:) name: VTDesktopDidRemoveNotification object: nil]; 
}

- (void) createWindowForDesktop: (VTDesktop*) desktop {
	NSWindow*		window			= nil; 
	NSView*			view			= nil; 
		
	// fetch the guid 
	NSString* desktopUUID = [desktop uuid]; 
	
	// and create a nice view 
	window = [[[NSWindow alloc] initWithContentRect: [[NSScreen mainScreen] visibleFrame] styleMask: NSBorderlessWindowMask backing: NSBackingStoreBuffered defer: NO] autorelease];
	
	// create view 
	view = [[[VTDesktopProtectorView alloc] initWithFrame: [window contentRectForFrameRect: [window frame]]] autorelease];    
	
	// bind the view to the window  
	[window setContentView: view];
	[window setBackgroundColor: [NSColor clearColor]]; 
	[window setLevel: NSStatusWindowLevel];
	[window setOpaque: NO];
	[window setIgnoresMouseEvents: NO];
	[window setAcceptsMouseMovedEvents: NO]; 
	[window setReleasedWhenClosed: NO]; 
	[window display]; 
	[window orderFront: self]; 
  
	// and make the window special to hide it 
	PNWindow* windowWrapper = [PNWindow windowWithNSWindow: window]; 
	[windowWrapper setSpecial: YES]; 
	[windowWrapper setSticky: YES];
	[windowWrapper setIgnoredByExpose: YES];
	[windowWrapper setDesktop: desktop]; 
	
	[mDesktopProtectionViews setObject: window forKey: desktopUUID];
	
	if ([desktop visible]) {
		[window orderOut: self]; 
	}
}

#pragma mark -
#pragma mark Notification Sink
- (void) onDesktopWillChange: (NSNotification*) notification {
	if (mEnabled) {
		NSString* oldDesktop = [[[VTDesktopController sharedInstance] activeDesktop] uuid]; 
		NSString* newDesktop = [[notification object] uuid]; 
		
		[[mDesktopProtectionViews objectForKey: newDesktop] orderOut: self]; 
		[[mDesktopProtectionViews objectForKey: oldDesktop] orderFront: self]; 
	}
}

- (void) onDesktopDidChange: (NSNotification*) notification {
}

- (void) onDesktopDeleted: (NSNotification*) notification {
	if (mEnabled) 
		[mDesktopProtectionViews removeObjectForKey: [[notification object] uuid]]; 
}

- (void) onDesktopCreated: (NSNotification*) notification {
	if (mEnabled)
		[self createWindowForDesktop: [notification object]]; 
}

@end 
