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

#import "VTMouseTrigger.h"
#import "VTMouseWatcher.h" 
#import "VTTriggerNotification.h" 
#import <Zen/Zen.h> 
#import <Carbon/Carbon.h> 

#define kVtCodingEdge				@"edge"
#define kVtCodingDelay			@"delay"
#define kVtCodingModifiers	@"modifiers"
#define kVtCodingClickCount	@"clickCount"

@implementation VTMouseTrigger

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		mModifiers		= 0; 
		mClickCount		= 0; 
		mDelay        = 0; 
		mEdge         = ZNEdgeAny;
		mTimer        = nil; 
    [[NSNotificationCenter defaultCenter] addObserver: self 
                                             selector: @selector(resetOnScreenChanged:) 
                                                 name: NSApplicationDidChangeScreenParametersNotification
                                               object: nil];
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver: self];
	[super dealloc]; 
}

#pragma mark -
#pragma mark Coding
- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	[super encodeToDictionary: dictionary]; 
	
	[dictionary setObject: [NSNumber numberWithInt: mEdge] forKey: kVtCodingEdge]; 
	[dictionary setObject: [NSNumber numberWithFloat: mDelay] forKey: kVtCodingDelay]; 
	[dictionary setObject: [NSNumber numberWithInt: mModifiers] forKey: kVtCodingModifiers]; 
	[dictionary setObject: [NSNumber numberWithUnsignedInt: mClickCount] forKey: kVtCodingClickCount]; 
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	if (self = [super decodeFromDictionary: dictionary]) {
		mEdge		= [[dictionary objectForKey: kVtCodingEdge] intValue]; 
		mDelay		= [[dictionary objectForKey: kVtCodingDelay] floatValue]; 
		mModifiers	= [[dictionary objectForKey: kVtCodingModifiers] intValue]; 
		mClickCount	= [[dictionary objectForKey: kVtCodingClickCount] unsignedIntValue]; 
		
		return self; 
	}
	
	return nil; 
}
	
#pragma mark -
#pragma mark Attributes 
- (int) modifiers {
	return mModifiers; 
}

- (void) setModifiers: (int) modifiers {
	[self willChangeValueForKey: @"stringValue"]; 

	mModifiers = modifiers; 
	ZEN_RELEASE(mStringValue); 
	
	[self didChangeValueForKey: @"stringValue"]; 
}

- (unsigned int) clickCount {
	return mClickCount; 
}

- (void) setClickCount: (unsigned int) clicks {
	[self willChangeValueForKey: @"stringValue"]; 
	
	mClickCount = clicks; 
	ZEN_RELEASE(mStringValue); 
	
	[self didChangeValueForKey: @"stringValue"]; 
}

- (float) delay {
	return mDelay; 
}

- (void) setDelay: (float) delay {
	mDelay = delay; 
}

- (void) setEdge: (ZNEdge) edge {
	if (edge == mEdge)
		return; 
	
	[self willChangeValueForKey: @"stringValue"]; 
	
	BOOL wasRegistered = (mEdge == ZNEdgeAny) ? YES : mRegistered; 
	
	[self unregisterTrigger];
	mEdge = edge;
	
	if ((wasRegistered) && (mEdge != ZNEdgeAny))
		[self registerTrigger]; 
	
	// invalidate string value 
	ZEN_RELEASE(mStringValue); 
	[self didChangeValueForKey: @"stringValue"]; 
}

- (ZNEdge) edge {
	return mEdge; 
}

#pragma mark -
- (NSString*) stringValue {
	if (mStringValue != nil) 
		return mStringValue; 

	unichar unicodeChar = 0; 
	
	// choose arrow character 
	switch (mEdge) {
		case ZNEdgeAny: 
			unicodeChar = 0; 
			break; 
		case ZNEdgeLeft: 
			unicodeChar = 0x25C0; 
			break; 
		case ZNEdgeTop: 
			unicodeChar = 0x25B2; 
			break; 
		case ZNEdgeRight: 
			unicodeChar = 0x25BA; 
			break; 
		case ZNEdgeBottom: 
			unicodeChar = 0x25BC; 
			break; 
		case ZNEdgeTopLeft: 
			unicodeChar = 0x25E4; 
			break; 
		case ZNEdgeTopRight: 
			unicodeChar = 0x25E5; 
			break; 
		case ZNEdgeBottomLeft: 
			unicodeChar = 0x25E3; 
			break; 
		case ZNEdgeBottomRight: 
			unicodeChar = 0x25E2; 
	}
	
	NSMutableString* returnValue = [[[NSMutableString alloc] init] autorelease]; 
	[returnValue appendString: [NSString stringWithModifiers: mModifiers]]; 
	if (unicodeChar != 0)
		[returnValue appendString: [NSString stringWithFormat: @" %@", [NSString stringWithCharacters: &unicodeChar length: 1]]]; 
	if (mClickCount > 0) 
		[returnValue appendString: [NSString stringWithFormat: @" x%i", mClickCount]]; 
	
	ZEN_ASSIGN(mStringValue, returnValue); 
	return mStringValue; 
}

