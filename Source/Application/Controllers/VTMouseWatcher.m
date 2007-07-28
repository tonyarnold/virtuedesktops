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

#import "VTMouseWatcher.h"
#import "../CocoaExtensions/NSScreenOverallScreen.h" 
#import <Peony/Peony.h> 
#import <Zen/Zen.h> 
#import <Zen/ZNEdge.h> 
#import <Zen/ZNShading.h>
#import <Zen/ZNEffectWindow.h> 

#define kVTEdgeSpacer				50
#define kVTEdgeSize					8
#define kVTCornerEdgeSize		20
#define kVTEdgeTrackSize		3

#pragma mark -
@interface VTMouseWatcher (Creation)
- (NSWindow*) windowForEdge: (ZNEdge) edge; 
- (void) removeWindowForEdge: (ZNEdge) edge; 
- (NSRect) frameForEdge: (ZNEdge) edge; 
- (NSRect) trackingFrameForEdge: (ZNEdge) edge;
- (NSRect) shaderFrameForEdge: (ZNEdge) edge frame: (NSRect) frame startEdge: (ZNEdge*) startEdge; 
- (ZNEdge) edgeForTrackingRect: (NSTrackingRectTag) tag; 
@end 

#pragma mark -
@interface VTMouseWatcher (Enabling) 
- (void) enableEdge: (ZNEdge) edge enabled: (BOOL) flag; 
@end 

#pragma mark -
@interface VTMouseWatcherWindow : ZNEffectWindow 
@end 

@implementation VTMouseWatcherWindow 
@end 

#pragma mark -
@interface VTMouseWatcherView : NSView {
	BOOL						mMouseIn; 
	ZNAxialShading*	mShader; 
	NSObject<VTMouseWatcherProtocol>* mWatcher; 
	ZNEdge					mEdge; 
}

- (void) setShader: (ZNAxialShading*) shading; 
- (void) setEdge: (ZNEdge) edge; 
- (void) setMouseWatcher: (NSObject<VTMouseWatcherProtocol>*) watcher; 

@end

#pragma mark -
@implementation VTMouseWatcherView

- (id) init {
	if (self = [super init]) {
		mMouseIn	= NO; 
		mShader		= nil; 
		mWatcher	= nil; 
		mEdge			= ZNEdgeAny; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mShader); 
	ZEN_RELEASE(mWatcher); 
	[super dealloc]; 
}

- (BOOL) isOpaque {
	return NO; 
}

- (BOOL)acceptsFirstResponder { 
	return YES;
} 

- (void) drawRect: (NSRect) aRect {
	if (mMouseIn) {
		if ((mEdge == ZNEdgeTop) || (mEdge == ZNEdgeLeft) || (mEdge == ZNEdgeRight) || (mEdge == ZNEdgeBottom)) {
			[[NSGraphicsContext currentContext] saveGraphicsState]; 
			NSBezierPath* path = [NSBezierPath bezierPathWithRect: aRect]; 
			[path closePath]; 
			[mShader fill]; 
			[[NSGraphicsContext currentContext] restoreGraphicsState]; 

			return; 
		}
	}
	
	[[NSGraphicsContext currentContext] saveGraphicsState]; 
	[[NSColor clearColor] set]; 
	[NSBezierPath fillRect: aRect]; 
	[[NSGraphicsContext currentContext] restoreGraphicsState]; 
}

- (void) setMouseIn: (BOOL) flag {
	mMouseIn = flag; 
}

- (void) setShader: (ZNAxialShading*) shader {
	ZEN_ASSIGN(mShader, shader); 
}

- (void) setEdge: (ZNEdge) edge {
	mEdge = edge; 
}

- (void) setMouseWatcher: (NSObject<VTMouseWatcherProtocol>*) watcher {
	ZEN_ASSIGN(mWatcher, watcher); 
}

- (void) mouseDown: (NSEvent*) event {
	if (mWatcher == nil)
		return; 
	
	[mWatcher mouseDown: event]; 
}

