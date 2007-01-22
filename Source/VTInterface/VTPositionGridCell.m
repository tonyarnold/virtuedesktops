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

#import "VTPositionGridCell.h"
#import <Zen/Zen.h> 

#define kCellSizeCorner			20
#define kCellSizeHeight			20
#define kCellSizeSpacer			6
#define kCellSizeWidth(total)	(total - 2 * kCellSizeHeight - 2 * kCellSizeSpacer)

#define kTopPosition(cellFrame) \
  NSMakeRect(cellFrame.origin.x + (cellFrame.size.width - kCellSizeWidth(cellFrame.size.width)) / 2.0, cellFrame.origin.y + (cellFrame.size.height - kCellSizeHeight), kCellSizeWidth(cellFrame.size.width), kCellSizeHeight)
#define kTopLeftPosition(cellFrame) \
  NSMakeRect(cellFrame.origin.x, cellFrame.origin.y + cellFrame.size.height - kCellSizeHeight, kCellSizeHeight, kCellSizeHeight)
#define kLeftPosition(cellFrame) \
  NSMakeRect(cellFrame.origin.x, cellFrame.origin.y + (cellFrame.size.height - kCellSizeWidth(cellFrame.size.height)) / 2.0, kCellSizeHeight, kCellSizeWidth(cellFrame.size.height))
#define kBottomLeftPosition(cellFrame) \
  NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, kCellSizeHeight, kCellSizeHeight)
#define kBottomPosition(cellFrame) \
  NSMakeRect(cellFrame.origin.x + (cellFrame.size.width - kCellSizeWidth(cellFrame.size.width)) / 2.0, cellFrame.origin.y, kCellSizeWidth(cellFrame.size.width), kCellSizeHeight)
#define kBottomRightPosition(cellFrame) \
  NSMakeRect(cellFrame.origin.x + (cellFrame.size.width - kCellSizeHeight), cellFrame.origin.y, kCellSizeHeight, kCellSizeHeight)
#define kRightPosition(cellFrame) \
  NSMakeRect(cellFrame.origin.x + (cellFrame.size.width - kCellSizeHeight), cellFrame.origin.y + (cellFrame.size.height - kCellSizeWidth(cellFrame.size.height)) / 2.0, kCellSizeHeight, kCellSizeWidth(cellFrame.size.height))
#define kTopRightPosition(cellFrame) \
  NSMakeRect(cellFrame.origin.x + (cellFrame.size.width - kCellSizeHeight), cellFrame.origin.y + cellFrame.size.height - kCellSizeHeight, kCellSizeHeight, kCellSizeHeight)
#define kCenterPosition(cellFrame) \
  NSMakeRect(cellFrame.origin.x + (cellFrame.size.width - kCellSizeWidth(cellFrame.size.width)) / 2.0, cellFrame.origin.y + (cellFrame.size.height - kCellSizeWidth(cellFrame.size.height)) / 2.0, kCellSizeWidth(cellFrame.size.width), kCellSizeHeight)

#pragma mark -
@interface VTPositionGridCell (Private) 
- (NSButtonCell*) selectedCell; 
- (void) selectCellWithTag: (int) tag; 
@end 

#pragma mark -
@implementation VTPositionGridCell

