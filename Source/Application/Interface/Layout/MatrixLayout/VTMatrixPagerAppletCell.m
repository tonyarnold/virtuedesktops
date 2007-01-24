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

#import "VTMatrixPagerAppletCell.h"
#import "NSBezierPathPlate.h"
#import <Zen/Zen.h> 

#pragma mark -
@implementation VTMatrixPagerAppletCell

#pragma mark -
#pragma mark Lifetime 
- (id) init {
	return [self initWithApplication: nil]; 
}

- (id) initWithApplication: (PNApplication*) application {
	if (self = [super initImageCell: nil]) {
		// and set the image 
		[self setApplication: application]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
  ZEN_RELEASE(mApplication);
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 
- (PNApplication*) application {
	return mApplication; 
}

- (void) setApplication: (PNApplication*) application {
	ZEN_ASSIGN(mApplication, application);
  
	[self setImage: [mApplication icon]]; 
	[[self controlView] setNeedsDisplay: YES]; 
}

#pragma mark -
#pragma mark NSCell 
- (NSSize) cellSize {
	if (mApplication == nil)
		return NSZeroSize; 
	
	return NSMakeSize(16, 16); 
}

- (void) drawWithFrame: (NSRect) cellFrame inView: (NSView*) controlView {
	if (([self state] == NSOffState) /* && (mMouseInside == NO) */) {
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
	if (([self isHighlighted]) || ([self state] == NSOnState))
		[[NSColor colorWithCalibratedWhite: 1.0 alpha: 1.0] set]; 
	else
		[[NSColor clearColor] set];
	
	[backgroundPath fill]; 
	
	// draw border 
	if (([self isHighlighted]) || ([self state] == NSOnState))
		[[NSColor colorWithCalibratedWhite: 0.8 alpha: 1.0] set]; 
	else
		[[NSColor clearColor] set]; 
	
	[backgroundPath setLineWidth: 1]; 
	[backgroundPath stroke];
	
	// and continue with innards
	[super drawWithFrame: cellFrame inView: controlView];
}

- (void) drawInteriorWithFrame: (NSRect) cellFrame inView: (NSView*) controlView {
	[super drawInteriorWithFrame: cellFrame inView: controlView]; 
}


@end
