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

#import "VTHotkeyCell.h"
#import "VTHotkeyTextView.h" 
#import "VTHotkeyTrigger.h"
#import "VTMouseTrigger.h"

@implementation VTHotkeyCell
- (void) setObjectValue: (id) object {	
	
	if ([object isKindOfClass: [VTHotkeyTrigger class]]) {
		[self setFocusRingType: NSFocusRingTypeNone];
		
		if ((object == nil) || ([(VTHotkeyTrigger*)object keyCode] < 0)) {
			NSDictionary* textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize: [NSFont smallSystemFontSize]], NSFontAttributeName, 
				[NSColor lightGrayColor], NSForegroundColorAttributeName, 
				nil];
			
			NSAttributedString* attributedObject = [[[NSAttributedString alloc] initWithString: @"None" attributes: textAttributes] autorelease];
			[super setObjectValue: attributedObject]; 
		}
		else {
			NSDictionary* textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
				[NSFont systemFontOfSize: [NSFont smallSystemFontSize]], NSFontAttributeName, 
				[NSColor blackColor], NSForegroundColorAttributeName, 
				nil];
			
			NSAttributedString* attributedObject = [[[NSAttributedString alloc] initWithString: [(VTHotkeyTrigger*)object stringValue] attributes: textAttributes] autorelease];
			[super setObjectValue: attributedObject];
		}
		[self setRepresentedObject: object]; 
		[self setEditable: YES]; 
	}
	else if ([object isKindOfClass: [VTMouseTrigger class]]) {
		[self setRepresentedObject: nil]; 
		[self setEditable: NO]; 
		[super setObjectValue: [(VTMouseTrigger*)object stringValue]]; 
	}
	else {
		[super setObjectValue: object];
		[self setRepresentedObject: nil];
		[self setEditable: YES];
	}
	
	
}

- (NSText*) setUpFieldEditorAttributes: (NSText*) textObj {
	[super setUpFieldEditorAttributes: textObj];
	
	if ([textObj isKindOfClass: [VTHotkeyTextView class]]) {
		if ([[self representedObject] isKindOfClass: [VTHotkeyTrigger class]]) {
			[(VTHotkeyTextView*) textObj setHotkey: [self representedObject]]; 
		}
	}
	
	return textObj;
}

@end