@end

#pragma mark -
@implementation VTMouseWatcher

#pragma mark -
#pragma mark Instance 

- (id) init {
	if (self = [super init]) {
		// ivars 
		mWindows				= [[NSMutableDictionary alloc] init]; 
		mTrackingRects	= [[NSMutableDictionary alloc] init]; 
		mObservers			= [[NSMutableDictionary alloc] init]; 
		mCurrentEdge		= ZNEdgeAny;
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mWindows); 
	ZEN_RELEASE(mTrackingRects); 
	ZEN_RELEASE(mObservers);
	[super dealloc];
}

+ (id) sharedInstance {
	static VTMouseWatcher* ms_INSTANCE = nil; 
	
	if (ms_INSTANCE == nil)
		ms_INSTANCE = [[VTMouseWatcher alloc] init]; 
	
	return ms_INSTANCE; 
}

#pragma mark -
#pragma mark Operations 
- (void) addObserver: (NSObject<VTMouseWatcherProtocol>*) observer forEdge: (ZNEdge) edge {
	// make sure we have the requested window handy 
	// NSWindow* window = [self windowForEdge: edge]; 

	// enable the window 
	[self enableEdge: edge enabled: YES]; 
	
	// now add the passed observer to the list of observers for the passed edge 
	NSMutableArray* observersForEdge = [mObservers objectForKey: [NSNumber numberWithInt: edge]]; 
	if (observersForEdge == nil) {
		observersForEdge = [NSMutableArray array]; 
		[mObservers setObject: observersForEdge forKey: [NSNumber numberWithInt: edge]]; 
	}
	[observersForEdge addObject: observer];
}

- (void) removeObserver: (NSObject*) observer {
	[self removeObserver: observer forEdge: ZNEdgeAny]; 
}

- (void) removeObserver: (NSObject*) observer forEdge: (ZNEdge) edge {
	NSMutableArray*	observers = [mObservers objectForKey: [NSNumber numberWithInt: edge]]; 
	[observers removeObject: observer]; 
	if ([observers count] == 0) 
		[self enableEdge: edge enabled: NO]; 
}

#pragma mark -
#pragma mark NSResponder delegeate 
- (void) mouseEntered: (NSEvent*) event {
	// fetch the edge from the event 
	mCurrentEdge = [self edgeForTrackingRect: [event trackingNumber]];  
	NSNumber*		edgeObject = [NSNumber numberWithInt: mCurrentEdge]; 
	ZNEffectWindow*	edgeWindow	= [mWindows objectForKey: edgeObject]; 
	
	// start accepting mouse clicks 
	[edgeWindow setIgnoresMouseEvents: NO]; 
	// and tell the view to color itself 
	[[edgeWindow contentView] setMouseIn: YES];
	[[edgeWindow contentView] setNeedsDisplay: YES]; 
	
	// fade in window (we do that really fast for mouseEntered events) 
	[edgeWindow setFadingAnimationTime: 0.2f]; 
	[edgeWindow fadeIn];
	
	// loop over our observers and notify them 
	NSEnumerator* observerIter = [[mObservers objectForKey: edgeObject] objectEnumerator]; 
	NSObject<VTMouseWatcherProtocol>* observer = nil; 
	
	while (observer = [observerIter nextObject])
		[observer mouseEntered: event]; 
}

- (void) mouseExited: (NSEvent*) event {
	// fetch the edge from the event 
	ZNEdge		edge		= [self edgeForTrackingRect: [event trackingNumber]];  
	NSNumber*		edgeObject	= [NSNumber numberWithInt: edge]; 
	ZNEffectWindow*	edgeWindow	= [mWindows objectForKey: edgeObject]; 
	
	// start fading in the window 
	[edgeWindow setFadingAnimationTime: 0.7f]; 
	[edgeWindow fadeOut]; 
	// start ignoring mouse clicks 
	[edgeWindow setIgnoresMouseEvents: YES];
	[edgeWindow setAcceptsMouseMovedEvents: YES];
	
	// loop over our observers and notify them 
	NSEnumerator* observerIter = [[mObservers objectForKey: edgeObject] objectEnumerator]; 
	NSObject<VTMouseWatcherProtocol>* observer = nil; 
	
	while (observer = [observerIter nextObject])
		[observer mouseExited: event]; 	
	
	// reset the edge 
	mCurrentEdge = ZNEdgeAny; 
}