#pragma mark -
#pragma mark Operations 

- (void) registerTrigger {
	// refuse if we are registered already 
	if (mRegistered)
		return; 
	// check if we have all the necessary information handy 
	if ([self edge] == ZNEdgeAny)
		return; 
	
	// we attach to the mouse watcher as an observer for our edge
	[[VTMouseWatcher sharedInstance] addObserver: self forEdge: [self edge]]; 
	mRegistered = YES; 
}

- (void) unregisterTrigger {
	if (mRegistered == NO)
		return; 
	
	[[VTMouseWatcher sharedInstance] removeObserver: self forEdge: mEdge]; 
	mRegistered = NO; 
}

- (BOOL) canRegister {
	return (mEdge != ZNEdgeAny); 
}

- (void) resetOnScreenChanged: (id) sender {
  [self unregisterTrigger];
  [self registerTrigger];
}

#pragma mark -
- (void) notify {
	// kill the timer if it is there 
	ZEN_RELEASE(mTimer); 
	// and have our notification object fire away 
	[mNotification requestNotification]; 
}

#pragma mark -
#pragma mark VTMouseWatcherProtocol 
- (void) mouseEntered: (NSEvent*) event {
	// ignored if click count is necessary
	if (mClickCount != 0)
		return; 
	
	// check for the modifier key 
	if (mModifiers != 0) {
		// get actually pressed modifier 
		int pressedModifier = GetCurrentKeyModifiers(); 
		
		// and check against needed modifier 
		if ((mModifiers & NSShiftKeyMask) && (!(pressedModifier & (1 << shiftKeyBit))))
			return; 
		if ((mModifiers & NSCommandKeyMask) && (!(pressedModifier & (1 << cmdKeyBit))))
			return; 
		if ((mModifiers & NSAlternateKeyMask) && (!(pressedModifier & (1 << optionKeyBit))))
			return; 
		if ((mModifiers & NSControlKeyMask) && (!(pressedModifier & (1 << controlKeyBit))))
			return; 
	}
	
	// check for the delay; if it is 0, we will immediately fire our notification, 
	// otherwise start a timer that fires when it expires unless we get an exit 
	// notification first 
	if (mDelay == 0) {
		[self notify];
		return; 
	}
	
	// ok, start our timer... 
	mTimer = [[NSTimer scheduledTimerWithTimeInterval: mDelay 
											  target: self 
											selector: @selector(notify)
											userInfo: nil
											 repeats: NO] retain]; 
}

- (void) mouseExited: (NSEvent*) event {
	// kill the timer if it is there 
	if (mTimer) {
		[mTimer invalidate]; 
		ZEN_RELEASE(mTimer); 
	}
}

- (void) mouseDown: (NSEvent*) event {
	// check if we need to consider this event 
	if ([event clickCount] != mClickCount)
		return; 
	
	// check for the modifier key 
	if (mModifiers != 0) {
		// get actually pressed modifier 
		int pressedModifier = GetCurrentKeyModifiers(); 
		
		// and check against needed modifier 
		if ((mModifiers & NSShiftKeyMask) && (!(pressedModifier & (1 << shiftKeyBit))))
			return; 
		if ((mModifiers & NSCommandKeyMask) && (!(pressedModifier & (1 << cmdKeyBit))))
			return; 
		if ((mModifiers & NSAlternateKeyMask) && (!(pressedModifier & (1 << optionKeyBit))))
			return; 
		if ((mModifiers & NSControlKeyMask) && (!(pressedModifier & (1 << controlKeyBit))))
			return; 
	}	
	
	[self notify]; 
}

@end
