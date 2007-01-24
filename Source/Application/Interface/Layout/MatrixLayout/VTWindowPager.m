//
//  VTWindowPager.m
//  VirtueDesktops
//
//  Created by Tony on 13/06/06.
//  Copyright 2007 boomBalada! Productions. All rights reserved.
//

#import "VTWindowPager.h"
#import "VTMatrixPagerView.h" 
#import "VTMatrixPagerPreferences.h"
#import "VTDesktopController.h"
#import "VTTriggerController.h" 
#import "NSUserDefaultsControllerKeyFactory.h"
#import "NSColorString.h"
#import <Peony/Peony.h> 
#import <Zen/Zen.h> 
#import <Zen/ZNEffectWindow.h> 

#define kVtCodingHasShadow						@"displayShadow"
#define kVtCodingApplicationIcons			@"displayIcons"
#define kVtCodingDisplayApplications	@"displayIcons"
#define kVtCodingDisplayColorLabels		@"displayLabels"
#define kVtCodingDisplayUnderMouse		@"displayUnderMouse"
#define kVtCodingWarpMouse						@"warpMouse"
#define kVtCodingColorBackground			@"backgroundColor"
#define kVtCodingColorBackgroundHi		@"backgroundHiColor"
#define kVtCodingColorWindow					@"windowColor"
#define kVtCodingColorWindowHi				@"windowHiColor"
#define kVtCodingColorText						@"textColor"

#pragma mark -
@interface VTWindowPagerWindow : ZNEffectWindow 
- (BOOL) canBecomeKeyWindow; 
@end 

#pragma mark -
@interface VTWindowPager (Private) 
- (void) createWindow; 
- (void) doDisplayWindow; 
- (void) doHideWindow; 
@end 

#pragma mark -
@implementation VTWindowPager

#pragma mark -
#pragma mark Lifetime 

- (id) initWithLayout: (VTMatrixDesktopLayout*) layout {
	if (self = [super init]) {
		// attributes 
		ZEN_ASSIGN(mLayout, layout); 
		mWindow							= nil;
		mStick							= NO; 
		mAnimates						= YES; 
		mDisplayUnderMouse	= NO; 
		mWarpMousePointer		= NO; 
		mShowing						= NO; 
		
		// initialize 
		[self createWindow]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mLayout); 
	ZEN_RELEASE(mWindow); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Coding 

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	[dictionary setObject: [NSNumber numberWithBool: [self displaysApplicationIcons]] forKey: kVtCodingDisplayApplications]; 
	[dictionary setObject: [NSNumber numberWithBool: [self displaysColorLabels]] forKey: kVtCodingDisplayColorLabels]; 
	[dictionary setObject: [NSNumber numberWithBool: [mWindow hasShadow]] forKey: kVtCodingHasShadow]; 
	[dictionary setObject: [NSNumber numberWithBool: mDisplayUnderMouse] forKey: kVtCodingDisplayUnderMouse]; 
	[dictionary setObject: [NSNumber numberWithBool: mWarpMousePointer] forKey: kVtCodingWarpMouse]; 
	
	// colors 
	[dictionary setObject: [[self backgroundColor] stringValue] forKey: kVtCodingColorBackground]; 
	[dictionary setObject: [[self highlightColor] stringValue] forKey: kVtCodingColorBackgroundHi]; 
	[dictionary setObject: [[self windowColor] stringValue] forKey: kVtCodingColorWindow]; 
	[dictionary setObject: [[self windowHighlightColor] stringValue] forKey: kVtCodingColorWindowHi]; 
	[dictionary setObject: [[self desktopNameColor] stringValue] forKey: kVtCodingColorText]; 
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	[self setDisplaysApplicationIcons: [[dictionary objectForKey: kVtCodingDisplayApplications] boolValue]]; 
	[self setDisplaysColorLabels: [[dictionary objectForKey: kVtCodingDisplayColorLabels] boolValue]]; 
	[self setDisplaysShadow: [[dictionary objectForKey: kVtCodingHasShadow] boolValue]]; 
	[self setDisplaysUnderMouse: [[dictionary objectForKey: kVtCodingDisplayUnderMouse] boolValue]]; 
	[self setWarpsMousePointer: [[dictionary objectForKey: kVtCodingWarpMouse] boolValue]]; 
	
	NSColor* color; 
	// colors 
	color = [NSColor colorWithString: [dictionary objectForKey: kVtCodingColorBackground]]; 
	if (color)
		[self setBackgroundColor: color]; 
	color = [NSColor colorWithString: [dictionary objectForKey: kVtCodingColorBackgroundHi]]; 
	if (color)
		[self setHighlightColor: color]; 
	color = [NSColor colorWithString: [dictionary objectForKey: kVtCodingColorWindow]]; 
	if (color)
		[self setWindowColor: color]; 
	color = [NSColor colorWithString: [dictionary objectForKey: kVtCodingColorWindowHi]]; 
	if (color)
		[self setWindowHighlightColor: color]; 
	color = [NSColor colorWithString: [dictionary objectForKey: kVtCodingColorText]]; 
	if (color)
		[self setDesktopNameColor: color]; 
	
	return self; 
}

