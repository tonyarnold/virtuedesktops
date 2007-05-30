//
//  PNWindowList.h
//  Peony framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import <Foundation/Foundation.h>
#import "PNDesktopItem.h" 
#import "PNWindow.h" 


@interface PNWindowList : NSObject<PNDesktopItem> 
{
	NSMutableArray* mWindows;					//!< List of managed windows 
	NSMutableArray* mNativeWindows;		//!< List of managed windows by their native identifier 
}

+ (id) windowListWithArray: (NSArray*) windows; 

- (id) init; 
- (id) initWithArray: (NSArray*) windows; 

/// @name Content handling 
//  @{

- (void) addWindow: (PNWindow*) window; 
- (void) addWindows: (NSArray*) windows; 

- (void) delWindow: (PNWindow*) window; 
- (void) delWindows: (NSArray*) windows;

- (NSArray*) windows; 

//  @}
/// @name DesktopItem implementation 
//  @{

	// Sticky 
- (void) setSticky: (BOOL) stickyState; 
- (BOOL) isSticky;

	// alphaValue 
- (void) setAlphaValue: (float) alpha animate: (BOOL) flag withDuration: (float) duration; 
- (void) setAlphaValue: (float) alpha; 
- (float) alphaValue;

	// desktop
- (int) desktopId;
- (void) setDesktop: (PNDesktop*) desktop;
- (void) setDesktopId: (int) desktopId;

	// name
- (NSString*) name;

	// iconic representation
- (NSImage*) icon;

- (void) orderOut; 
- (void) orderIn; 
- (void) orderAbove: (NSObject<PNDesktopItem>*) item; 
- (void) orderBelow: (NSObject<PNDesktopItem>*) item; 

//  @}

@end
