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


@interface VTInspector : NSResponder {
	IBOutlet NSWindow*	mWindow; 
	
	NSView*		mMainView; 
	NSObject*	mInspectedObject; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) init; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (void) setInspectedObject: (NSObject*) object; 
- (NSObject*) inspectedObject; 

#pragma mark -
- (NSView*) mainView; 

#pragma mark -
- (NSWindow*) window; 

#pragma mark -
#pragma mark Delegate type methods 
- (void) didSelect; 
- (void) didUnselect; 

@end
