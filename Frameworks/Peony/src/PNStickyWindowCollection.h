/******************************************************************************
* 
* Peony.Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import <Foundation/Foundation.h>
#import "PNWindow.h" 
#import "PNWindowList.h" 

@interface PNStickyWindowCollection : NSObject 
{
	PNWindowList* mWindows; 
}

#pragma mark Lifetime 

+ (id) stickyWindowCollection; 

#pragma mark Operations 

- (void) addWindow: (PNWindow*) window; 
- (void) delWindow: (PNWindow*) window; 

#pragma mark Accessors 

- (NSArray*) windows; 

@end
