#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <Zen/Zen.h>
#import "VTNotifications.h"
#import "VTApplication.h"

enum  {
	kVtEventHotKeyPressedSubtype  = 6,
	kVtEventHotKeyReleasedSubtype = 9,
};

@implementation VTApplication

- (void) sendEvent: (NSEvent*) theEvent  { 
	// Hi-jack key presses and search for registered hot-key presses that we will use to send a hot-key press notification 
    if (([theEvent type]	== NSSystemDefined) && ([theEvent subtype] == kVtEventHotKeyPressedSubtype)) {
        EventHotKeyRef hotKeyRef = (EventHotKeyRef) [theEvent data1];
        [[NSNotificationCenter defaultCenter] postNotificationName: kVtNotificationOnKeyPress 
                                                            object: [NSValue value: &hotKeyRef withObjCType: @encode(EventHotKeyRef)]];
    }
	
    [super sendEvent: theEvent];
}

@end