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

#import <Cocoa/Cocoa.h>
#import "VTHotkeyTrigger.h"

@interface VTHotkeyTextView : NSTextView {
	NSButton*			mClearButton;
	VTHotkeyTrigger*	mHotkey; 
}

#pragma mark -
#pragma mark Attributes 

- (void) setHotkey: (VTHotkeyTrigger*) hotkey; 
- (VTHotkeyTrigger*) hotkey; 

@end
