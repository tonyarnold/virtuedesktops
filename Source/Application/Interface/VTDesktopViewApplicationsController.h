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
#import <Virtue/VTDesktop.h>

@interface VTDesktopViewApplicationsController : NSObject {
// outlets 
	IBOutlet NSOutlineView*		mApplicationView; 
	IBOutlet NSButton*			mStickyButton; 
// ivars 
	VTDesktop*	mDesktop; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) init; 

#pragma mark -
#pragma mark Attributes 
- (void) setDesktop: (VTDesktop*) desktop; 

#pragma mark -
#pragma mark Actions 
- (IBAction) toggleSticky: (id) sender; 


@end
