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

#import "VTPositionGrid.h"
#import <Zen/Zen.h> 

@interface VTPositionGrid(Private) 
- (void) resetTrackingRects; 
@end 

#pragma mark -
@implementation VTPositionGrid

#pragma mark -
#pragma mark Information

+ (Class) cellClass {
	return [VTPositionGridCell class]; 
}

#pragma mark -
#pragma mark Lifetime 

- (id) initWithFrame: (NSRect) frame {
	if (self = [super initWithFrame: frame]) {
		// tracking rects 
		mTrackingRects = [[NSMutableArray alloc] init]; 
		
		// set cell 
		VTPositionGridCell* cell = [[[VTPositionGridCell alloc] init] autorelease]; 
		[self setCell: cell]; 
		
		return self; 
	}

	return nil; 
}

- (void) dealloc {
	while ([mTrackingRects count] > 0) 
		[self removeTrackingRect: [[mTrackingRects objectAtIndex: 0] intValue]]; 
	ZEN_RELEASE(mTrackingRects); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Bindings 
- (NSArray*) exposedBindings {
	return [NSArray arrayWithObjects: @"markers", nil]; 
}

#pragma mark -
#pragma mark Attributes 
- (void) setMarkers: (NSArray*) markers {
	[[self cell] setMarkers: markers]; 
	[self setNeedsDisplay: YES]; 
}

- (NSArray*) markers {
	return [[self cell] markers]; 
}

#pragma mark -
- (void) setSelectedMarker: (VTPositionGridMarker) marker {
	[[self cell] setSelectedMarker: marker]; 
	[self setNeedsDisplay: YES]; 
}

- (VTPositionGridMarker) selectedMarker {
	return [[self cell] selectedMarker]; 
}

@end

#pragma mark -
@implementation VTPositionGrid(Private) 

- (void) resetTrackingRects {
	// remove all tracking rects 
	while ([mTrackingRects count] > 0) 
		[self removeTrackingRect: [[mTrackingRects objectAtIndex: 0] intValue]]; 
	[mTrackingRects removeAllObjects]; 
}

@end 