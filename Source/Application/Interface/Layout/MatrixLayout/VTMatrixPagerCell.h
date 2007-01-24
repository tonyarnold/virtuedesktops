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
#import "VTDesktop.h"
#import "VTDesktopController.h"

@interface VTMatrixPagerCell : NSActionCell {
	// attributes 
	VTDesktop*				mDesktop; 
	BOOL					mDrawsApplets;
	BOOL					mDrawsColorLabels; 
	BOOL					mDrawsWithoutDesktop; 
	BOOL					mDraggingTarget; 
	// cached values 
	NSMutableDictionary*	mDesktopNameAttributes;
	// cached colors 
	NSColor*				mDesktopBackgroundColor;			//!< Desktop background 
	NSColor*				mDesktopBackgroundHighlightColor;	//!< Desktop background when highlighted 
	NSColor*				mWindowColor;						//!< Window background 
	NSColor*				mWindowBorderColor;					//!< Window border 
	NSColor*				mWindowHighlightColor;				//!< Window background when highlighted 
	NSColor*				mWindowBorderHighlightColor;		//!< Window border when highlighted 
	NSColor*				mBorderColor;						//!< Border
	NSColor*				mBackgroundColor;					//!< Background 
	NSColor*				mBackgroundHighlightColor;			//!< Background when highlighted 
	// subcells 
	NSMutableArray*			mAppletCells; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) init; 
- (id) initWithDesktop: (VTDesktop*) desktop; 

#pragma mark -
#pragma mark Attributes 
- (void) setDesktop: (VTDesktop*) desktop; 
- (VTDesktop*) desktop; 
#pragma mark -
- (void) setDraggingTarget: (BOOL) flag; 
- (BOOL) isDraggingTarget; 

#pragma mark -
- (void) setDisplaysApplicationIcons: (BOOL) flag; 
- (BOOL) displaysApplicationIcons; 
#pragma mark -
- (void) setDisplaysColorLabels: (BOOL) flag; 
- (BOOL) displaysColorLabels; 
#pragma mark -
- (void) setDrawsWithoutDesktop: (BOOL) flag; 
- (BOOL) drawsWithoutDesktop; 

#pragma mark -
- (void) setTextColor: (NSColor*) color; 
- (void) setBackgroundColor: (NSColor*) color; 
- (void) setBackgroundHighlightColor: (NSColor*) color; 
- (void) setWindowColor: (NSColor*) color; 
- (void) setWindowHighlightColor: (NSColor*) color; 

#pragma mark -
#pragma mark Operations 
- (NSImage*) drawToImage; 

@end