#pragma mark -
#pragma mark Attributes 
- (NSString*) name {
  return @"Window";
}

#pragma mark -
- (void) setDisplaysApplicationIcons: (BOOL) flag {
	[[mWindow contentView] setDisplaysApplicationIcons: flag]; 
}

- (BOOL) displaysApplicationIcons {
	return [[mWindow contentView] displaysApplicationIcons]; 
}

#pragma mark -
- (void) setDisplaysColorLabels: (BOOL) flag {
	[[mWindow contentView] setDisplaysColorLabels: flag]; 
}

- (BOOL) displaysColorLabels {
	return [[mWindow contentView] displaysColorLabels]; 
}

#pragma mark -
- (void) setDisplaysUnderMouse: (BOOL) flag {
	mDisplayUnderMouse = flag; 
}

- (BOOL) displaysUnderMouse {
	return mDisplayUnderMouse; 
}

#pragma mark -
- (void) setWarpsMousePointer: (BOOL) flag {
	mWarpMousePointer = flag; 
}

- (BOOL) warpsMousePointer {
	return mWarpMousePointer; 
}

#pragma mark -
- (void) setDisplaysShadow: (BOOL) flag {
	[mWindow setHasShadow: flag]; 
}

- (BOOL) displaysShadow {
	return [mWindow hasShadow]; 
}

#pragma mark -
- (void) setBackgroundColor: (NSColor*) color {
	[[mWindow contentView] setBackgroundColor: color]; 
}

- (NSColor*) backgroundColor {
	return [[mWindow contentView] backgroundColor]; 
}

#pragma mark -
- (void) setHighlightColor: (NSColor*) color {
	[[mWindow contentView] setBackgroundHighlightColor: color]; 
}

- (NSColor*) highlightColor {
	return [[mWindow contentView] backgroundHighlightColor]; 
}

#pragma mark -
- (void) setWindowColor: (NSColor*) color {
	[[mWindow contentView] setWindowColor: color]; 
}

- (NSColor*) windowColor {
	return [[mWindow contentView] windowColor]; 
}

#pragma mark -
- (void) setWindowHighlightColor: (NSColor*) color {
	[[mWindow contentView] setWindowHighlightColor: color]; 
}

- (NSColor*) windowHighlightColor {
	return [[mWindow contentView] windowHighlightColor]; 
}

#pragma mark -
- (void) setDesktopNameColor: (NSColor*) color {
	[[mWindow contentView] setTextColor: color]; 
}

- (NSColor*) desktopNameColor {
	return [[mWindow contentView] textColor]; 
}


#pragma mark -
#pragma mark VTPager 

- (IBAction) displayMe: (id) sender {
  if (mWindow) {
    [self doDisplayWindow];
  } else {
    [self createWindow];
    [self doDisplayWindow];
  }
}

- (IBAction) hideMe: (id) sender {
	[self doHideWindow];
}

- (void) display: (BOOL) sticky {
	mStick = sticky; 
  
	[self doDisplayWindow]; 
}

- (void) hide {
  [self doHideWindow];
}

#pragma mark -
#pragma mark NSWindow delegate 

- (void) windowDidResignKey: (NSNotification*) aNotification {
	// as soon as the window resigned key focus, we will close it 
//	[self doHideWindow];
}

#pragma mark -
- (void) flagsChanged: (NSEvent*) event {
	//if (mStick == NO)
		//[self doHideWindow];
}

