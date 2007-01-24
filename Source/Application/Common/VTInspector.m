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

#import "VTInspector.h"
#import <Zen/Zen.h> 


@implementation VTInspector

#pragma mark -
#pragma mark Lifetime 
- (id) init {
	if (self = [super init]) {
		mMainView = nil; 
		
		// TODO: Place your nib loading code here and assign mMainView
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 
- (void) setInspectedObject: (NSObject*) object {
	ZEN_ASSIGN(mInspectedObject, object); 
}

- (NSObject*) inspectedObject {
	return mInspectedObject; 
}

#pragma mark -
- (NSView*) mainView { 
	return mMainView; 
}

#pragma mark -
- (NSWindow*) window {
	return mWindow; 
}

#pragma mark -
#pragma mark Delegate type methods 
- (void) didSelect {
}

- (void) didUnselect {
}


@end
