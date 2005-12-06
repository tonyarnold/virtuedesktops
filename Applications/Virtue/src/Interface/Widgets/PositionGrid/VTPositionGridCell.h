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

typedef enum {
	VTPositionMarkerNone		= -1,
	VTPositionMarkerTopLeft		=  0,
	VTPositionMarkerLeft		=  1,
	VTPositionMarkerBottomLeft	=  2,
	VTPositionMarkerBottom		=  3,
	VTPositionMarkerBottomRight	=  4,
	VTPositionMarkerRight		=  5,
	VTPositionMarkerTopRight	=  6,
	VTPositionMarkerTop			=  7, 
} VTPositionGridMarker; 

@interface VTPositionGridCell : NSActionCell {
	NSMutableArray* mMarkers; 
	NSButtonCell*	mHighlightedMarker; 
}

#pragma mark -
- (id) init; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 

- (void) setMarkers: (NSArray*) markers; 
- (NSArray*) markers; 

#pragma mark -
- (VTPositionGridMarker) selectedMarker; 
- (void) setSelectedMarker: (VTPositionGridMarker) marker; 

@end