- (void) keyDown: (NSEvent*) event {
	NSString*		characters	= [event charactersIgnoringModifiers]; 
	
	// Enter and Space: Will trigger switch to selected desktop 
	if (([characters characterAtIndex: 0] == NSEnterCharacter) ||
      ([characters characterAtIndex: 0] == NSCarriageReturnCharacter) ||
      ([characters characterAtIndex: 0] == 0x0020)) {
    
		//[self doHideWindow];
		return; 
	}
	// Escape: Will trigger closing without switch, by setting the selected 
	// desktop to nil 
	if ([characters characterAtIndex: 0] == 0x001B) {
		[(VTMatrixPagerView*)[mWindow contentView] setSelectedDesktop: nil];
		[self doHideWindow];
		
		return; 
	}
}

#pragma mark -
#pragma mark Actions 

- (void) onDesktopSelected: (id) sender {
	// order out window, we will do the rest then... 
	//[self doHideWindow];
  
  //mShowing = NO; 
  
	// reactivate hotkeys 
	//[[VTTriggerController sharedInstance] setEnabled: YES]; 
  
	VTDesktop* selectedDesktop = [(VTMatrixPagerView*)[mWindow contentView] selectedDesktop];
  
  // if we got a selected desktop, switch to it
	if (!selectedDesktop)
		return; 
	
	VTDesktop* desktop = [(VTMatrixPagerView*)[mWindow contentView] selectedDesktop]; 
	[[VTDesktopController sharedInstance] activateDesktop: desktop]; 
}

#pragma mark -
#pragma mark KVO Sink 

- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object change: (NSDictionary*) change context: (void*) context {
	if ([keyPath isEqualToString: [NSUserDefaultsController pathForKey: VTMatrixPagerHasShadow]]) {
		[mWindow setHasShadow: [[NSUserDefaults standardUserDefaults] boolForKey: VTMatrixPagerHasShadow]]; 
	}
}

@end

#pragma mark -
@implementation VTWindowPager (Private) 

- (void) createWindow {
	// create our view 
	NSRect contentRect = NSZeroRect;
	
	// create our view 
	VTMatrixPagerView* view = [[[VTMatrixPagerView alloc] initWithFrame: contentRect forLayout: mLayout] autorelease];
	// and attach ourselves as the target 
	[[view desktopCollectionMatrix] setTarget: self]; 
	[[view desktopCollectionMatrix] setAction: @selector(onDesktopSelected:)];
	
	// get the content rect from the view 
	contentRect = [view frame];
	
	// create the window 
	mWindow = [[VTWindowPagerWindow alloc] initWithContentRect: contentRect 
																									 styleMask: NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
																										 backing: NSBackingStoreBuffered
																											 defer: NO];
	
	// set up the window as we need it 
	[mWindow setBackgroundColor: [NSColor clearColor]];
	[mWindow setOpaque: NO];
	[mWindow setIgnoresMouseEvents: NO];
	[mWindow setAcceptsMouseMovedEvents: YES]; 
	[mWindow setHasShadow: YES];
	[mWindow setReleasedWhenClosed: NO];
	
	// bind the view to the window  
	[mWindow setContentView: view];
	[mWindow setInitialFirstResponder: view]; 
	
	// now set alpha to 1 and level accordingly 
	[mWindow setAlphaValue: 0.0f]; 
	[mWindow setLevel: kCGUtilityWindowLevel]; 
	// set ourselves as the delegate 
	[mWindow setDelegate: self]; 
	
	// and make the window special to hide it 
	[[PNWindow windowWithNSWindow: mWindow] setSpecial: YES];
	[[PNWindow windowWithNSWindow: mWindow] setSticky: YES];	
}

