/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2006, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTColorLabelButtonCell.h"
#import <Virtue/NSBezierPathPlate.h> 
#import <Virtue/NSImageTint.h> 
#import <Zen/Zen.h> 


@implementation VTColorLabelButtonCell

#pragma mark -
- (id) init {
	if (self = [super initImageCell: nil]) {
		mColor			= [[NSColor clearColor] retain]; 
		mMouseInside	= NO; 
		
		[self setType: VTColorLabelType];  
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mColor); 
	ZEN_RELEASE(mImage); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 
- (void) setColor: (NSColor*) color {
	ZEN_ASSIGN(mColor, color); 
}

- (NSColor*) color {
	return mColor; 
}

#pragma mark -
- (void) setSelected: (BOOL) flag {
	mSelected = flag; 
	[[self controlView] setNeedsDisplay: YES]; 
}

- (BOOL) isSelected {
	return mSelected; 
}

#pragma mark -
- (void) setLabelType: (VTColorLabelButtonType) type {
	mType = type; 
	
	// set image to display 
	ZEN_RELEASE(mImage); 
	if (mType == VTClearLabelType) 
		mImage = [[NSImage imageNamed: @"imageColorLabelClear.png"] retain]; 
	else
		mImage = [[NSImage imageNamed: @"imageColorLabelMaskComposite.png"] retain]; 
	
	[[self controlView] setNeedsDisplay: YES]; 
}

- (VTColorLabelButtonType) labelType {
	return mType; 
}


#pragma mark -
#pragma mark NSCell 
- (void) mouseEntered: (NSEvent*) event {
	mMouseInside = YES; 
	
	[[self controlView] setNeedsDisplay: YES]; 
}

- (void) mouseExited: (NSEvent*) event {
	mMouseInside = NO; 
	
	[[self controlView] setNeedsDisplay: YES]; 
}

#pragma mark -
- (NSSize) cellSize {
	return NSMakeSize(16, 16); 
}

#pragma mark -
#pragma mark Drawing 

- (void) drawWithFrame: (NSRect) cellFrame inView: (NSView*) controlView {
	if (([self state] == NSOffState) && (mMouseInside == NO)) {
		[[NSColor clearColor] set]; 
		[NSBezierPath fillRect: cellFrame]; 
		
		// and continue with innards
		[super drawWithFrame: cellFrame inView: controlView]; 	

		return; 
	}
	
	NSRect frame = cellFrame; 	
	frame.origin.x += 0.5; 
	frame.origin.y += 0.5; 
	frame.size.width -= 0.5; 
	frame.size.height -= 0.5; 
	NSBezierPath* backgroundPath = [NSBezierPath bezierPathForRoundedRect: frame withRadius: 3]; 

	// draw background 
	if (([self isHighlighted]) || ([self state] == NSOnState)) {
		if (mType == VTColorLabelType) 
			[[NSColor colorWithCalibratedWhite: 1.0 alpha: 1.0] set]; 
		else
			[[NSColor clearColor] set]; 
	}
	else
		[[NSColor colorWithCalibratedWhite: 0.8 alpha: 1.0] set];

	[backgroundPath fill]; 
	
	// draw border 
	if (([self isHighlighted]) || ([self state] == NSOnState)) {
		if (mType == VTColorLabelType) 
			[[NSColor colorWithCalibratedWhite: 0.8 alpha: 1.0] set]; 
		else
			[[NSColor clearColor] set]; 
	}
	else
		[[NSColor colorWithCalibratedWhite: 0.7 alpha: 1.0] set]; 
	
	[backgroundPath setLineWidth: 1]; 
	[backgroundPath stroke];
	
	// and continue with innards
	[super drawWithFrame: cellFrame inView: controlView]; 	
}

- (void) drawInteriorWithFrame: (NSRect) cellFrame inView: (NSView*) controlView {
	if (mType == VTClearLabelType) {
		NSPoint imagePosition = cellFrame.origin; 
		imagePosition.x += 3; 
		imagePosition.y += 3 + [mImage size].height; 
		
		[mImage compositeToPoint: imagePosition operation: NSCompositeSourceOver fraction: 1.0]; 
		
		return; 
	}
	
	NSRect			blobPathRect; 
	NSPoint			blobImagePosition; 
	blobPathRect.origin = NSMakePoint(cellFrame.origin.x + 3, cellFrame.origin.y + 3); 
	blobPathRect.size	= [mImage size]; 
	blobImagePosition	= NSMakePoint(blobPathRect.origin.x, blobPathRect.origin.y + [mImage size].height); 

	NSBezierPath* blobPath = [NSBezierPath bezierPathWithOvalInRect: blobPathRect]; 
		
	NSShadow* shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor: [mColor shadowWithLevel: 0.6]];
	[shadow setShadowBlurRadius: 1];
	[shadow setShadowOffset:NSMakeSize(1,-1)];
	
	[NSGraphicsContext saveGraphicsState]; 	
	[shadow set]; 
	// draw the blob
	[mColor set]; 
	[blobPath fill]; 
	[NSGraphicsContext restoreGraphicsState]; 
	
	// draw our specular highlight and border with shadow 
	[mImage dissolveToPoint: blobImagePosition fraction: 0.7]; 
}

@end
