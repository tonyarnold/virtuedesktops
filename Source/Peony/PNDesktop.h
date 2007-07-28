/*!
 *	Peony - PNDesktop.h
 *	@author	Tony Arnold
 *	@author	Thomas Staller
 *	
 *	@addtogroup	peony	Peony framework
 *
 *	@brief A collection of windows representing a window tree called a "Workspace" in Apple's terminology
 *
 *	This interface provides functionality to manipulate and collect windows that belong to one desktop (a workspace) window tree. Since we do not own the workspace but provide a wrapper around existing functionality, this interface is but a wrapper. It is therefore possible to have multiple desktop interfaces for the same workspace, no data between the wrapper instances will be shared, e.g. if one of the instances gets assigned a name, the other will keep its own.
 *	
 *	Copyright (c) 2004, Thomas Staller  <playback@users.sourceforge.net>
 *	Copyright (c) 2006-2007, Tony Arnold <tony@tonyarnold.com
 *
 *	See COPYING for licensing details
 */

/*!
    @header     PNDesktop
    @abstract   Defines the Peony Desktop class
    @discussion This header defines the Peony Desktop class, as well as the Peony transition types and enums.
 */

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "CGSPrivate.h"

@class PNWindow;
@class PNDesktop;
@class PNApplication;

/*!
    @enum       PNTransitionType
    @abstract   Desktop transition effect types
    @discussion These constants represent the available CoreGraphics transition effect types. Quite a number of these are broken or incomplete under Mac OS X 10.4 - many do additive blending, resulting in a disturbing "fade through white" effect that was not present under Mac OS X 10.3. A number of the directional transitions also don't actually move in the provided direction.
    @constant   kPnTransitionAny        Perform any available transition
    @constant   kPnTransitionNone       Don't show any transition
    @constant   kPnTransitionFade       Fades from one desktop to the next
    @constant   kPnTransitionZoom       Zooms the old desktop toward the screen, whilst fading to reveal the new desktop in place
    @constant   kPnTransitionReveal     Slides the old desktop away, revealing the new desktop already in place
    @constant   kPnTransitionWarpFade   Swirls the old desktop, whilst fading to reveal the new desktop already in place
    @constant   kPnTransitionSwap       The old desktop flies away from the screen, whilst the new desktop flies into place
    @constant   kPnTransitionCube       The old and new desktops are superimposed on a three-dimensional cube, which rotates. This is the effect used for Apple's "Fast user switching"
    @constant   kPnTransitionWarpSwitch Swirls the old screen, and upon return from the distortion the new screen is in place
    @constant   kPnTransitionFlip       Flips the old desktop over in three-dimensional space to reveal the new desktop (New in Mac OS X 10.4)
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
	kPnTransitionWarpSwitch,
	kPnTransitionFlip
} PNTransitionType; 

/*!
    @enum       PNTransitionOption
    @abstract   Desktop transition directions
    @discussion These are the parameters that affect which direction a desktop transition will move in
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

/*!
    @class      PNDesktop
    @abstract   A collection of windows representing a window tree called a "Workspace" in Apple's terminology
    @discussion This interface provides functionality to manipulate and collect windows that belong to one desktop (a workspace) window tree. Since we do not own the workspace but provide a wrapper around existing functionality, this interface is but a wrapper. It is therefore possible to have multiple desktop interfaces for the same workspace, no data between the wrapper instances will be shared, e.g. if one of the instances gets assigned a name, the other will keep its own. 
 */ 
@interface PNDesktop : NSObject <NSCopying>
{
	int                   mDesktopId;		// The native workspace identifier of this desktop
	NSString*             mDesktopName;		// The name of the desktop
	NSMutableArray*       mWindows;         // List of windows managed by this desktop
	NSMutableDictionary*  mApplications;	// List of applications managed by the desktop, and indexed by process identifier
    PNApplication*        mActiveApp;       // The last active application of the desktop
}

#pragma mark -
#pragma mark Lifetime 

/*!
    @method   desktopWithId:
    @abstract Returns a desktop wrapper for the workspace with an ID matching the one passed
    @param    desktopId   The identifier of the workspace you wish to return as a desktop wrapper
    @result   Returns an autoreleased desktop wrapper instance that is fully initialised and assigned a temporary desktop name.
*/

