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
#import "PNDesktopItem.h" 
#import "PNDesktop.h" 
#import "PNWindow.h" 

/**
 * @brief	Desktop bound window container grouping windows by application pid
 *
 * This interface is not really representing a whole application but acts as a 
 * window group grouping windows belonging to one application seen on a 
 * specific desktop. It is possible to have multiple applications with the same
 * pid on different desktops at the same time.. 
 *
 */  
@interface PNApplication : NSObject<PNDesktopItem>
{
	pid_t				mPid;			//!< The process id of the application 
	ProcessSerialNumber	mPsn;			//!< The process serial number of the application 
	NSImage*			mIcon;			//!< Application bundle icon 
	NSString*			mName;			//!< Name of the application fetched from the bundle 
	NSString*			mBundlePath;	//!< Path to the application bundle 
	PNDesktop*			mDesktop;		//!< Desktop this application is on 
	
	BOOL				mIsSticky;		//!< Is the application stickied?  
	BOOL				mIsHidden;		//!< Is the application hidden from display? 
	NSMutableArray*		mWindows;		//!< All windows of the application 
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
- (void) setHidden: (BOOL) hidden; 
- (BOOL) isHidden; 

#pragma mark -
#pragma mark PNDesktopItem 
// sticky 
- (void) setSticky: (BOOL) stickyState; 
- (BOOL) isSticky; 

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
// iconic representation
- (NSImage*) icon; 

#pragma mark -
- (NSString*) bundlePath; 

#pragma mark -
- (BOOL) isValid; 

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
