//
//  PNDesktopItem.h
//  Peony framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import <Cocoa/Cocoa.h>
#import "PNDesktop.h"


@protocol PNDesktopItem

#pragma mark Attributes  

// sticky 
- (void) setSticky: (BOOL) stickyState; 
- (BOOL) isSticky; 
// alphaValue 
- (void) setAlphaValue: (float) alpha animate: (BOOL) flag withDuration: (float) duration; 
- (void) setAlphaValue: (float) alpha; 
- (float) alphaValue; 
// desktop
- (int) desktopId; 
- (void) setDesktop: (PNDesktop*) desktop; 
// name
- (NSString*) name; 
// iconic representation
- (NSImage*) icon; 

#pragma mark Operations 

- (void) orderOut; 
- (void) orderIn; 
- (void) orderAbove: (NSObject<PNDesktopItem>*) item; 
- (void) orderBelow: (NSObject<PNDesktopItem>*) item; 

@end
