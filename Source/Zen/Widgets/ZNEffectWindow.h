//
//  ZNEffectWindow.h
//  Zen framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import <Cocoa/Cocoa.h>

@interface ZNEffectWindow : NSWindow {
	NSTimer*	_fadingTimer; 
	float		_fadingDuration; 
}

#pragma mark -
#pragma mark Attributes 
- (void) setFadingAnimationTime: (float) seconds; 
- (float) fadingAnimationTime; 

#pragma mark -
#pragma mark Visibility
- (void) fadeOut;
- (void) fadeIn; 

@end

#pragma mark -
@interface NSObject(ZNEffectWindowNotifications) 
- (void) windowDidFadeIn: (NSNotification*) notification; 
- (void) windowDidFadeOut: (NSNotification*) notification; 
@end 

#pragma mark -
@interface NSObject(ZNEffectWindowDelegate) 
@end 

#pragma mark -
extern NSString* ZNWindowDidFadeInNotification; 
extern NSString* ZNWindowDidFadeOutNotification; 


