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
#import <Peony/Peony.h> 

@interface VTMatrixPagerAppletCell : NSImageCell {
	PNApplication* mApplication; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) init; 
- (id) initWithApplication: (PNApplication*) application; 

#pragma mark -
#pragma mark Attributes 
- (PNApplication*) application; 
- (void) setApplication: (PNApplication*) application; 

@end