+ (PNDesktop*) desktopWithId: (int) desktopId; 

/*!
    @method   desktopWithId: andName:
    @abstract Returns a desktop wrapper for the workspace with an ID and name matching those passed
    @param    desktopId The identifier of the workspace you wish to return as a desktop wrapper
    @param    andName   The name of the workspace you wish to return as a desktop wrapper
    @result   Returns an autoreleased desktop wrapper instance that is fully initialised and has been assigned a temporary desktop name.
 */
+ (PNDesktop*) desktopWithId: (int) desktopId andName: (NSString*) name;

+ (void) setDesktopId: (int) desktopId;

- (id) init; 

/*!
  @method     initWithId:
  @abstract   Initialiser for a desktop with the default name
  @discussion A call to this initialiser will bind the desktop to the passed workspace and initialise the name of the desktop to the default name.
  @param      desktopId The workspace id that is to be wrapped by this desktop instance
  @result     A fully-initialised instance representing the wrapped workspace
*/
- (id) initWithId: (int) desktopId; 

/*!
  @method     initWithId: andName:
  @abstract   Initialiser for a desktop with a provided name
  @discussion A call to this initialiser will bind the desktop to the passed workspace and set the name of the desktop to the value passed.
  @param      desktopId The workspace id that is to be wrapped by this desktop instance
  @param      name      The name for this desktop instance
  @result     A fully-initialised instance representing the wrapped workspace
*/
- (id) initWithId: (int) desktopId andName: (NSString*) name; 

#pragma mark -
#pragma mark Attributes

/*!
    @method   activeDesktopIdentifier
    @abstract Returns the workspace identifier representing the currently active desktop
    @result   The workspace identifier of the currently shown desktop, or kPnDesktopInvalidId if there was an error
*/
+ (int) activeDesktopIdentifier; 

/*!
    @method   firstDesktopIdentifier
    @abstract Returns the lowest possible valid workspace identifier
    @result   The workspace identifier of the lowest possible valid workspace, or kPnDesktopInvalidId if there was an error
*/
+ (int) firstDesktopIdentifier; 

/*!
    @method   identifier
    @abstract Returns the desktop identifier for the desktop represented by this instance
    @result   The desktop identifier for the desktop represented by this instance
*/
- (int) identifier; 

/*!
    @method   setIdentifier:
    @abstract Sets the desktop identifier for the desktop represented by this instance
    @param    identifier  The desktop identifier to set
*/
- (void) setIdentifier: (int) identifier; 

#pragma mark -

/*!
    @method   name
    @abstract Returns the name for the desktop represented by this instance
    @result   The name for the desktop represented by this instance
*/
- (NSString*) name; 
/*!
    @method   setName:
    @abstract Sets the name for the desktop represented by this instance
    @param    name  The desktop name to set
*/
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
- (BOOL) activateTopApplication;
- (BOOL) activateTopApplicationIgnoring: (PNApplication*)application;
- (void) setActiveApplication: (PNApplication*)application;
- (PNApplication*) activeApplication;

#pragma mark -
#pragma mark Window operations
- (void) moveAllWindowsToDesktop: (PNDesktop*) desktop;
- (void) orderWindowFront: (PNWindow*) window;
- (void) orderWindowBack: (PNWindow*) window;
- (void) sendWindowUnderCursorBack;

#pragma mark -
#pragma mark Moving windows
- (void) moveWindowUnderCursorToDesktop: (PNDesktop*) desktop;

#pragma mark -
#pragma mark Updating
- (void) updateDesktop; 
              
#pragma mark -
#pragma mark Queries 
- (PNWindow*) windowUnderCursor;
- (PNWindow*) windowContainingPoint: (NSPoint) point;
- (PNWindow*) windowForId: (CGSWindow) window; 
- (PNApplication*) applicationForPid: (pid_t) pid;
- (PNApplication*) applicationForPSN: (ProcessSerialNumber) psn;
- (PNWindow*) bottomMostWindow;

@end 
