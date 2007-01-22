//
//  PNApplication.h
//  Peony framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

/*!
  @header     PNApplication
  @abstract   Classes for creating and managing "virtual desktops" by utilising Apple's workspace objects
  @discussion This framework does a lot of the management of creating, modifying and maintaining virtual desktops using Apple's workspace objects. It does not define a "layout" for the desktops - as far as the framework is concerned, the desktops have an order, but no physical representation.
 */

#import <Cocoa/Cocoa.h>
#import "PNDesktopItem.h" 
#import "PNDesktop.h" 
#import "PNWindow.h" 

/*!
    @class      PNApplication
    @abstract   Desktop bound window container grouping windows by application pid
    @discussion This interface is not really representing a whole application but acts as a window group grouping windows belonging to one application seen on a specific desktop. It is possible to have multiple applications with the same pid on different desktops at the same time.. 
 */  
@interface PNApplication : NSObject<PNDesktopItem>
{
	pid_t               mPid;			// The process id of the application 
	ProcessSerialNumber	mPsn;			// The process serial number of the application 
  
	PNDesktop*          mDesktop; // Desktop this application is on 
	NSMutableArray*     mWindows; // All windows of the application
  
  NSString            *_name;
  
	BOOL				mIsSticky;		// Is the application stickied?  
	BOOL				mIsHidden;		// Is the application hidden from display?
  BOOL				mIsUnfocused;	// Is the application unfocused?
}

#pragma mark Lifetime
- (id) initWithPid: (pid_t) pid onDesktop: (PNDesktop*) desktop;
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (pid_t) pid; 
- (ProcessSerialNumber) psn; 

#pragma mark -
- (NSArray*) windows; 

#pragma mark -
- (void) setIsHidden: (BOOL) hidden; 
- (BOOL) isHidden; 

#pragma mark -
#pragma mark PNDesktopItem 
// sticky 
- (void) setSticky: (BOOL) stickyState; 
- (BOOL) isSticky; 

#pragma mark -
// focus
- (void) setIsUnfocused: (BOOL) unfocused;
- (BOOL) isUnfocused;

#pragma mark -
// alphaValue 
- (void) setAlphaValue: (float) alpha animate: (BOOL) flag withDuration: (float) duration; 
- (void) setAlphaValue: (float) alpha; 
- (float) alphaValue; 

#pragma mark -
// desktop
- (int) desktopId; 
- (void) setDesktop: (PNDesktop*) desktop; 

#pragma mark -
// name 
- (NSString*) name; 

#pragma mark -
- (NSString*) path;
- (NSString*) bundleId;

#pragma mark -
- (NSImage*) icon;

#pragma mark -
- (BOOL) isValid; 
- (BOOL) isFrontmost;

#pragma mark -
#pragma mark Binding windows  
- (void) bindWindow: (PNWindow*) window; 
- (void) unbindWindow: (PNWindow*) window; 

#pragma mark -
#pragma mark Ordering 
- (void) orderOut; 
- (void) orderIn; 
- (void) orderAbove: (NSObject<PNDesktopItem>*) item; 
- (void) orderBelow: (NSObject<PNDesktopItem>*) item; 

@end
