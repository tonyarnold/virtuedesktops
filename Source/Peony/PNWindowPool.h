/*
	PNWindowPool.h
	See COPYING for licensing details
	Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
	Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com>
*/

/*! @header       PNWindowPool.h
    @discussion   This interface provides a method to maintain a shared list of valid, active PNWindow objects that are currently attached to desktops.
 */
#import <Foundation/Foundation.h>
#import "CGSPrivate.h" 
#import "PNWindowList.h"
#import "PNWindow.h"


/*! @class       PNWindowPool
    @abstract    Provides a pool of currently allocated, valid PNWindow objects who are assigned to desktops
    @discussion  This interface provides a method to maintain a shared list of valid, active PNWindow objects that are currently attached to desktops.
 */
@interface PNWindowPool : NSObject 
{
	NSMutableDictionary*	_windowDict;
}

/*! @method   sharedWindowPool
    @abstract Creates (if necessary) and returns a shared instance of the current class.  
    @result   Returns the newly initialized (if necessary) PNWindowPool object or nil on error.
*/
+ (PNWindowPool*) sharedWindowPool;

/*! @method   windowWithId:   
    @abstract Creates (if necessary) and returns the PNWindow instance with the window identifier specified.  
    @param    windowId  
              A CGSWindow specifying the identifier of the window to return.
    @result   Returns the newly initialized (if necessary) PNWindow object or nil on error.
*/
- (PNWindow*) windowWithId: (CGSWindow) windowId;
- (PNWindowList*) windowsOnDesktopId: (int) desktopId;
@end
