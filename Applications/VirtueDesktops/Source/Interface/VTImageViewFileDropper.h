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


@interface VTImageViewFileDropper : NSImageView {
	NSString*	mPath; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) init; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (void) setImagePath: (NSString*) path; 
- (NSString*) imagePath; 

@end
