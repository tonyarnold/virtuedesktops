/*
	PNApplication.h
	See COPYING for licensing details
	Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
	Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
 */

#import <Cocoa/Cocoa.h>
#import "PNDesktopItem.h" 
#import "PNDesktop.h" 
#import "PNWindow.h" 

@interface PNApplication : NSObject<PNDesktopItem>
{
	pid_t               mPid;			//!< The process id of the application
	ProcessSerialNumber	mPsn;			//!< The process serial number of the application
  
	PNDesktop*          mDesktop; //!< Desktop this application is on
	NSMutableArray*     mWindows; //!< All windows of the application
  
	NSString            *_name;
  
	BOOL				mIsSticky;		//!< Is the application stickied?
	BOOL				mIsHidden;		//!< Is the application hidden from display?
	BOOL				mIsUnfocused;	//!< Is the application unfocused?
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
/*!
  @return The identifier of the application's desktop
 */
- (int) desktopId;
/*!
  @return The desktop of the application
 */
- (PNDesktop*) desktop;		
/*!
  @brief  Moves the represented application to the specified desktop
  @param  desktop The PNDesktop instance to move the represented PNApplication instance to.
  @todo   Move this method from separate window handling to handling a window list, which should be much more efficient 
  */
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
- (BOOL) isMe;

#pragma mark -
- (BOOL) activate;

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
