//
//  VTUIColorLabelButtonCell.h
//  VirtueDesktops
//
//  Created by Tony on 2/10/06.
//  Copyright 2006 boomBalada! Productions. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	VTClearLabelType	= 0, 
	VTUIColorLabelType	= 1, 
} VTUIColorLabelButtonType; 

@interface VTUIColorLabelButtonCell : NSActionCell {
  NSColor*	mColor;
	NSImage*	mImage;
	
	VTUIColorLabelButtonType	mType;
	
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
- (void) setLabelType: (VTUIColorLabelButtonType) type; 
- (VTUIColorLabelButtonType) labelType; 

#pragma mark -
- (void) setSelected: (BOOL) flag; 
- (BOOL) selected; 

#pragma mark -
- (void) mouseEntered: (NSEvent*) event;
- (void) mouseExited: (NSEvent*) event;


@end
