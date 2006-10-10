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
#import "VTMouseWatcherProtocol.h" 
#import <Zen/ZNEdge.h> 


@interface VTMouseWatcher : NSObject<VTMouseWatcherProtocol> {
	NSMutableDictionary*	mWindows;
	NSMutableDictionary*	mObservers;
	NSMutableDictionary*	mTrackingRects; 
	
	ZNEdge					mCurrentEdge; 
}

#pragma mark -
#pragma mark Instance 

+ (id) sharedInstance; 

#pragma mark -
#pragma mark Operations 

- (void) addObserver: (NSObject<VTMouseWatcherProtocol>*) observer forEdge: (ZNEdge) edge; 
- (void) removeObserver: (NSObject*) observer forEdge: (ZNEdge) edge; 
- (void) removeObserver: (NSObject*) observer; 


@end