- (void) mouseDown: (NSEvent*) event {
	// fetch the edge from the event 
	NSNumber* edgeObject = [NSNumber numberWithInt: mCurrentEdge]; 
	
	// send event on to our observers 
	NSEnumerator* observerIter = [[mObservers objectForKey: edgeObject] objectEnumerator]; 
	NSObject<VTMouseWatcherProtocol>* observer = nil; 
	
	while (observer = [observerIter nextObject])
		[observer mouseDown: event]; 
}

#pragma mark -
#pragma mark ZNEffectWindow Delegate 

- (void) windowDidFadeIn: (NSNotification*) notification {
}

- (void) windowDidFadeOut: (NSNotification*) notification {
	NSWindow* window = [notification object]; 
	
	// tell the view that we no longer need it 
	[[window contentView] setMouseIn: NO];
	[[window contentView] setNeedsDisplay: YES]; 
}

@end

#pragma mark -
@implementation VTMouseWatcher (Creation) 

- (NSRect) frameForEdge: (ZNEdge) edge {
	NSRect screenRect = [[NSScreen mainScreen] frame]; 
	
	switch (edge) {
		// Edges 
		case ZNEdgeTop: 
			return NSMakeRect(0, screenRect.size.height-kVTEdgeSize, screenRect.size.width, kVTEdgeSize); 
		case ZNEdgeBottom: 
			return NSMakeRect(0, 0, screenRect.size.width, kVTEdgeSize); 
		case ZNEdgeLeft: 
			return NSMakeRect(0, 0, kVTEdgeSize, screenRect.size.height); 
		case ZNEdgeRight: 
			return NSMakeRect(screenRect.size.width-kVTEdgeSize, 0, kVTEdgeSize, screenRect.size.height); 
			// Corners 
		case ZNEdgeTopLeft: 
			return NSMakeRect(0, screenRect.size.height-kVTCornerEdgeSize, kVTCornerEdgeSize, kVTCornerEdgeSize); 
		case ZNEdgeTopRight: 
			return NSMakeRect(screenRect.size.width-kVTCornerEdgeSize, screenRect.size.height-kVTCornerEdgeSize, kVTCornerEdgeSize, kVTCornerEdgeSize); 
		case ZNEdgeBottomLeft: 
			return NSMakeRect(0, 0, kVTCornerEdgeSize, kVTCornerEdgeSize); 
		case ZNEdgeBottomRight: 
			return NSMakeRect(screenRect.size.width-kVTCornerEdgeSize, 0, kVTCornerEdgeSize, kVTCornerEdgeSize); 
	}; 
	
	return NSZeroRect; 
}

