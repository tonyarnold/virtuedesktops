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

#import "VTColorLabelButton.h"
#import "VTColorLabelButtonCell.h" 

@interface VTColorLabelButton(Private) 
- (void) resetColorLabels: (NSArray*) colors; 
- (void) resetTrackingRects; 

- (void) setSelectedColorLabel: (NSColor*) color; 
@end 

#pragma mark -
@implementation VTColorLabelButton

#pragma mark -
#pragma mark Lifetime 
- (id) initWithFrame: (NSRect) frame {
	if (self = [super initWithFrame: frame]) {
		// attributes 
		mTrackingRects = [[NSMutableArray alloc] init]; 
		
		// create matrix 
		NSSize cellSpacing = NSMakeSize(2, 2); 
		
		// create the cell matrix 
		NSRect labelFrame = frame; 
		labelFrame.origin = NSZeroPoint; 
		mColorLabels = [[NSMatrix alloc] initWithFrame: labelFrame]; 
		
		[mColorLabels setCellClass: [VTColorLabelButtonCell class]]; 
		[mColorLabels setIntercellSpacing: cellSpacing]; 
		[mColorLabels setMode: NSRadioModeMatrix];
		[mColorLabels setAllowsEmptySelection: NO]; 
		[mColorLabels setSelectionByRect: NO];  
		[mColorLabels setTarget: self]; 
		[mColorLabels setAction: @selector(onLabelSelected:)]; 
		
		[self addSubview: mColorLabels]; 
		
		return self; 
	}
	
	return nil;
}

