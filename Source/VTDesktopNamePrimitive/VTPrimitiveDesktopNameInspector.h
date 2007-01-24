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
#import "VTInspector.h" 

@interface VTPrimitiveDesktopNameInspector : VTInspector {
	// outlets 
	IBOutlet  NSTextField*  mTextField; 
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
