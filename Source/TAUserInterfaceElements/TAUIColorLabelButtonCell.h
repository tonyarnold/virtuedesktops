//
//  TAUIColorLabelButtonCell.h
//  TAUserInterfaceElements.framework
//
//  Created by Tony on 2/10/06.
//  Copyright 2007 boomBalada! Productions..
//  Some rights reserved: <http://creativecommons.org/licenses/by/2.5/>
//

#import <Cocoa/Cocoa.h>

typedef enum {
	TAUIClearLabelType	= 0, 
	TAUIColorLabelType	= 1, 
} TAUIColorLabelButtonType; 

@interface TAUIColorLabelButtonCell : NSActionCell {
  NSColor*	mColor;
	NSImage*	mImage;
	
	TAUIColorLabelButtonType	mType;
	
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
- (void) setLabelType: (TAUIColorLabelButtonType) type; 
- (TAUIColorLabelButtonType) labelType; 

#pragma mark -
- (void) setSelected: (BOOL) flag; 
- (BOOL) selected; 

#pragma mark -
- (void) mouseEntered: (NSEvent*) event;
- (void) mouseExited: (NSEvent*) event;


@end
