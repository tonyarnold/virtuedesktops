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

#import "VTNotificationBezel.h"
#import "VTPreferences.h"
#import "NSUserDefaultsControllerKeyFactory.h"
#import <Zen/ZNMemoryManagementMacros.h> 

#define kVtFadingIncrement	0.05
#define kVtFadingDelay			0.5 / (1.0 / kVtFadingIncrement)

@interface VTNotificationBezel(Private) 
- (void) show: (PNDesktop*) desktop withText: (NSString*) text; 
- (void) stopTimer;
- (void) startFadingOut; 
- (void) fadeOut; 
@end 

#pragma mark -
@implementation VTNotificationBezel

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		// attributes 
		mTimer = nil; 
		
		// window 
		NSRect contentRect = NSMakeRect(0, 0, 215, 215); 
		mWindow = [[NSWindow alloc] 
						initWithContentRect: contentRect 
						styleMask: NSBorderlessWindowMask 
						backing: NSBackingStoreBuffered
						defer: FALSE];
		
		// set up the window as we need it 
		[mWindow setLevel: kCGUtilityWindowLevel]; 
		[mWindow setBackgroundColor: [NSColor clearColor]];
		[mWindow setOpaque: NO];
		[mWindow setIgnoresMouseEvents: YES];
		
		// view
		mView = [[VTNotificationBezelView alloc] initWithFrame: contentRect]; 
		
		[mWindow setAlphaValue: 0.0f]; 
		[mWindow setContentView: mView]; 
		
		// positin the window 
		NSRect windowFrame			= [mWindow frame]; 
		NSRect screenFrame			= [[NSScreen mainScreen] frame];
		
		windowFrame.origin.x = (int)(0.5f * (screenFrame.size.width - windowFrame.size.width)); 
		windowFrame.origin.y = (int)(0.5f * ((2.0/3.0) * screenFrame.size.height - windowFrame.size.height)); 
		
		[mWindow setFrame: windowFrame display: NO]; 
		
		// and mark the window as special so it wont show up 
		[[PNWindow windowWithNSWindow: mWindow] setSpecial: YES]; 
		
		// register for updates to preferences we care about 
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver: self forKeyPath: [NSUserDefaultsController pathForKey: VTDesktopTransitionNotifyDuration] options: NSKeyValueObservingOptionNew context: NULL]; 
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver: self forKeyPath: [NSUserDefaultsController pathForKey: VTDesktopTransitionNotifyApplets] options: NSKeyValueObservingOptionNew context: NULL]; 
		[[NSUserDefaultsController sharedUserDefaultsController] addObserver: self forKeyPath: [NSUserDefaultsController pathForKey: VTDesktopTransitionNotifyEnabled] options: NSKeyValueObservingOptionNew context: NULL]; 
		// register for desktop switch notifications 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopDidActivate:) name: kPnOnDesktopDidActivate object: nil]; 
		
		// get defaults 
		mShowBezel = [[NSUserDefaults standardUserDefaults] boolForKey: VTDesktopTransitionNotifyEnabled]; 
		mDuration  = [[NSUserDefaults standardUserDefaults] floatForKey: VTDesktopTransitionNotifyDuration]; 
		[mView setDrawsApplets: [[NSUserDefaults standardUserDefaults] boolForKey: VTDesktopTransitionNotifyApplets]]; 
		
		if (mDuration < 0.5)
			mDuration += 0.5; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	// invalidate timer 
	[mTimer invalidate]; 
	// release attributes 
	ZEN_RELEASE(mTimer); 
	ZEN_RELEASE(mWindow); 
	ZEN_RELEASE(mView); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Actions 

- (IBAction) showNotificationBezel: (id) sender {
	[self show: nil withText: @"VirtueDesktops"]; 
}

#pragma mark -
#pragma mark Notification Sink

- (void) onDesktopDidActivate: (NSNotification*) notification {
	[self show: [notification object] withText: [[notification object] name]]; 
}

#pragma mark -
#pragma mark KVO Sink

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	// bezel enabled 
	if ([keyPath hasSuffix: VTDesktopTransitionNotifyEnabled]) {
		mShowBezel = [[NSUserDefaults standardUserDefaults] boolForKey: VTDesktopTransitionNotifyEnabled]; 
	}
	// showing application icons in bezel 
	else if ([keyPath hasSuffix: VTDesktopTransitionNotifyApplets]) {
		[mView setDrawsApplets: [[NSUserDefaults standardUserDefaults] boolForKey: VTDesktopTransitionNotifyApplets]]; 
	}
	// bezel onscreen lifetime 
	else if ([keyPath hasSuffix: VTDesktopTransitionNotifyDuration]) {
		mDuration = [[NSUserDefaults standardUserDefaults] floatForKey: VTDesktopTransitionNotifyDuration]; 
		// and correct value 
		if (mDuration <= 0.5)
			mDuration = mDuration + 0.5; 
	}
}


@end

#pragma mark -
@implementation VTNotificationBezel(Private) 

#pragma mark -
- (void) show: (PNDesktop*) desktop withText: (NSString*) text {
	// order out the window and kill of the timer 
	[mWindow orderOut: self]; 
	[self stopTimer]; 
	
	if (mShowBezel == NO)
		return; 
	
	// set desktopname for view 
	[mView setDesktop: desktop]; 
	[mView setText: text]; 

	// show the window 
	[mWindow setAlphaValue: 1.0]; 
	[mWindow orderFrontRegardless];
	
	// set up timer to trigger fading out of the window 
	mTimer = [[NSTimer scheduledTimerWithTimeInterval: (mDuration - 0.5)
				target: self 
				selector: @selector(startFadingOut)
				userInfo: nil
				repeats: NO] retain]; 
}

- (void) stopTimer {
	[mTimer invalidate]; 
	ZEN_RELEASE(mTimer); 
}

- (void) fadeOut {
	// if we are still visible (alpha > 0.0), we will continue fading 
	if ([mWindow alphaValue] > 0.0) {
		[mWindow setAlphaValue: [mWindow alphaValue] - kVtFadingIncrement]; 
	}
	else {
		// stop the timer and order out the window 
		[self stopTimer]; 
		[mWindow orderOut: self]; 
	}

}

- (void) startFadingOut {
	// first, we stop the timer 
	[self stopTimer]; 
	// now start fading 
	mTimer = [[NSTimer scheduledTimerWithTimeInterval: kVtFadingDelay
				target: self
				selector: @selector(fadeOut)
				userInfo: nil
				repeats: YES] retain]; 
}

@end 