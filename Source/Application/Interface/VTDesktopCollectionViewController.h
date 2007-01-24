/******************************************************************************
* 
* VirtueDesktops 
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
#import "VTDesktop.h"

@interface VTDesktopCollectionViewController : NSWindowController {
	// outlets 
	IBOutlet NSArrayController* mCollectionController; 
	IBOutlet NSOutlineView*		mCollectionOutline; 
	
	NSToolbar*					mToolbar;
	NSMutableDictionary*		mToolbarItems; 
	
	NSMutableDictionary*		mApplicationCache; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) init; 
- (void) dealloc; 

@end
