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

#import <Carbon/Carbon.h>

#import "VTApplication.h"
#import <Virtue/VTNotifications.h>


enum  {
    kVtEventHotKeyPressedSubtype  = 6,
    kVtEventHotKeyReleasedSubtype = 9,
};

@implementation VTApplication

- (void) sendEvent: (NSEvent*) theEvent  { 
	// hijack key presses and search for registered hot key presses 
	// that we will use to send a hotkey press notification 
    if (([theEvent type]	== NSSystemDefined) && 
        ([theEvent subtype] == kVtEventHotKeyPressedSubtype)) {
        EventHotKeyRef hotKeyRef = (EventHotKeyRef) [theEvent data1];
		
        [[NSNotificationCenter defaultCenter]
			postNotificationName: kVtNotificationOnKeyPress 
			object: [NSValue value: &hotKeyRef withObjCType: @encode(EventHotKeyRef)]];		
    }
	
    [super sendEvent: theEvent];
}

@end
