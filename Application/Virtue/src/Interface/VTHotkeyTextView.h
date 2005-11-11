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

#import <Cocoa/Cocoa.h>
#import <Virtue/VTHotkeyTrigger.h>


@interface VTHotkeyTextView : NSTextView {
	NSButton*			mClearButton;
	VTHotkeyTrigger*	mHotkey; 
}

#pragma mark -
#pragma mark Attributes 

- (void) setHotkey: (VTHotkeyTrigger*) hotkey; 
- (VTHotkeyTrigger*) hotkey; 

@end
