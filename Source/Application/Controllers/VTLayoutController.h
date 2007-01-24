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
#import "VTDesktopLayout.h" 

@interface VTLayoutController : NSObject {
	VTDesktopLayout*	mActiveLayout; 
	NSMutableArray*		mLayouts; 
}

#pragma mark -
#pragma mark Lifetime 

+ (VTLayoutController*) sharedInstance; 

#pragma mark -
#pragma mark Persistentcy 
- (void) synchronize; 

#pragma mark -
#pragma mark Attributes 

- (VTDesktopLayout*) activeLayout; 
- (void) setActiveLayout: (VTDesktopLayout*) layout; 

- (NSArray*) layouts; 
- (void) attachLayout: (VTDesktopLayout*) layout; 
- (void) detachLayout: (VTDesktopLayout*) layout; 

@end
