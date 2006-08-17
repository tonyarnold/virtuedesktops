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

#import "VTDesktopDecoration.h" 

@interface VTDesktopDecorationView : NSView {
	VTDesktopDecoration*	mDecoration; 
}

#pragma mark -
#pragma mark Lifetime 

- (id) initWithFrame: (NSRect) aRect withDecoration: (VTDesktopDecoration*) aDecoration; 

@end
