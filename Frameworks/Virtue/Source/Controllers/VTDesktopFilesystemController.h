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
#import "VTDesktop.h" 


@interface VTDesktopFilesystemController : NSObject {
	// watched desktops indexed by their original paths 
	NSMutableDictionary* mWatchers; 
}

#pragma mark -
#pragma mark Lifetime 
+ (VTDesktopFilesystemController*) sharedInstance; 

#pragma mark -
#pragma mark Persistency control 
+ (void) createVirtualDesktopContainer; 

@end
