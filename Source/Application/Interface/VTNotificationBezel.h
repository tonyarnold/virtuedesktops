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
#import "VTNotificationBezelView.h" 

@interface VTNotificationBezel : NSObject {
	NSWindow*					mWindow;		//!< The window to display 
	VTNotificationBezelView*	mView;			//!< The window content view 
	
	BOOL						mShowBezel; 
	float						mDuration; 
	NSTimer*					mTimer; 
}

#pragma mark -
#pragma mark Lifetime 

- (id) init; 
- (void) dealloc; 

#pragma mark -
#pragma mark Actions 

- (IBAction) showNotificationBezel: (id) sender; 

@end
