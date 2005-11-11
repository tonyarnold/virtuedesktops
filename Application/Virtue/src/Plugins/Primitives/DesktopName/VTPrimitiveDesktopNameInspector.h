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
#import <Virtue/VTInspector.h> 

@interface VTPrimitiveDesktopNameInspector : VTInspector {
	// outlets 
	IBOutlet NSTextField*	mFontTextField; 
	// ivar 
	NSResponder*			mPreviousResponder; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) init; 

#pragma mark -
#pragma mark Actions 
- (IBAction) showFontPanel: (id) sender; 

@end
