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

#import "VTDecorationPrimitivePositionMarkers.h"


#pragma mark -
@implementation VTDecorationPrimitive(VTPositionMarkers)

- (NSArray*) supportedMarkers {
	NSEnumerator*	positionIter	= [[self supportedPositionTypes] objectEnumerator]; 
	NSNumber*		positionType		= nil; 
	
	NSMutableArray*	markers			= [NSMutableArray array]; 
	
	while (positionType = [positionIter nextObject]) {
		if ([positionType intValue] != kVtDecorationPositionAbsolute) 
			[markers addObject: [NSNumber numberWithInt: [self markerForPosition: [positionType intValue]]]]; 
	}
	
	return markers; 
}

- (VTPositionGridMarker) markerPosition {
	return [self markerForPosition: [self positionType]]; 
}

- (void) setMarkerPosition: (VTPositionGridMarker) marker {
	[self setPositionType: [self positionForMarker: marker]]; 
}

- (VTDecorationPosition) positionForMarker: (VTPositionGridMarker) marker {
	switch (marker) {
		case VTPositionMarkerTop: 
			return kVtDecorationPositionTop; 
		case VTPositionMarkerBottom: 
			return kVtDecorationPositionBottom; 
		case VTPositionMarkerLeft: 
			return kVtDecorationPositionLeft; 
		case VTPositionMarkerRight: 
			return kVtDecorationPositionRight; 
		case VTPositionMarkerTopLeft: 
			return kVtDecorationPositionTL; 
		case VTPositionMarkerTopRight: 
			return kVtDecorationPositionTR; 
		case VTPositionMarkerBottomLeft: 
			return kVtDecorationPositionLL; 
		case VTPositionMarkerBottomRight: 
			return kVtDecorationPositionLR;
    case VTPositionMarkerCenter:
      return kVtDecorationPositionCenter;
	}; 
	
	// interpret none of the above as an absolute position 
	return kVtDecorationPositionAbsolute; 
}

- (VTPositionGridMarker) markerForPosition: (VTDecorationPosition) position {
	switch (position) {
		case kVtDecorationPositionTop: 
			return VTPositionMarkerTop; 
		case kVtDecorationPositionBottom: 
			return VTPositionMarkerBottom; 
		case kVtDecorationPositionLeft: 
			return VTPositionMarkerLeft; 
		case kVtDecorationPositionRight: 
			return VTPositionMarkerRight; 
		case kVtDecorationPositionTL: 
			return VTPositionMarkerTopLeft; 
		case kVtDecorationPositionTR: 
			return VTPositionMarkerTopRight; 
		case kVtDecorationPositionLL: 
			return VTPositionMarkerBottomLeft; 
		case kVtDecorationPositionLR: 
			return VTPositionMarkerBottomRight;
    case kVtDecorationPositionCenter:
      return VTPositionMarkerCenter;
	}
	
	// interpret none of the above as no marker 
	return VTPositionMarkerNone; 
}

@end 