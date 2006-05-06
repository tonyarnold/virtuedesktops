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

@interface VTApplicationViewController : NSWindowController {
// outlets 
	IBOutlet NSArrayController* mApplicationsController; 
	IBOutlet NSArrayController* mWindowsController;  
}

#pragma mark -
#pragma mark Attributes 
- (NSArray*) availableDesktops;

#pragma mark -
#pragma mark Actions 
- (IBAction) toggleSelectedWindowStickyState: (id) sender; 
- (IBAction) removeApplication: (id) sender;

@end