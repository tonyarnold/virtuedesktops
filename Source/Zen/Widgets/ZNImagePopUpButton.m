/******************************************************************************
* 
* Zen 
*
* A foundations framework 
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2007, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "ZNImagePopUpButton.h"
#import "ZNMemoryManagementMacros.h" 

@implementation ZNImagePopUpButton

#pragma mark -
#pragma mark Lifetime 
- (id) initWithFrame: (NSRect) frame {
	if (self = [super initWithFrame: frame]) {
		// set up our button layout as we need it 
		[self setBordered: NO]; 
		[self setButtonType: NSMomentaryChangeButton]; 
		
		return self; 
	}
	
	return nil; 
}

#pragma mark -
- (id) initWithCoder: (NSCoder*) coder {
	return [super initWithCoder: coder]; 
}

- (void) encodeWithCoder: (NSCoder*) coder {
	[super encodeWithCoder: coder]; 
}

#pragma mark -
#pragma mark NSView 

- (void) mouseDown: (NSEvent*) event {
	if ([self isEnabled] == NO) 
		return;
	
	if([self menu] == nil) {
		[super mouseDown: event];
		return;
	}
	
	// highlight the button 
	[self highlight: YES];
	
	// create a temporary event to pass on to the NSMenu.popUpContextMenu: 
	// message. we are setting a new position so the popup menu pops up at
	// a nice location right below our widget 
	NSPoint point = [self convertPoint: [self bounds].origin toView: nil];
	point.y -= NSHeight([self frame]) + 2.0;
	point.x -= 1.0;
	
	NSEvent* simulatedEvent = [NSEvent mouseEventWithType: [event type] location: point modifierFlags: [event modifierFlags] timestamp: [event timestamp] windowNumber: [[event window] windowNumber] context: [event context] eventNumber: [event eventNumber] clickCount: [event clickCount] pressure: [event pressure]];
	[NSMenu popUpContextMenu: [self menu] withEvent: simulatedEvent forView: self];
	
	[self mouseUp: [[NSApplication sharedApplication] currentEvent]];
}

- (void) mouseUp: (NSEvent*) event {
	// remove highlighting and pass on event 
	[self highlight: NO]; 
	[super mouseUp: event]; 
}

- (void) mouseDragged: (NSEvent*) event {
	// Ignore 
	return;
}

@end