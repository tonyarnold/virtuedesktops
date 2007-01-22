//
//  PNStickyWindowCollection.h
//  Peony framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

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
