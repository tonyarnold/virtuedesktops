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
#import "VTDesktopLayout.h"
#import "VTDesktop.h"
#import "VTPager.h"
#import "VTCoding.h" 

@interface VTMatrixDesktopLayout : VTDesktopLayout<VTCoding> {
	unsigned int	mRows; 
	unsigned int	mColumns;
	
	BOOL			mBindColumnsToRows; 
	BOOL			mWraps;
	BOOL			mJumpsGaps; 
	BOOL			mCompacted; 
	BOOL			mContinous; 
	BOOL			mDraggable;
	
  
  NSObject<VTPager>*  mMatrixPager;
  NSObject<VTPager>*  mWindowPager;
  
	NSObject<VTPager>*	mPager; 
  NSArray*            mPagers;
	NSMutableArray*     mDesktopLayout; 
}

#pragma mark -
#pragma mark Lifetime 

- (id) init; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (void) setPager: (NSObject<VTPager>*) newPager;
- (NSObject<VTPager>*) pager;
- (NSArray*) availablePagers;

#pragma mark -
- (unsigned int) numberOfRows; 
- (unsigned int) numberOfDisplayedRows; 
- (void) setNumberOfRows: (unsigned int) rows; 

#pragma mark -
- (unsigned int) numberOfColumns; 
- (unsigned int) numberOfDisplayedColumns; 
- (void) setNumberOfColumns: (unsigned int) cols; 

#pragma mark -
- (unsigned int) maximumNumberOfDesktops;

#pragma mark -
- (BOOL) bindsNumberOfColumnsToRows; 
- (void) setBindsNumberOfColumnsToRows: (BOOL) flag; 

#pragma mark -
- (BOOL) isCompacted; 
- (void) setCompacted: (BOOL) flag; 

#pragma mark -
- (BOOL) isWrapping; 
- (void) setWrapping: (BOOL) flag; 

#pragma mark -
- (BOOL) isJumpingGaps; 
- (void) setJumpingGaps: (BOOL) flag; 

#pragma mark -
- (BOOL) isContinous; 
- (void) setContinous: (BOOL) flag; 

#pragma mark -
- (BOOL) isDraggable; 
- (void) setDraggable: (BOOL) flag; 

#pragma mark -
- (NSArray*) desktopLayout; 
- (void) swapDesktopAtIndex: (unsigned int) index withIndex: (unsigned int) otherIndex;
- (void) moveDesktopAtIndex: (unsigned int) index toIndex: (unsigned int) newIndex;

#pragma mark -
#pragma mark VTDesktopLayout implementation 
- (VTDesktop*) desktopInDirection: (VTDirection) direction ofDesktop: (VTDesktop*) desktop; 
- (VTDirection) directionFromDesktop: (VTDesktop*) referenceDesktop toDesktop: (VTDesktop*) desktop; 

@end
