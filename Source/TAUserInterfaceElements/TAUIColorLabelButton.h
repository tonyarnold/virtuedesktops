//
//  TAUIColorLabelButton.h
//  TAUserInterfaceElements.framework
//
//  Created by Tony on 2/10/06.
//  Copyright 2007 boomBalada! Productions..
//  Some rights reserved: <http://creativecommons.org/licenses/by/2.5/>
//

#import <Cocoa/Cocoa.h>
#import "TAUIColorLabelButtonCell.h" 

@interface TAUIColorLabelButton : NSControl {
  NSMatrix*       mColorLabels;
	NSMutableArray*	mTrackingRects;
	BOOL            mDisplaysClearButton;
  NSColor*        mColorLabelColor;
}

#pragma mark -
#pragma mark Lifetime 
- (id) initWithFrame: (NSRect) frame; 
- (void) bootstrapView;
- (void) doAction: (id) sender;
- (void) dealloc; 

#pragma mark -
- (void) setLabelType: (TAUIColorLabelButtonType) type; 
- (TAUIColorLabelButtonType) labelType; 

#pragma mark -
- (NSControlSize) controlSize;
- (void) setControlSize: (NSControlSize) newControlSize;

#pragma mark -
- (void) setColorLabels: (NSArray*) colors; 
- (NSArray*) colorLabels; 

#pragma mark -
- (void) setSelectedColorLabel: (NSColor*) color; 
- (NSColor*) selectedColorLabel; 

#pragma mark -
- (void) setDisplaysClearButton: (BOOL) flag; 
- (BOOL) displaysClearButton; 

@end