- (void) doDisplayWindow {
	mShowing = YES; 
	
	// we have to set position and size of the window...
	NSRect	windowFrame		= [mWindow frame]; 
	NSRect	screenFrame		= [[NSScreen mainScreen] visibleFrame];  
		
	// decide on the position to display the overlay... 
	if (mDisplayUnderMouse == NO) {
		// we do not bind the pager to the mouse position, so we just center it
		windowFrame.origin.x	= (int)(0.5f * (screenFrame.size.width - windowFrame.size.width));  
		windowFrame.origin.y	= (int)(0.5f * (screenFrame.size.height - windowFrame.size.height));  
	}
	else {
		if (mWarpMousePointer == YES) {
			// TODO: Implement focusing on active desktop 
		}
		else {
			// we do not center the pager around anything special, so just position the center of 
			// the pager around the mouse pointer as good as possible 
			CGPoint location;
			CGSGetCurrentCursorLocation(_CGSDefaultConnection(), &location);
			
			// we have to mirror the location 
			location.y = screenFrame.size.height - location.y + screenFrame.origin.y; 
						
			windowFrame.origin.x = location.x - (windowFrame.size.width * 0.5); 
			windowFrame.origin.y = location.y - (windowFrame.size.height * 0.5); 
			
			// check if we are outside screen bounds and move if we are 
			if (windowFrame.origin.x + windowFrame.size.width > screenFrame.size.width)
				windowFrame.origin.x = windowFrame.origin.x - (windowFrame.origin.x + windowFrame.size.width - screenFrame.size.width); 
			if (windowFrame.origin.x < screenFrame.origin.x)
				windowFrame.origin.x = screenFrame.origin.x; 
			if (windowFrame.origin.y + windowFrame.size.height > screenFrame.size.height)
				windowFrame.origin.y = windowFrame.origin.y - (windowFrame.origin.y + windowFrame.size.height - screenFrame.size.height); 
			if (windowFrame.origin.y < screenFrame.origin.y)
				windowFrame.origin.y = screenFrame.origin.y; 
		}
	}
		
	// position the window off screen 
	[mWindow setFrame: windowFrame display: NO]; 
	
	// set desktop for view 
	[(VTMatrixPagerView*)[mWindow contentView] setSelectedDesktop: [[VTDesktopController sharedInstance] activeDesktop]]; 
	// force redisplay to be sure we are displaying the latest snapshot
	[[mWindow contentView] setNeedsDisplay: YES]; 
	// make our window the key window; we are being rude here and take away 
	// key from other applications and make ourselves the active application
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
	[(ZNEffectWindow*)mWindow setFadingAnimationTime: 0.5f];
	[(ZNEffectWindow*)mWindow fadeIn]; 
	
	// and disable all hotkeys 
	//[[VTTriggerController sharedInstance] setEnabled: NO]; 
}

- (void) doHideWindow {
	if (mShowing == NO)
		return; 	
	mShowing = NO; 
  
	// reactivate hotkeys 
	[[VTTriggerController sharedInstance] setEnabled: YES]; 
  
	VTDesktop* selectedDesktop = [(VTMatrixPagerView*)[mWindow contentView] selectedDesktop]; 
	
	// if we have a selected desktop, we order out immediately as we will switch
	// desktops and there is no time to fade out
	if ((selectedDesktop != nil) && (selectedDesktop != [[VTDesktopController sharedInstance] activeDesktop])) {
		[(ZNEffectWindow*)mWindow setFadingAnimationTime: 0.0f]; 
		[(ZNEffectWindow*)mWindow fadeOut]; 
		
		return; 
	}
	
	// otherwise, smoothly fade out the window 
	[(ZNEffectWindow*)mWindow setFadingAnimationTime: 0.2f]; 
	[(ZNEffectWindow*)mWindow fadeOut]; 
}

#pragma mark -
#pragma mark ZNEffectWindow Delegate 

- (void) windowDidFadeIn: (NSNotification*) notification {
	[[notification object] makeKeyAndOrderFront: self]; 
}

- (void) windowDidFadeOut: (NSNotification*) notification {
	[[notification object] orderOut: self]; 
}

@end 

#pragma mark -
@implementation VTWindowPagerWindow

/**
* Have to work around the Cocoa default implementation that disallows windows 
 * without title bar to become the key window.. so we will override the guilty 
 * method and return YES here 
 *
 */ 
- (BOOL) canBecomeKeyWindow {
	return YES; 
}

/**
* TODO: Fixme
 * Note that this is a workaround, as I thought those events from the NSResponder
 * walk up the responder chain automagically if not handled; maybe something done
 * in the VTMatrixPagerView is wrong and breaks the chain? 
 * 
 */ 
- (void) flagsChanged: (NSEvent*) event {
	[[self delegate] flagsChanged: event]; 
}

- (void) keyDown: (NSEvent*) event {
	[[self delegate] keyDown: event]; 
}

@end 
