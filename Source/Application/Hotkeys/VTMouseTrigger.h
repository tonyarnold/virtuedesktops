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
#import "VTTrigger.h" 
#import "VTMouseWatcherProtocol.h" 
#import <Zen/ZNEdge.h> 

@interface VTMouseTrigger : VTTrigger<VTMouseWatcherProtocol> {
  int           mModifiers;			//!< Modifiers of the hotkey 
	unsigned int	mClickCount;		//!< Click count needed
	float         mDelay;         //!< Delay in ms. Only considered if mClickCount is 0
	ZNEdge        mEdge;          //!< The edge for our trigger 
	
	NSTimer*      mTimer; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) init; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (void) setEdge: (ZNEdge) edge; 
- (ZNEdge) edge; 

- (void) setDelay: (float) delay; 
- (float) delay; 

- (void) setModifiers: (int) modifiers; 
- (int) modifiers; 

- (void) resetOnScreenChanged: (id) sender;

@end
