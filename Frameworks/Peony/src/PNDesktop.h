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

// cocoa includes 
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
// private cgs stuff
#import "CGSPrivate.h"

@class PNWindow;
@class PNApplication; 

/**
 * @brief   Desktop switching Transitions
 *
 */ 
typedef enum {
	kPnTransitionAny		= -1,
	kPnTransitionNone		= CGSNone, 
	kPnTransitionFade, 
	kPnTransitionZoom,
	kPnTransitionReveal, 
	kPnTransitionSlide, 
	kPnTransitionWarpFade, 
	kPnTransitionSwap,
	kPnTransitionCube,
	kPnTransitionWarpSwitch
} PNTransitionType; 

/**
 * @brief   Desktop transition parameters
 *
 */
typedef enum {
	kPnOptionAny			= -1, 
	kPnOptionDown			= CGSDown, 
	kPnOptionLeft,
	kPnOptionRight,
	kPnOptionInRight, 
	kPnOptionBottomLeft		= 5,
	kPnOptionBottomRight,		
	kPnOptionDownTopRight,		
	kPnOptionUp,					
	kPnOptionTopLeft,			
	kPnOptionTopRight,			
	kPnOptionUpBottomRight,		
	kPnOptionInBottom,			
	kPnOptionLeftBottomRight,	
	kPnOptionRightBottomLeft,	
	kPnOptionInBottomRight,		
	kPnOptionInOut				
} PNTransitionOption; 

enum
{
	kPnTransitionDurationDefault = 1
};

enum
{
	kPnDesktopInvalidId  = -1
}; 

#pragma mark -

/**
 * @interface	PNDesktop
 * @brief		A collection of windows representing a window tree called 
 *				Workspace in Apple terminology
 *
 * This interface provides functionality to manipulate and collect windows
 * that belong to one desktop (a workspace) window tree. Since we do not 
 * own the workspace but provide a wrapper around existing functionality, 
 * this interface is but a wrapper. It is therefore possible to have
 * multiple desktop interfaces for the same workspace, no data between the
 * wrapper instances will be shared, e.g. if one of the instances gets assigned
 * a name, the other will keep its own. 
 *
 * @notify		kPnOnDesktopWillActivate
 *				Sent when the desktop is about to be activated 
 * @notify		kPnOnDesktopDidActivate 
 *				Sent when the desktop was activated
 * 
 */ 
@interface PNDesktop : NSObject<NSCopying>
{
	int						mDesktopId;			//!< The native workspace id of this desktop
	NSString*				mDesktopName;		//!< Name of the desktop
	NSMutableArray*			mWindows;			//!< List of windows managed by the desktop
	NSMutableDictionary*	mApplications;		//!< List of applications managed by the desktop indexed by pid
}

#pragma mark -
#pragma mark Lifetime 

+ (PNDesktop*) desktopWithId: (int) desktopId; 
+ (PNDesktop*) desktopWithId: (int) desktopId andName: (NSString*) name; 

- (id) init; 
- (id) initWithId: (int) desktopId; 
- (id) initWithId: (int) desktopId andName: (NSString*) name; 

#pragma mark -
#pragma mark Attributes 

+ (int) activeDesktopIdentifier; 
+ (int) firstDesktopIdentifier; 

- (int) identifier; 
- (void) setIdentifier: (int) identifier; 

#pragma mark -
- (NSString*) name; 
- (void) setName: (NSString*) name; 

#pragma mark -
- (NSArray*) windows;
- (NSArray*) applications;

#pragma mark -
- (BOOL) visible; 

#pragma mark -
#pragma mark NSObject
- (BOOL) isEqual: (id) other; 
- (NSString*) description; 

#pragma mark -
#pragma mark Activation 
- (void) activate; 
- (void) activateWithTransition: (PNTransitionType) transition option: (PNTransitionOption) option duration: (float) seconds;

#pragma mark -
#pragma mark Window operations 
- (void) moveAllWindowsToDesktop: (PNDesktop*) desktop;
- (void) orderWindowFront: (PNWindow*) window;  

#pragma mark -
#pragma mark Updating 
- (void) updateDesktop; 
              
#pragma mark -
#pragma mark Queries 
- (PNWindow*) windowContainingPoint: (NSPoint) point;
- (PNWindow*) windowForId: (CGSWindow) window; 
- (PNApplication*) applicationForPid: (pid_t) pid; 

@end 