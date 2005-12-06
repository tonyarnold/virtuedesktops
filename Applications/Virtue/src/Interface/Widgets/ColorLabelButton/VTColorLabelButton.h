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

#import <Cocoa/Cocoa.h>
#import "VTColorLabelButtonCell.h" 

#pragma mark -
@interface VTColorLabelButton : NSControl {
	NSMatrix*		mColorLabels; 
	NSMutableArray*	mTrackingRects; 
	BOOL			mDisplaysClearButton; 

}

#pragma mark -
#pragma mark Lifetime 
- (id) initWithFrame: (NSRect) frame; 
- (void) dealloc; 

#pragma mark -
- (void) setLabelType: (VTColorLabelButtonType) type; 
- (VTColorLabelButtonType) labelType; 

#pragma mark -
- (NSControlSize) controlSize;
- (void) setControlSize: (NSControlSize) newControlSize;

#pragma mark -
- (void) setColorLabels: (NSArray*) colors; 
- (NSArray*) colorLabels; 

#pragma mark -
- (void) selectColorLabel: (NSColor*) color; 
- (NSColor*) selectedColorLabel; 

#pragma mark -
- (void) setDisplaysClearButton: (BOOL) flag; 
- (BOOL) displaysClearButton; 

@end
