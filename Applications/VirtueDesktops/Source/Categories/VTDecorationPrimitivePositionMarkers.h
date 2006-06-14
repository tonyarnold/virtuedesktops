/******************************************************************************
* 
* Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2006, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import <Cocoa/Cocoa.h>
#import <Virtue/VTDecorationPrimitive.h> 
#import "../Interface/Widgets/Position Grid/VTPositionGrid.h" 

@interface VTDecorationPrimitive(VTPositionMarkers)

- (NSArray*) supportedMarkers; 
#pragma mark -
- (VTPositionGridMarker) markerPosition; 
- (void) setMarkerPosition: (VTPositionGridMarker) marker; 
#pragma mark -
- (VTPositionGridMarker) markerForPosition: (VTDecorationPosition) position; 
- (VTDecorationPosition) positionForMarker: (VTPositionGridMarker) marker; 
#pragma mark -


@end
