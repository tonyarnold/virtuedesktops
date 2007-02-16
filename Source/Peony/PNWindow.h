//
//  PNWindow.h
//  Peony framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h> 

#import "PNDesktop.h"
#import "PNDesktopItem.h" 
#import "CGSPrivate.h"  

enum
{
	kPnWindowInvalidId    = -1,
	kPnWindowInvalidLevel = -1,
	kPnWindowInvalidPid   =  0,
}; 

enum
{
	kPnOrderTypeAbove	= kCGSOrderAbove,
	kPnOrderTypeBelow	= kCGSOrderBelow,
	kPnOrderTypeOut		= kCGSOrderOut,
};

/*!
    @class      PNWindow
    @abstract		Lightweight wrapper around a CGSWindow
    @discussion This interface provides methods for window manipulation operations on CGSWindows. Instances can be created from a native CGSWindow id or by using an NSWindow as template. 

 */ 
@interface PNWindow : NSObject<PNDesktopItem>
{
	CGSWindow   mNativeWindow;      //!< The native window that is wrapped 
	pid_t       mOwnerPid;					//!< The pid of the window owner 
	NSImage*    mIcon;							//!< Window icon 
	
	BOOL		mIsSticky;              //!< YES if the window is stickied 
	BOOL		mIsSpecial;             //!< If YES, VirtueDesktops will not display this window 
	BOOL		mIsIgnoredByExpose; 
}

#pragma mark -
#pragma mark Lifetime 

+ (PNWindow*) windowWithNSWindow: (NSWindow*) window; 
+ (PNWindow*) windowWithWindowId: (CGSWindow) windowId; 

- (id) initWithNSWindow: (NSWindow*) window; 
- (id) initWithWindowId: (CGSWindow) windowId; 
- (void) dealloc; 

#pragma mark -
#pragma mark NSObject 
- (BOOL) isEqual: (id) toObject; 

#pragma mark -
#pragma mark Ordering 

- (void) orderAbove: (NSObject<PNDesktopItem>*) window; 
- (void) orderBelow: (NSObject<PNDesktopItem>*) window; 

- (void) orderOut; 
- (void) orderIn; 

#pragma mark -
#pragma mark Attributes  

- (BOOL) isValid; 

#pragma mark -
- (void) setProperty: (NSString*) property forKey: (NSString*) key; 
- (NSString*) propertyForKey: (NSString*) key; 

#pragma mark -
- (int) desktopId; 
- (void) setDesktopId: (int) desktopId; 

- (void) setDesktop: (PNDesktop*) desktop; 

#pragma mark -
- (CGSWindow) nativeWindow;

- (BOOL)isMenu;
- (BOOL)isPalette;

#pragma mark -
- (BOOL) isSpecial;
- (void) setSpecial: (BOOL) special;

#pragma mark -
- (pid_t) ownerPid; 
- (ProcessSerialNumber) ownerPsn; 

#pragma mark -
- (void) setSticky: (BOOL) stickyState; 
- (BOOL) isSticky; 

#pragma mark -
- (void) setIgnoredByExpose: (BOOL) flag; 
- (BOOL) isIgnoredByExpose; 

#pragma mark -
- (void) clearWindowTags;

#pragma mark -
- (int) level; 
- (void) setLevel: (int) level; 

#pragma mark -
- (void) setAlphaValue: (float) alpha; 
- (void) setAlphaValue: (float) alpha animate: (BOOL) flag withDuration: (float) duration; 
- (float) alphaValue; 

#pragma mark -
- (NSString*) name; 

- (BOOL) isOrderedIn;

#pragma mark -
- (NSImage*) icon; 

#pragma mark -
- (NSRect) screenRectangle; 

@end 