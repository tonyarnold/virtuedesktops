//
//  ZNEffectWindow.m
//  Zen framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import "ZNEffectWindow.h"

#pragma mark -
NSString* ZNWindowDidFadeInNotification		= @"ZNWindowDidFadeInNotification"; 
NSString* ZNWindowDidFadeOutNotification	= @"ZNWindowDidFadeOutNotification"; 

#define kZNTimerInterval	(1.0 / 70.0)
#define kZNFadeIncrement	0.05	

#pragma mark -
@interface ZNEffectWindow(Animation) 
- (void) _onFadeInTick: (NSTimer*) timer; 
- (void) _onFadeOutTick: (NSTimer*) timer; 
- (void) _stopTimer; 
@end 

#pragma mark -
@interface ZNEffectWindow(NotificationHelper)
- (void) _windowDidFadeIn; 
- (void) _windowDidFadeOut; 
@end 

#pragma mark -
@implementation ZNEffectWindow

#pragma mark -
#pragma mark Lifetime 
- (id) init {
	if (self = [super init]) {
		_fadingTimer	= nil; 
		_fadingDuration	= 0.5f; 
		
		return self; 
	}
	
	return nil; 
}

#pragma mark -
#pragma mark Attributes 
- (void) setFadingAnimationTime: (float) seconds {
	_fadingDuration = seconds; 
}

- (float) fadingAnimationTime {
	return _fadingDuration; 
}

#pragma mark -
#pragma mark Visibility
- (void) fadeOut {
	[self _stopTimer];
	
	if (_fadingDuration == 0.0) {
		[self setAlphaValue: 0.0f];
		[NSTimer scheduledTimerWithTimeInterval: 0.0f target: self selector: @selector(_windowDidFadeOut) userInfo: nil repeats: NO]; 
		
		return; 
	}
	
	float timerInterval = _fadingDuration / (1.0 / kZNFadeIncrement); 

	// start fading 
	_fadingTimer = [[NSTimer scheduledTimerWithTimeInterval: timerInterval target: self selector: @selector(_onFadeOutTick:) userInfo: nil repeats: YES] retain];
}

- (void) fadeIn {
	[self _stopTimer];	
	
	if (_fadingDuration == 0.0) {
		[self setAlphaValue: 1.0f]; 
		[NSTimer scheduledTimerWithTimeInterval: 0.0f target: self selector: @selector(_windowDidFadeIn) userInfo: nil repeats: NO]; 

		return; 
	}
	
	float timerInterval = _fadingDuration / (1.0 / kZNFadeIncrement); 
	
	// start fading 
	_fadingTimer = [[NSTimer scheduledTimerWithTimeInterval: timerInterval target: self selector: @selector(_onFadeInTick: ) userInfo: nil repeats: YES] retain];
}

@end

#pragma mark -
@implementation ZNEffectWindow (Animation) 

- (void) _onFadeInTick: (NSTimer*) timer {
	// fetch alpha value 
	float alphaValue = [self alphaValue]; 
	
	if (alphaValue < 1.0) {
		[self setAlphaValue: alphaValue + kZNFadeIncrement];
		return; 
	}
	
	// we are done fading, so we stop the timer and be done 
	[self _stopTimer]; 
	[self setAlphaValue: 1.0]; 
	
	// trigger notification call
	[self _windowDidFadeIn];
}

- (void) _onFadeOutTick: (NSTimer*) timer {
	// fetch alpha value 
	float alphaValue = [self alphaValue]; 
	
	if (alphaValue > 0.0) {
		[self setAlphaValue: alphaValue - kZNFadeIncrement]; 
		return; 
	}
	
	// we are done fading, so set alpha to 0.0 and order out 
	[self _stopTimer]; 
	[self setAlphaValue: 0.0]; 
	
	// trigger notification call 
	[self _windowDidFadeOut]; 
}

- (void) _stopTimer {
	if (_fadingTimer == nil)
		return; 
	
	[_fadingTimer invalidate]; 
	[_fadingTimer release];
	
	_fadingTimer = nil; 
}

@end

#pragma mark -
@implementation ZNEffectWindow(NotificationHelper)
- (void) _windowDidFadeIn {
	NSNotification* notification = [NSNotification notificationWithName: ZNWindowDidFadeInNotification object: self]; 
	
	// call the delegate (TODO: do it the right way via NSInvocation)
	if ([self delegate] && [[self delegate] respondsToSelector: @selector(windowDidFadeIn:)])
		[[self delegate] windowDidFadeIn: notification]; 
	
	// post the notification 
	[[NSNotificationCenter defaultCenter] postNotification: notification]; 
}

- (void) _windowDidFadeOut {
	NSNotification* notification = [NSNotification notificationWithName: ZNWindowDidFadeOutNotification object: self]; 
	
	// call the delegate (TODO: do it the right way via NSInvocation)
	if ([self delegate] && [[self delegate] respondsToSelector: @selector(windowDidFadeOut:)])
		[[self delegate] windowDidFadeOut: notification]; 
	
	// post the notification 
	[[NSNotificationCenter defaultCenter] postNotification: notification]; 
}

@end 

#pragma mark -
@implementation NSObject(ZNEffectWindowNotifications) 
- (void) windowDidFadeIn: (NSNotification*) notification {
}
- (void) windowDidFadeOut: (NSNotification*) notification {
}
@end 
