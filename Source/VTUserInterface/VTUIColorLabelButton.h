//
//  VTUIColorLabelButton.h
//  VirtueDesktops
//
//  Created by Tony on 2/10/06.
//  Copyright 2006 boomBalada! Productions. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VTUIColorLabelButtonCell.h" 

@interface VTUIColorLabelButton : NSControl {
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
- (void) setLabelType: (VTUIColorLabelButtonType) type; 
- (VTUIColorLabelButtonType) labelType; 

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
