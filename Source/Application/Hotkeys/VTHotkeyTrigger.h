/*
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
 */

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h> 
#import "VTTrigger.h"

@interface VTHotkeyTrigger : VTTrigger {
	EventHotKeyRef	mHotkeyRef;			//!< The native hot key ref
  int							mKeyCode;				//!< The keycode of the hotkey 
	int							mKeyModifiers;	//!< Modifiers of the hotkey 
}

#pragma mark -
#pragma mark Lifetime 

+ (id) hotkeyWithKeyCode: (int) keyCode andModifiers: (int) modifiers; 

#pragma mark -
- (id) init; 
- (id) initWithKeyCode: (int) keyCode andModifiers: (int) modifiers; 
- (id) copyWithZone: (NSZone*) zone; 

#pragma mark -
#pragma mark NSObject 

- (BOOL) isEqual: (id) other; 

#pragma mark -
#pragma mark Attributes 

- (int) keyCode; 
- (void) setKeyCode: (int) keyCode; 

#pragma mark -
- (int) keyModifiers; 
- (int) keyCarbonModifiers;
- (void) setKeyModifiers: (int) keyModifiers; 

#pragma mark -
- (EventHotKeyRef) hotkeyRef; 

@end
