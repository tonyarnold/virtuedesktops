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

#import <Cocoa/Cocoa.h>
#import "VTPositionGridCell.h" 

@interface VTPositionGrid : NSControl {
	NSMutableArray*	mTrackingRects; 
}

#pragma mark -
#pragma mark Lifetime 

- (id) initWithFrame: (NSRect) frame; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (void) setMarkers: (NSArray*) markers; 
- (NSArray*) markers; 

#pragma mark -
- (void) setSelectedMarker: (VTPositionGridMarker) marker; 
- (VTPositionGridMarker) selectedMarker; 
@end