- (NSRect) trackingFrameForEdge: (ZNEdge) edge {
	NSRect screenRect = [[NSScreen mainScreen] frame]; 
	
	switch (edge) {
		// Edges 
		case ZNEdgeTop: 
			return NSMakeRect(kVTEdgeSpacer, kVTEdgeSize-kVTEdgeTrackSize, screenRect.size.width-kVTEdgeSpacer*2, kVTEdgeTrackSize); 
		case ZNEdgeBottom: 
			return NSMakeRect(kVTEdgeSpacer, 0, screenRect.size.width-kVTEdgeSpacer*2, kVTEdgeTrackSize); 
		case ZNEdgeLeft: 
			return NSMakeRect(0, kVTEdgeSpacer, kVTEdgeTrackSize, screenRect.size.height-kVTEdgeSpacer*2); 
		case ZNEdgeRight: 
			return NSMakeRect(kVTEdgeSize-kVTEdgeTrackSize, kVTEdgeSpacer, kVTEdgeTrackSize, screenRect.size.height-kVTEdgeSpacer*2); 
			// Corners
		case ZNEdgeTopLeft: 
			return NSMakeRect(0, kVTCornerEdgeSize-kVTEdgeTrackSize, kVTEdgeTrackSize, kVTEdgeTrackSize); 
		case ZNEdgeTopRight: 
			return NSMakeRect(kVTCornerEdgeSize-kVTEdgeTrackSize, kVTCornerEdgeSize-kVTEdgeTrackSize, kVTEdgeTrackSize, kVTEdgeTrackSize); 
		case ZNEdgeBottomLeft: 
			return NSMakeRect(0, 0, kVTEdgeTrackSize, kVTEdgeTrackSize); 
		case ZNEdgeBottomRight: 
			return NSMakeRect(kVTCornerEdgeSize-kVTEdgeTrackSize, 0, kVTEdgeTrackSize, kVTEdgeTrackSize); 
	}; 	
	
	return NSZeroRect; 
}

- (NSRect) shaderFrameForEdge: (ZNEdge) edge frame: (NSRect) frame startEdge: (ZNEdge*) startEdge {
	switch (edge) {
		case ZNEdgeTop: 
			*startEdge = ZNEdgeTop; 
			return NSMakeRect(0, 0, frame.size.width, kVTEdgeSize);
		case ZNEdgeBottom:
			*startEdge = ZNEdgeBottom; 
			return NSMakeRect(0, 0, frame.size.width, kVTEdgeSize); 
		case ZNEdgeLeft: 
			*startEdge = ZNEdgeLeft; 
			return NSMakeRect(0, 0, kVTEdgeSize, frame.size.height); 
		case ZNEdgeRight: 
			*startEdge = ZNEdgeRight; 
			return NSMakeRect(0, 0, kVTEdgeSize, frame.size.height); 
		case ZNEdgeTopLeft: 
			*startEdge = ZNEdgeTopLeft; 
			return NSMakeRect(0, 0, kVTCornerEdgeSize, kVTCornerEdgeSize); 
		case ZNEdgeTopRight: 
			*startEdge = ZNEdgeTopRight; 
			return NSMakeRect(0, 0, kVTCornerEdgeSize, kVTCornerEdgeSize); 
		case ZNEdgeBottomLeft: 
			*startEdge = ZNEdgeBottomLeft;
			return NSMakeRect(0, 0, kVTCornerEdgeSize, kVTCornerEdgeSize); 
		case ZNEdgeBottomRight: 
			*startEdge = ZNEdgeBottomRight; 
			return NSMakeRect(0, 0, kVTCornerEdgeSize, kVTCornerEdgeSize); 
	}
	
	return NSZeroRect; 
}

