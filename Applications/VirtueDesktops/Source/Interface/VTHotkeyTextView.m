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

#import "VTHotkeyTextView.h"
#import <Zen/Zen.h> 


@implementation VTHotkeyTextView

- (id) initWithFrame: (NSRect) rect {
	if (self = [super initWithFrame: rect]) {
		// initialize attributes 
		mHotkey = nil;
		return self; 
	}
	
	return nil;
}

- (void) dealloc {
	ZEN_RELEASE(mHotkey); 
	
	[super dealloc];
}


- (void) keyDown: (NSEvent*) event {
	if (mHotkey == nil) {
		[super keyDown: event]; 
		return; 
	}
	
	[mHotkey setKeyCode: [event keyCode]]; 
	[mHotkey setKeyModifiers: [event modifierFlags]]; 
	
	// set responder 
	[[self window] makeFirstResponder: [self superview]]; 
}

- (BOOL) performKeyEquivalent: (NSEvent*) theEvent {
	if (mHotkey == nil)
		return [super performKeyEquivalent: theEvent]; 
	
	[self keyDown: theEvent];
	return YES;
}

#pragma mark -
#pragma mark Attributes 

- (BOOL) shouldDrawInsertionPoint {
	return NO; 
}

#pragma mark -
- (void) setHotkey: (VTHotkeyTrigger*) hotkey {
	ZEN_ASSIGN(mHotkey, hotkey); 
}

- (VTHotkeyTrigger*) hotkey {
	return mHotkey; 
}

- (BOOL) becomeFirstResponder {
	[self setTextColor: [NSColor darkGrayColor]]; 
	[self setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]]; 
	[self setString: NSLocalizedString(@"VTTriggerPreferencesPressToSet", @"Asks to press the keys of the keyboard trigger")]; 
	
	return YES; 
}

@end
