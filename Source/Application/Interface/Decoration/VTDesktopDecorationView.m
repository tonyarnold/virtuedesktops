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

#import "VTDesktopDecorationView.h"
#import <Zen/ZNMemoryManagementMacros.h> 

@implementation VTDesktopDecorationView

#pragma mark -
#pragma mark Lifetime 

- (id) initWithFrame: (NSRect) aRect withDecoration: (VTDesktopDecoration*) aDecoration {
	if (self = [super initWithFrame: aRect]) {
		// attributes 
		ZEN_ASSIGN(mDecoration, aDecoration); 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mDecoration); 
	[super dealloc];
}

#pragma mark -
#pragma mark NSView  

- (BOOL) isOpaque { 
	return NO; 
}

- (BOOL) isFlipped { 
	return NO; 
}

#pragma mark -
#pragma mark Drawing 

- (void) drawRect: (NSRect) aRect {
	if (mDecoration == nil) 
		return; 
	
	// just forward drawing to the decoration container object 
	[mDecoration drawInView: self withRect: aRect]; 
}


@end
