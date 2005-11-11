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
#import <Virtue/VTDesktopLayout.h>
#import <Virtue/VTDesktop.h>
#import <Virtue/VTPager.h>
#import <Virtue/VTCoding.h> 

@interface VTMatrixDesktopLayout : VTDesktopLayout<VTCoding> {
	unsigned int	mRows; 
	unsigned int	mColumns; 
	
	BOOL			mBindColumnsToRows; 
	BOOL			mWraps;
	BOOL			mJumpsGaps; 
	BOOL			mCompacted; 
	BOOL			mContinous; 
	
	NSObject<VTPager>*	mPager; 
	NSMutableArray*		mDesktopLayout; 
}

#pragma mark -
#pragma mark Lifetime 

- (id) init; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (NSObject<VTPager>*) pager;

#pragma mark -
- (unsigned int) numberOfRows; 
- (unsigned int) numberOfDisplayedRows; 
- (void) setNumberOfRows: (unsigned int) rows; 

#pragma mark -
- (unsigned int) numberOfColumns; 
- (unsigned int) numberOfDisplayedColumns; 
- (void) setNumberOfColumns: (unsigned int) cols; 

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
- (NSArray*) desktopLayout; 
- (void) swapDesktopAtIndex: (unsigned int) index withIndex: (unsigned int) otherIndex;

#pragma mark -
#pragma mark VTDesktopLayout implementation 
- (VTDesktop*) desktopInDirection: (VTDirection) direction ofDesktop: (VTDesktop*) desktop; 
- (VTDirection) directionFromDesktop: (VTDesktop*) referenceDesktop toDesktop: (VTDesktop*) desktop; 

@end