- (NSWindow*) windowForEdge: (ZNEdge) edge {
	ZNEffectWindow* window = nil; 
	
	// first, check if we already have the window handy and just return it in this case 
	window = [mWindows objectForKey: [NSNumber numberWithInt: edge]];
	
	NSRect frame = [self frameForEdge: edge]; 
    
  if (window != nil) {
    [window setFrame: frame display: NO];
    return window;
  }

	// otherwise we will have to create it... 
	window = [[ZNEffectWindow alloc] initWithContentRect: frame
																						 styleMask: NSBorderlessWindowMask
																							 backing: NSBackingStoreBuffered
																								 defer: NO];
	
	// create view 
	VTMouseWatcherView* view = [[VTMouseWatcherView alloc] initWithFrame: [window contentRectForFrameRect: [window frame]]];    
	// create the views content path 
	ZNEdge		rectEdge; 
	NSRect		shaderFrame = [self shaderFrameForEdge: edge frame: frame startEdge: &rectEdge];  
	
	NSColor* startColor = [[NSColor selectedControlColor] colorUsingColorSpaceName: NSCalibratedRGBColorSpace]; 
	NSColor* endColor	= [startColor colorWithAlphaComponent: 0.2]; 
	
	ZNAxialShading* shader = [ZNAxialShading shadingInRect: shaderFrame startColor: startColor endColor: endColor startEdge: rectEdge];  
	[view setShader: shader];
	[view setMouseWatcher: self]; 
	[view setEdge: edge]; 
	
	// bind the view to the window  
	[window setContentView: view];
	[window setBackgroundColor: [NSColor clearColor]];
	[window setAlphaValue: 0.0f]; 
	[window setLevel: NSStatusWindowLevel + 1];	
	[window setOpaque: NO]; 
	[window setAcceptsMouseMovedEvents: YES];
	[window setIgnoresMouseEvents: YES];
	[window setInitialFirstResponder: view]; 
	[window setReleasedWhenClosed: YES];
	
	[window setTitle: [NSString stringWithFormat: @"MouseWatcher for edge %i", edge]];
	
	// set ourselves as the delegate 
	[window setDelegate: self];
	[window orderFront: self]; 
	
	// and make the window special to hide it 
	PNWindow* windowWrapper = [PNWindow windowWithNSWindow: window]; 
	[windowWrapper setSticky: YES];
	[windowWrapper setSpecial: YES];
	[windowWrapper setIgnoredByExpose: YES];
	
	// now take care of adding the tracking rectangle 
	NSRect						trackingRectFrame		= [self trackingFrameForEdge: edge];
	NSTrackingRectTag	trackingRect				= [view addTrackingRect: trackingRectFrame owner: self userData: (void*)(&edge) assumeInside: NO]; 
	// and add it
	[mTrackingRects setObject: [NSNumber numberWithInt: trackingRect] forKey: [NSNumber numberWithInt: edge]]; 
	
	// add the window to our dictionary and return 
	[mWindows setObject: window forKey: [NSNumber numberWithInt: edge]]; 
	
	// no need for window and view any more 
	[view release]; 
	[window autorelease]; 
	
	return window; 
}

- (ZNEdge) edgeForTrackingRect: (NSTrackingRectTag) tag {
	NSEnumerator*	edgeObjectIter	= [mTrackingRects keyEnumerator]; 
	NSNumber*		edgeObject		= nil; 
	NSNumber*		tagObject		= [NSNumber numberWithInt: tag]; 
	
	while (edgeObject = [edgeObjectIter nextObject]) {
		if ([[mTrackingRects objectForKey: edgeObject] isEqual: tagObject]) 
			return [edgeObject intValue];
	}
		
	return ZNEdgeAny; 
}

- (void) removeWindowForEdge: (ZNEdge) edge {
	NSWindow* window = [mWindows objectForKey: [NSNumber numberWithInt: edge]]; 
	
	if (window == nil)
		return; 
	
	// remove the rtacking rectangle 
	[[window contentView] removeTrackingRect: 
		[[mTrackingRects objectForKey: [NSNumber numberWithInt: edge]] intValue]];  
	
	// order out the window 
	[window close]; 
	
	// remove from our dictionaries 
	[mTrackingRects removeObjectForKey: [NSNumber numberWithInt: edge]]; 
	[mWindows removeObjectForKey: [NSNumber numberWithInt: edge]]; 
}

@end 

#pragma mark -
@implementation VTMouseWatcher (Enabling) 

- (void) enableEdge: (ZNEdge) edge enabled: (BOOL) flag {
	NSWindow* window = [mWindows objectForKey: [NSNumber numberWithInt: edge]]; 
	// toggle accepting of mouse moved events for this window 
	[window setAcceptsMouseMovedEvents: flag];
	
	if (flag) 
		[window orderFront: self]; 
	else
		[window orderOut: self];
}

@end 
