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
#import "CGSPrivate.h" 
#import "PNWindow.h" 


@interface PNWindowPool : NSObject 
{
	NSMutableDictionary*	mWindows; 
}

#pragma mark Lifetime 
+ (id) sharedWindowPool;

#pragma mark Operations  
- (PNWindow*) windowWithId: (CGSWindow) windowId; 

@end