#pragma mark -
- (id) init {
	if (self = [super initImageCell: [NSImage imageNamed: @"imagePosition.png"]]) {
		mMarkers = [[NSMutableArray alloc] init]; 
		mHighlightedMarker = nil; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mMarkers); 
	ZEN_RELEASE(mHighlightedMarker); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 

- (void) setMarkers: (NSArray*) markers {
	[mMarkers removeAllObjects]; 
	
	// build subcells 
	NSEnumerator*	markerIter	= [markers objectEnumerator]; 
	NSNumber*		marker		= nil; 
	
	while (marker = [markerIter nextObject]) {
		// create our button cell 
		NSButtonCell* markerCell = [[[NSButtonCell alloc] initImageCell: nil] autorelease]; 
		
		// set up
		[markerCell setBordered: YES]; 
		[markerCell setBezelStyle: NSRegularSquareBezelStyle]; 
		[markerCell setButtonType: NSOnOffButton]; 
		
		[markerCell setTag: [marker intValue]]; 
		[markerCell setTarget: self]; 
		[markerCell setAction: @selector(onMarkerClicked:)];
		
		[mMarkers addObject: markerCell]; 
	}
}

- (NSArray*) markers {
	NSMutableArray* markers = [NSMutableArray array]; 
	
	NSEnumerator*	markerIter	= [mMarkers objectEnumerator]; 
	NSButtonCell*	marker		= nil; 
	
	while (marker = [markerIter nextObject]) {
		[markers addObject: [NSNumber numberWithInt: [marker tag]]]; 
	}
	
	return markers; 
}

#pragma mark -
- (VTPositionGridMarker) selectedMarker {
	NSCell* selectedCell = [self selectedCell]; 
	
	if (selectedCell == nil) 
		return VTPositionMarkerNone; 
	
	return [selectedCell tag]; 
}

- (void) setSelectedMarker: (VTPositionGridMarker) marker {
	[self selectCellWithTag: marker]; 
}

#pragma mark -
#pragma mark NSCell 

- (void) highlight: (BOOL) flag withFrame: (NSRect) cellFrame inView: (NSView*) controlView {
	// check if we have a highlighted button, and if we have, give it a chance 
	// to unhighlight
	if (mHighlightedMarker) {
		[mHighlightedMarker highlight: flag withFrame: cellFrame inView: controlView]; 
		ZEN_RELEASE(mHighlightedMarker); 
	}
}

- (BOOL) trackMouse: (NSEvent*) theEvent inRect: (NSRect) cellFrame ofView: (NSView*) controlView untilMouseUp: (BOOL) flag {
	NSPoint	locationInCell;
	
	// fetch the location of the mouse event 
	locationInCell = [theEvent locationInWindow];
	locationInCell = [controlView convertPoint: locationInCell fromView: nil];
	
	// now draw all our subcells 
	NSEnumerator*	markerIter	= [mMarkers objectEnumerator]; 
	NSButtonCell*	marker		= nil; 
	
	while (marker = [markerIter nextObject]) {
		// we have to figure out the frame we have to draw our cell in according
		// to its set tag indicating the position it represents 
		NSRect subcellFrame; 
		
		switch ([marker tag]) {
			case VTPositionMarkerTop: 
				subcellFrame = kTopPosition(cellFrame);  
				break;
			case VTPositionMarkerTopLeft: 
				subcellFrame = kTopLeftPosition(cellFrame); 
				break; 
			case VTPositionMarkerLeft: 
				subcellFrame = kLeftPosition(cellFrame); 
				break; 
			case VTPositionMarkerBottomLeft: 
				subcellFrame = kBottomLeftPosition(cellFrame); 
				break; 
			case VTPositionMarkerBottom: 
				subcellFrame = kBottomPosition(cellFrame); 
				break; 
			case VTPositionMarkerBottomRight: 
				subcellFrame = kBottomRightPosition(cellFrame); 
				break; 
			case VTPositionMarkerRight: 
				subcellFrame = kRightPosition(cellFrame); 
				break; 
			case VTPositionMarkerTopRight: 
				subcellFrame = kTopRightPosition(cellFrame); 
				break; 
      case VTPositionMarkerCenter:
        subcellFrame = kCenterPosition(cellFrame);
        break;
		}
		
		if (NSMouseInRect(locationInCell, subcellFrame, FALSE)) {
			if ([self selectedCell] == marker) 
				return [super trackMouse: theEvent inRect: cellFrame ofView: controlView untilMouseUp: flag];
			
			[[self selectedCell] setState: NSOffState]; 
			
			ZEN_ASSIGN(mHighlightedMarker, marker); 
			[mHighlightedMarker highlight: YES withFrame: subcellFrame inView: controlView]; 
			return [mHighlightedMarker trackMouse: theEvent inRect: subcellFrame ofView: controlView untilMouseUp: flag]; 
		}
	}
	
	return [super trackMouse: theEvent inRect: cellFrame ofView: controlView untilMouseUp: flag];
}

- (void) setEnabled: (BOOL) flag {
	NSEnumerator*	markerIter	= [mMarkers objectEnumerator]; 
	NSButton*     marker      = nil; 
	
	while (marker = [markerIter nextObject]) {
		[marker setEnabled: flag]; 
	}
  
	[super setEnabled: flag]; 
}

#pragma mark -
#pragma mark Drawing 

- (void) drawWithFrame: (NSRect) cellFrame inView: (NSView*) controlView {
	[super drawWithFrame: cellFrame inView: controlView]; 
	
	// now draw all our subcells 
	NSEnumerator*	markerIter	= [mMarkers objectEnumerator]; 
	NSButtonCell*	marker		= nil; 
	
	while (marker = [markerIter nextObject]) {
		// we have to figure out the frame we have to draw our cell in according
		// to its set tag indicating the position it represents 
		NSRect subcellFrame; 
		
		switch ([marker tag]) {
			case VTPositionMarkerTop: 
				subcellFrame = kTopPosition(cellFrame);  
				break;
			case VTPositionMarkerTopLeft: 
				subcellFrame = kTopLeftPosition(cellFrame); 
				break; 
			case VTPositionMarkerLeft: 
				subcellFrame = kLeftPosition(cellFrame); 
				break; 
			case VTPositionMarkerBottomLeft: 
				subcellFrame = kBottomLeftPosition(cellFrame); 
				break; 
			case VTPositionMarkerBottom: 
				subcellFrame = kBottomPosition(cellFrame); 
				break; 
			case VTPositionMarkerBottomRight: 
				subcellFrame = kBottomRightPosition(cellFrame); 
				break; 
			case VTPositionMarkerRight: 
				subcellFrame = kRightPosition(cellFrame); 
				break; 
			case VTPositionMarkerTopRight: 
				subcellFrame = kTopRightPosition(cellFrame); 
				break; 
      case VTPositionMarkerCenter:
        subcellFrame = kCenterPosition(cellFrame);
        break;
		}
	
		[marker drawWithFrame: subcellFrame inView: controlView]; 
	}
}


#pragma mark -
#pragma mark Actions 
- (void) onMarkerClicked: (id) sender {
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
@implementation VTPositionGridCell (Private) 

- (NSButtonCell*) selectedCell {
	NSEnumerator*	cellIter	= [mMarkers objectEnumerator]; 
	NSButtonCell*	cell		= nil; 
	
	while (cell = [cellIter nextObject]) {
		if ([cell state] == NSOnState) 
			return cell; 
	}
	
	return nil; 
}

- (void) selectCellWithTag: (int) tag {
	if (tag == VTPositionMarkerNone) {
		[[self selectedCell] setState: NSOffState]; 
		return; 
	}
	
	NSEnumerator*	cellIter	= [mMarkers objectEnumerator]; 
	NSButtonCell*	cell			= nil; 
	
	while (cell = [cellIter nextObject]) {
		if ([cell tag] == tag) {
			[[self selectedCell] setState: NSOffState]; 
			[cell setState: NSOnState]; 
			
			return; 
		}	
	}
	
	// If we get to here, we do not have a cell that was selected by another cell, so we will deselect the previously selected cell 
	if ([self selectedCell]) {
		[[self selectedCell] setState: NSOffState]; 
	}
}


@end 
