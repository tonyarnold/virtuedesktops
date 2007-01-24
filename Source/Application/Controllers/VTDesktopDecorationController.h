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
#import "VTDesktop.h"

@interface VTDesktopDecorationController : NSObject {
	NSMutableDictionary*	mWindows;							// Windows indexed by desktop id 
	NSMutableDictionary*	mDecorations;					// Decorations indexed by desktop id 
	int										mDesktopWindowLevel;	// The desktop window level 
}

#pragma mark -
#pragma mark Lifetime 

+ (VTDesktopDecorationController*) sharedInstance; 

#pragma mark -
#pragma mark Attributes 

- (NSArray*) decorations; 
- (VTDesktopDecoration*) decorationForDesktop: (VTDesktop*) desktop; 

#pragma mark -
- (void) setDesktopWindowLevel: (int) level; 
- (int) desktopWindowLevel; 

#pragma mark -
#pragma mark Operations 

- (void) hide; 
- (void) show; 
- (void) attachDecoration: (VTDesktopDecoration*) decoration; 
- (void) detachDecorationForDesktop: (VTDesktop*) desktop; 

@end
