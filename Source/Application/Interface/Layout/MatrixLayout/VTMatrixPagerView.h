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
#import "VTMatrixDesktopLayout.h" 
#import "VTMatrixPagerCell.h" 

@interface VTMatrixPagerView : NSView {
	NSColor*		mBackgroundColor;
	NSColor*		mBackgroundHighlightColor; 
	NSColor*		mWindowColor; 
	NSColor*		mWindowHighlightColor; 
	NSColor*		mTextColor; 
	
	BOOL			mDisplaysColorLabels; 
	BOOL			mDisplaysApplicationIcons;
	BOOL			mDraggable;
	
	NSMatrix*				mPagerCells;
	NSMutableArray*	mTrackingRects; 
	
	VTMatrixPagerCell*			mCurrentDraggingTarget; 
	VTMatrixDesktopLayout*	mLayout; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) initWithFrame: (NSRect) frame forLayout: (VTMatrixDesktopLayout*) layout; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (void) setSelectedDesktop: (VTDesktop*) desktop; 
- (VTDesktop*) selectedDesktop; 

#pragma mark -
- (NSMatrix*) desktopCollectionMatrix; 

#pragma mark -
- (void) setDisplaysApplicationIcons: (BOOL) flag; 
- (BOOL) displaysApplicationIcons; 
- (void) setDisplaysColorLabels: (BOOL) flag; 
- (BOOL) displaysColorLabels; 

#pragma mark -
- (void) setTextColor: (NSColor*) color; 
- (NSColor*) textColor; 
- (void) setBackgroundColor: (NSColor*) color; 
- (NSColor*) backgroundColor; 
- (void) setBackgroundHighlightColor: (NSColor*) color; 
- (NSColor*) backgroundHighlightColor; 
- (void) setWindowColor: (NSColor*) color; 
- (NSColor*) windowColor; 
- (void) setWindowHighlightColor: (NSColor*) color; 
- (NSColor*) windowHighlightColor; 

@end
