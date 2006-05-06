/******************************************************************************
* 
* Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2006, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import <Cocoa/Cocoa.h>

typedef enum {
	VTClearLabelType	= 0, 
	VTColorLabelType	= 1, 
} VTColorLabelButtonType; 

#pragma mark -
@interface VTColorLabelButtonCell : NSActionCell {
	// attributes 
	NSColor*	mColor; 
	NSImage*	mImage; 
	
	VTColorLabelButtonType	mType; 
	
	BOOL		mMouseInside; 
	BOOL		mSelected; 
}

#pragma mark -
- (id) init; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (void) setColor: (NSColor*) color; 
- (NSColor*) color; 

#pragma mark -
- (void) setLabelType: (VTColorLabelButtonType) type; 
- (VTColorLabelButtonType) labelType; 

#pragma mark -
- (void) setSelected: (BOOL) flag; 
- (BOOL) isSelected; 

#pragma mark -
- (void) mouseEntered: (NSEvent*) event;
- (void) mouseExited: (NSEvent*) event;

@end