- (void) dealloc {
	// remove all tracking rects 
	while ([mTrackingRects count] > 0) 
		[self removeTrackingRect: [[mTrackingRects objectAtIndex: 0] intValue]]; 
	[mTrackingRects removeAllObjects]; 

	// delegate to super
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 
- (void) setLabelType: (VTColorLabelButtonType) type {
	[[self cell] setLabelType: type]; 
}

- (VTColorLabelButtonType) labelType {
	return [[self cell] labelType]; 
}

- (NSControlSize) controlSize {
	return NSSmallControlSize;
}

- (void) setControlSize: (NSControlSize) newControlSize {
}

#pragma mark -
- (void) setColorLabels: (NSArray*) colors {
	[self resetColorLabels: colors]; 
	[self setNeedsDisplay: YES]; 
}

- (NSArray*) colorLabels {
	NSEnumerator*			cellIter	= [[mColorLabels cells] objectEnumerator]; 
	VTColorLabelButtonCell*	cell		= nil; 
	
	NSMutableArray* colors = [NSMutableArray array]; 
	
	while (cell = [cellIter nextObject]) {
		if ([cell color]) 
			[colors addObject: [cell color]]; 
	}
	
	return colors; 
}

#pragma mark -
- (void) selectColorLabel: (NSColor*) color {
	[self setSelectedColorLabel: color]; 
}

- (NSColor*) selectedColorLabel {
	if ([mColorLabels selectedCell] == nil)
		return nil; 
	if ([(VTColorLabelButtonCell*)[mColorLabels selectedCell] labelType] == VTClearLabelType)
		return nil; 
	
	return [(VTColorLabelButtonCell*)[mColorLabels selectedCell] color]; 
}

#pragma mark -
- (void) setDisplaysClearButton: (BOOL) flag {
	mDisplaysClearButton = flag; 
	
	[self resetColorLabels: [self colorLabels]]; 
	[self setNeedsDisplay]; 
}

- (BOOL) displaysClearButton {
	return mDisplaysClearButton; 
}

#pragma mark -
#pragma mark NSControl 

- (BOOL)isOpaque {
	return NO;
}

#pragma mark -
- (BOOL) acceptsFirstMouse: (NSEvent*) theEvent {
	return YES;
}

#pragma mark -
- (void) drawRect: (NSRect) aRect {
	[super drawRect: aRect]; 
}

#pragma mark -

- (void) mouseEntered: (NSEvent*) event {
	int						trackingTag		= [event trackingNumber]; 
	VTColorLabelButtonCell*	trackedCell		= (VTColorLabelButtonCell*)[mColorLabels cellWithTag: trackingTag]; 

	// forward the message to the correct cell 
	[trackedCell mouseEntered: event]; 
}

- (void) mouseExited: (NSEvent*) event {
	int						trackingTag		= [event trackingNumber]; 
	VTColorLabelButtonCell*	trackedCell		= (VTColorLabelButtonCell*)[mColorLabels cellWithTag: trackingTag]; 
	
	// forward the message to the correct cell 
	[trackedCell mouseExited: event]; 	
}

- (void) resetCursorRects {
	[self resetTrackingRects]; 
}

#pragma mark -
#pragma mark Actions 

- (void) onLabelSelected: (id) sender {
	// we are KVO compliant here 
	[self willChangeValueForKey: @"selectedColorLabel"]; 
	[self didChangeValueForKey: @"selectedColorLabel"]; 
	
	// sanity checks 
	if ([self target] == nil)
		return; 
	if ([self action] == nil)
		return; 
	if ([[self target] respondsToSelector: [self action]] == NO)
		return; 

	[[self target] performSelector: [self action] withObject: self]; 	
}

@end

#pragma mark -
@implementation VTColorLabelButton(Private) 

- (void) resetColorLabels: (NSArray*) colors {
	// remove old colors 
	while ([mColorLabels numberOfColumns] > 0) 
		[mColorLabels removeColumn: 0]; 
	
	int numberOfColumns = [colors count]; 	
	if (mDisplaysClearButton)
		numberOfColumns++; 
	
	[mColorLabels renewRows: 1 columns: numberOfColumns]; 
	
	NSEnumerator*	colorIter	= [colors objectEnumerator]; 
	NSColor*		color		= nil; 
	int				columnIter	= 0; 
	
	if (mDisplaysClearButton) {
		VTColorLabelButtonCell* cell = [[mColorLabels cells] objectAtIndex: 0]; 
		
		[cell setLabelType: VTClearLabelType]; 
		[cell setTarget: self]; 
		[cell setAction: @selector(onLabelSelected:)]; 
		
		// increment the iterator to start from column 1 later on, as the clear button 
		// is always displayed in the front 
		columnIter++; 
	}
	
	while (color = [colorIter nextObject]) {
		VTColorLabelButtonCell* cell = [[mColorLabels cells] objectAtIndex: columnIter]; 
		
		[cell setLabelType: VTColorLabelType]; 
		[cell setColor: color]; 
		[cell setTarget: self]; 
		[cell setAction: @selector(onLabelSelected:)]; 
		
		columnIter++; 
	}
	
	[mColorLabels sizeToFit];
	
	// now we get the size, the pager needs to display 
	NSRect labelsFrame	= [mColorLabels frame];
	// we also need to set the frame of the pager cells accordingly 
	NSRect viewFrame	= [self frame]; 
	viewFrame.size		= labelsFrame.size; 

	[self setFrame: viewFrame]; 
	[self setNeedsDisplay: YES]; 
}

- (void) resetTrackingRects {
	// remove all tracking rects 
	while ([mTrackingRects count] > 0) 
		[self removeTrackingRect: [[mTrackingRects objectAtIndex: 0] intValue]]; 
	[mTrackingRects removeAllObjects]; 
		
	// now create the new ones 
	NSEnumerator*			cellIter	= [[mColorLabels cells] objectEnumerator]; 
	VTColorLabelButtonCell*	cell		= nil; 
		
	while (cell = [cellIter nextObject]) {
		int row; 
		int col; 
			
		[mColorLabels getRow: &row column: &col ofCell: cell]; 
			
		NSRect cellFrame		= [mColorLabels cellFrameAtRow: row column: col]; 
		NSRect cellFrameView	= [mColorLabels convertRect: cellFrame toView: self]; 
			
		// add the new one 
		NSTrackingRectTag trackingRect = [self addTrackingRect: cellFrameView owner: self userData: self assumeInside: NO]; 
		
		// remember the tag	
		[cell setTag: trackingRect]; 
	}
}

- (void) setSelectedColorLabel: (NSColor*) color {
	if ((color == nil) && (mDisplaysClearButton)) {
		[mColorLabels selectCell: [[mColorLabels cells] objectAtIndex: 0]]; 
		return; 
	}
	
	// we have to find the correct cell now 
	NSEnumerator*			cellIter	= [[mColorLabels cells] objectEnumerator]; 
	VTColorLabelButtonCell* cell		= nil; 
	
	while (cell = [cellIter nextObject]) {
		if ([[cell color] isEqual: color]) {
			[mColorLabels selectCell: cell]; 
			return; 
		}
	}
}

@end 

