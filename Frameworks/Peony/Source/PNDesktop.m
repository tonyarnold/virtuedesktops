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

#import "PNDesktop.h"
#import "PNWindow.h"
#import "PNApplication.h"
#import "PNNotifications.h"
#import "PNStickyWindowCollection.h"
#import <Zen/Zen.h>

@interface PNDesktop(Private)
- (PNWindow*) windowWithId: (CGSWindow) windowId;
- (id) initWithId: (int) desktopId andName: (NSString*) name update: (BOOL) update;
@end

#pragma mark -
@interface PNDesktop (ApplicationList)
- (void) detachApplication: (PNApplication*) application;
- (void) attachApplication: (PNApplication*) application;
@end

#pragma mark -
@implementation PNDesktop

#pragma mark -
#pragma mark Lifetime

/**
 * @brief		Factory for a desktop with passed id
 *
 * @param		desktopId		The workspace id that should be wrapped
 *
 * Returns an autoreleased desktop wrapper instance that is fully
 * initialized and assigned a temporary desktop name.
 *
 */
+ (PNDesktop*) desktopWithId: (int) desktopId {
	// create a new desktop and associate it with the passed workspace id
	return [[[PNDesktop alloc] initWithId: desktopId] autorelease];
}

/**
 * @brief		Factory for a desktop with passed id and name
 *
 * @param		desktopId		The workspace id that should be wrapped
 * @param		andName		The desktop name
 *
 */
+ (PNDesktop*) desktopWithId: (int) desktopId andName: (NSString*) name {
	// create a new desktop and associate it with the passed workspace id
	return [[[PNDesktop alloc] initWithId: desktopId andName: name] autorelease];
}

#pragma mark -

/**
 * @brief We do not allow initialization of a non-connected
 *			desktop proxy
 *
 */
- (id) init {
	return [self initWithId: -1];
}

/**
 * @brief Initializer for a desktop
 *
 * @param desktopId The workspace id that is wrapped
 *
 * A call to this initializer will bind the desktop to the passed workspace and
 * initialize the name of the desktop to the default name.
 *
 */
- (id) initWithId: (int) desktopId {
	// generate default name
	NSString* sDefaultName = [NSString stringWithFormat: @"Desktop %i", desktopId];
	// pass on initialiazion to designated initializer

	return [self initWithId: desktopId andName: sDefaultName];
}

/**
 * @brief Designated Initializer for a desktop
 *
 * @param desktopId The workspace id that is wrapped
 * @param andName		The desktop name
 *
 * A call to this initializer will bind the desktop to the passed workspace and
 * initialize the name of the desktop to the passed name.
 *
 */
- (id) initWithId: (int) desktopId andName: (NSString*) name {
	return [self initWithId: desktopId andName: name update: YES];
}

- (void) dealloc {
	ZEN_RELEASE(mDesktopName);
	ZEN_RELEASE(mWindows);
	ZEN_RELEASE(mApplications);

	// delegate to super
	[super dealloc];
}

#pragma mark -
#pragma mark NSCopying
- (id) copyWithZone: (NSZone*) zone {
	PNDesktop* desktop = [[PNDesktop alloc] initWithId: mDesktopId andName: mDesktopName update: NO];

	// and initialize
	desktop->mWindows				= [mWindows retain];
	desktop->mApplications	= [mApplications retain];

	return desktop;
}

#pragma mark -
#pragma mark Attributes

/**
 * @brief		Returns the id of the desktop that is currently shown
 *
 * @return	The workspace id of the currently shown desktop or
 *			kPnDesktopInvalidId if there was an error.
 */
+ (int) activeDesktopIdentifier
{
	// get cgs connection
	CGSConnection oConnection = _CGSDefaultConnection();
	// fetch the active desktop id and return nil in case of an error
	int iWorkspaceId;

	OSStatus oResult = CGSGetWorkspace(oConnection, &iWorkspaceId);
	if (oResult)
	{
		NSLog(@"PNDesktop cannot access current workspace [Error: %i]", oResult);
		return kPnDesktopInvalidId;
	}

	return iWorkspaceId;
}

/**
 * @brief Returns the lowest possible / valid desktop id
 *
 */
+ (int) firstDesktopIdentifier {
	return 1;
}

#pragma mark -
- (int) identifier {
	return mDesktopId;
}

- (void) setIdentifier: (int) identifier {
	mDesktopId = identifier;

	[self updateDesktop];
}


#pragma mark -
- (NSString*) name {
	return mDesktopName;
}

- (void) setName: (NSString*) name {
	[mDesktopName autorelease];

	if (name && ([name length] > 0))
		mDesktopName = [name copy];
	else
		mDesktopName = @"None";
}


#pragma mark -

/**
 * @brief KVO compliant list of windows contained in the desktop
 *
 */
- (NSArray*) windows {
	return mWindows;
}

/**
 * @brief KVO compliant list of applications contained in the desktop
 *
 */
- (NSArray*) applications {
	return [mApplications allValues];
}

#pragma mark -

/**
 * @brief Checks if the desktop is currently shown to the user
 *
 * @return	Returns @c YES if the desktop is the one the user is
 *			currently working on, @c NO if it is not.
 *
 */
- (BOOL) visible {
	CGSConnection oConnection = _CGSDefaultConnection();

	int iActiveWorkspace;
	OSStatus oResult = CGSGetWorkspace(oConnection, &iActiveWorkspace);
	if (oResult) {
		NSLog(@"[Desktop %i] Failed getting active workspace [Error: %i]", mDesktopId, oResult);
		return NO;
	}

	return (mDesktopId == iActiveWorkspace);
}

#pragma mark -
#pragma mark NSObject

- (BOOL) isEqual: (id) other {
	if ([other isKindOfClass: [PNDesktop class]] == NO)
		return NO;

	return (mDesktopId == [(PNDesktop*)other identifier]);
}

- (NSString*) description {
	return [self name];
}

#pragma mark -
#pragma mark Activation

/**
 * @brief Activates the desktop using the default transition and duration settings
 *
 */
- (void) activate {
	// delegate to the more sophisticated activation method using default values
	[self activateWithTransition: kPnTransitionAny option: kPnOptionAny duration: kPnTransitionDurationDefault];
}

/**
 * @brief Activates the desktop using the passed transition and duration
 *
 * @param transition	The transition to use while switching
 * @param option		Option parameterizing the transition
 * @param duration	The duration the transition should take in seconds
 *
 * The passed transition type has to be different from peonyTransitionAny. If
 * peonyTransitionAny is passed, peonyTransitionNone will be used as the type
 * passed to CGS.
 *
 * @notify		kPnOnDesktopWillActivate
 *					'object'	self
 * @notify		kPnOnDesktopDidActivate
 *					'object'	self
 *
 * @distnotify	kPnOnDesktopWillActivate
 *					'desktop' self.desktopId
 * @distnotify	kPnOnDesktopDidActivate
 *					'desktop' self.desktopId
 */
- (void) activateWithTransition: (PNTransitionType) transition option: (PNTransitionOption) option duration: (float) seconds {
	NSDictionary* infoDict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt: mDesktopId], @"desktop",
		nil];

	// notify clients that we will soon be the active desktop
	[[NSDistributedNotificationCenter defaultCenter]
		postNotificationName: kPnOnDesktopWillActivate object: nil userInfo: infoDict];
	[[NSNotificationCenter defaultCenter]
		postNotificationName: kPnOnDesktopWillActivate object: self];

	// get connection
		CGSConnection oConnection = _CGSDefaultConnection();

		int transNo = -1;
		CGSTransitionSpec transSpec;

		transSpec.type				= transition;
		transSpec.option			= option;
		transSpec.wid					= 0;
		transSpec.backColour	= NULL;
		
		CGSNewTransition(oConnection, &transSpec, &transNo);
		CGSSetWorkspace(oConnection,mDesktopId);
		usleep(700000);
		
	// notify listeners that we are now the active desktop
	[[NSDistributedNotificationCenter defaultCenter]
		postNotificationName: kPnOnDesktopDidActivate object: nil userInfo: infoDict];
	[[NSNotificationCenter defaultCenter]
		postNotificationName: kPnOnDesktopDidActivate object: self];
	CGSInvokeTransition(oConnection, transNo, seconds);

}

#pragma mark -
#pragma mark Window operations

- (void) moveAllWindowsToDesktop: (PNDesktop*) desktop {
	// update to fetch all windows we have
	[self updateDesktop];
	// now go through the list of windows and move them to the passed desktop
	NSEnumerator*		windowIter = [mWindows objectEnumerator];
	PNWindow*		window		 = nil;

	// TODO: Move functionality to use a PNWindowList for mass-window
	//		 operations
	while (window = [windowIter nextObject]) {
		[window setDesktop: desktop];
	}
}

/**
 * @brief Orders the passed window to the front of the current desktop
 *
 * @param window	Window to bring to the front
 *
 */
- (void) orderWindowFront: (PNWindow*) window {
	if ([mWindows count] == 0)
		return;
	if ([mWindows objectAtIndex: 0] == window)
		return;

	PNWindow* referenceWindow = [mWindows objectAtIndex: 0];
	[window orderAbove: referenceWindow];
}

#pragma mark -
#pragma mark Updating

/**
 * @brief Clear the list of windows and fetch all windows in the workspace
 *
 * Queries windows for the wrapped desktop and adds new windows not yet contained
 * in the internal list of windows. Windows that are contained in the internal list
 * but were not returned by the windows query, will be removed from the internal
 * list. We also try to validate all sticky windows in this run and remove invalid
 * sticky windows (those that were closed) from the sticky window list.
 *
 * @note	This method is inherently costly, it should not be called every ms and
 *			the caller should be prepared to wait a bit here.
 *
 * @notify	kPnOnWindowRemoved
 *			Called if a window is no longer living on this desktop or was closed
 *
 * @todo	Optimize a bit here
 *
 */
- (void) updateDesktop {
	if (mDesktopId < 0)
		return;

	// get connection
	CGSConnection		oConnection						= _CGSDefaultConnection();
	OSStatus				oResult;

	int							iNumberOfWindows			= 0;
	NSMutableData*	oWindows							= NULL;

	BOOL						didChangeWindows			= NO;
	BOOL						didChangeApplications = NO;

	// first we have to query for the number of windows in our workspace
	oResult = CGSGetWorkspaceWindowCount(oConnection, mDesktopId, &iNumberOfWindows);
	if (oResult) {
		NSLog(@"[Desktop %i] CGSGetWorkspaceWindowCount failed [%i]", mDesktopId, oResult);
		return;
	}

	// if the number of desktops is 0, we will skip fetching windows
	if (iNumberOfWindows > 0) {
		// query the list of windows in our workspace
		oWindows = [NSMutableData dataWithCapacity: iNumberOfWindows * sizeof(int)];
		oResult = CGSGetWorkspaceWindowList(oConnection, mDesktopId, iNumberOfWindows, [oWindows mutableBytes], &iNumberOfWindows);
		if (oResult)
		{
			NSLog(@"[Desktop %i] CGSGetWorkspaceWindowList failed [%i]", mDesktopId, oResult);
			return;
		}
	}
	

// copy the current list of windows for cross checking
	NSMutableArray* previousWindows = [NSMutableArray arrayWithArray: mWindows];

	int i									= 0;
	int currentListIndex	= 0;

// heya, now we can start synchronizing.. we will iterate over all windows and
// check if we already know about them. If we find a window we do not know, we
// will add it. we will also remove windows we found from the copy.
	for ( i = 0; i < iNumberOfWindows; i++ ) {
// get entry from list of fetched windows
		CGSWindow iWindowId = ((int*)[oWindows mutableBytes])[i];

// get the window proxy
		PNWindow* window = [[PNWindow windowWithWindowId: iWindowId] retain];
// if the window is special, we do not include it in our list
		if ([window isSpecial]) {
			[window release];
			continue;
		}

// ignore menus
		if (([window level] == NSPopUpMenuWindowLevel) ||
				([window level] == NSSubmenuWindowLevel) ||
				([window level] == NSMainMenuWindowLevel)) {
			[window release];
			continue;
		}

		// get application container
		PNApplication* application = [mApplications objectForKey: [NSNumber numberWithInt: [window ownerPid]]];
		// if the application container does not contain a reference to the
		// application, create a new one
		if (application == nil) {
			didChangeApplications = YES;

			application = [[PNApplication alloc] initWithPid: [window ownerPid] onDesktop: self];
			// and attach
			[self attachApplication: application];
			// and release application
			[application release];
		}

		// check if the window is in our list and add it if it isn't
		if ([mWindows containsObject: window] == NO) {
			// add the window to the list of known windows and mark ourselves as dirty
			didChangeWindows = YES;
			[mWindows insertObject: window atIndex: currentListIndex];
			[application bindWindow: window];
		}
		else {
			// we already knew about this window, and it apparently still exists, so
			// we will remove it from the list of previous windows
			[previousWindows removeObject: window];

			// and check if the position of the window changed
			if (currentListIndex != [mWindows indexOfObject: window])
			{
				didChangeWindows = YES;

				// now we move the window to the new index
				[mWindows removeObject: window];
				[mWindows insertObject: window atIndex: currentListIndex];
			}
		}

		[window release];
		// increment the list index
		currentListIndex++;
	}

	// now handle sticky windows, this will only change the window
	// list, if we are not the active desktop
	NSArray*				stickyWindowsCopy = [NSMutableArray arrayWithArray: [[PNStickyWindowCollection stickyWindowCollection] windows]];
	NSEnumerator*		stickyIter				= [stickyWindowsCopy objectEnumerator];
	PNWindow*				stickyWindow			= nil;

	while (stickyWindow = [stickyIter nextObject]) {
		// we take the chance and remove all the sticky windows that are no longer
		// valid
		if ([stickyWindow isValid] == NO)
		{
			// remove from the sticky window list as this window seems to be gone
			[[PNStickyWindowCollection stickyWindowCollection] delWindow: stickyWindow];
			// and also remove it from the application list if necessary
			PNApplication* application = [mApplications objectForKey: [NSNumber numberWithInt: [stickyWindow ownerPid]]];
			if (application != nil) {
				if ([application isValid] == YES)
					[application unbindWindow: stickyWindow];
				else {
					didChangeApplications = YES;
					// detach application
					[self detachApplication: application];
				}
			}

			if ([previousWindows containsObject: stickyWindow] == NO) {
				// and post notification that the window was removed
				[[NSNotificationCenter defaultCenter] postNotificationName: kPnOnWindowRemoved object: stickyWindow];
			}
		}
		else
		{
			// remove from previous list if it is there
			[previousWindows removeObject: stickyWindow];

			if (([stickyWindow isSpecial] == NO) && ([mWindows containsObject: stickyWindow] == NO)) {
				didChangeWindows = YES;
				[mWindows addObject: stickyWindow];

				PNApplication*	application = [mApplications objectForKey: [NSNumber numberWithInt: [stickyWindow ownerPid]]];
				// if the application container does not contain a reference to the
				// application, create a new one
				if (application == nil) {
					didChangeApplications = YES;

					application = [[PNApplication alloc] initWithPid: [stickyWindow ownerPid] onDesktop: self];
					// and attach application
					[self attachApplication: application];
					// safe to release it now
					[application release];
				}

				[application bindWindow: stickyWindow];
			}
		}
	}

	// all windows that are still left in the copied window list
	// were not touched by the loop above and are no longer on
	// the desktop, so we will remove them from the list of windows
	NSEnumerator*		previousWindowsIter = [previousWindows objectEnumerator];
	PNWindow*				checkWindow = nil;

	while (checkWindow = [previousWindowsIter nextObject]) {
		// remove...
		didChangeWindows = YES;

		[mWindows removeObject: checkWindow];

		// handle application windows
		PNApplication* application = [mApplications objectForKey: [NSNumber numberWithInt: [checkWindow ownerPid]]];
		if (application != nil) {
			// check if the application is still valid
			if ([application isValid]) {
				[application unbindWindow: checkWindow];
				// check if there are still windows contained in the application wrappers and
				// remove the application if there are none...
				if ([[application windows] count] == 0) {
					didChangeApplications = YES;
					[self detachApplication: application];
				}
			}
			else {
				didChangeApplications = YES;
				[self detachApplication: application];
			}
		}

		// and post notification that the window was removed
		[[NSNotificationCenter defaultCenter] postNotificationName: kPnOnWindowRemoved object: checkWindow];
	}

	// clear the list of previous windows
	[previousWindows removeAllObjects];

	// now post KVO notification
	if (didChangeWindows == YES) {
		// should not get performance issues as i doubt someone will have 1000 windows
		// open on his desktop. so we just post notification for whole array
		[self willChangeValueForKey: @"windows"];
		[self didChangeValueForKey: @"windows"];
	}
	if (didChangeApplications == YES) {
		[self willChangeValueForKey: @"applications"];
		[self didChangeValueForKey: @"applications"];
	}
}


#pragma mark -
#pragma mark Queries

/**
 * @brief Finds the topmost window in the hierarchy containing the passed point
 *
 * @param point Point to search for
 *
 * The method will skip windows marked as special and windows not living on the
 * kCGNormalWindowLevel window level
 *
 */
- (PNWindow*) windowContainingPoint: (NSPoint) point {
	// iterate windows until we find a window containing the passed
	// point or we reached the end of the list. we will not consider
	// windows that were marked as special

	NSEnumerator*		windowIter	= [mWindows objectEnumerator];
	PNWindow*				window			= nil;

	while (window = [windowIter nextObject]) {
		//if ([window isSpecial])
		//	continue;
		//if ([window level] != kCGNormalWindowLevel)
		//	continue;

		// fetch the screen rect to check
		NSRect	windowRect = [window screenRectangle];

		if (NSMouseInRect(point, windowRect, NO)) {
			return window;
		}
	}

	return nil;
}

/**
 * @brief Searches for the application with the passed pid
 *
 * @param pid Process id for the application to return
 *
 * @return	Returns the application instance matching the passed pid or @c nil
 *			if the desktop does not contain an application with the passed pid
 *
 */
- (PNApplication*) applicationForPid: (pid_t) pid {
	return [mApplications objectForKey: [NSNumber numberWithInt: pid]];
}

/**
 * @brief Searches for the window with the passed window id
 *
 * @param window	Window to search for
 *
 * @return	Returns the window instance matching the passed id or @c nil if
 *			the desktop does not contain a window with the passed id
 *
 */
- (PNWindow*) windowForId: (CGSWindow) window {
	return [self windowWithId: window];
}

@end

#pragma mark -
@implementation PNDesktop(Private)

/**
 * @todo	Remove and change over to windowForId
 *
 */
- (PNWindow*) windowWithId: (CGSWindow) windowId {
	// iterate through the list of windows until we find the passed window id
	NSEnumerator*		windowIter	= [mWindows objectEnumerator];
	PNWindow*		window		= nil;

	while (window = [windowIter nextObject]) {
		if ([window nativeWindow] == windowId)
			return window;
	}

	return nil;
}

- (id) initWithId: (int) desktopId andName: (NSString*) name update: (BOOL) update {
	if (self = [super init]) {
		// initialize attributes
		mDesktopId		= desktopId;
		mDesktopName	= [name copy];
		mWindows		= [[NSMutableArray array] retain];
		mApplications = [[NSMutableDictionary dictionary] retain];

		// build up list of windows we got in our workspace
		if (update == YES)
			[self updateDesktop];

		return self;
	}

	return nil;
}

@end

#pragma mark -
@implementation PNDesktop (ApplicationList)
- (void) detachApplication: (PNApplication*) application {
	if (application == nil)
		return;
	if ([application bundlePath] == nil)
		return;

	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		application, PNApplicationInstanceParam,
		self, PNApplicationDesktopParam,
		nil];

	[mApplications removeObjectForKey: [NSNumber numberWithInt: [application pid]]];

	// and post notification
	[[NSNotificationCenter defaultCenter] postNotificationName: PNApplicationWasRemoved object: [application bundlePath] userInfo: userInfo];
}

- (void) attachApplication: (PNApplication*) application {
	if (application == nil)
		return;
	if ([application bundlePath] == nil)
		return;

	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
		application, PNApplicationInstanceParam,
		self, PNApplicationDesktopParam,
		nil];

	[mApplications setObject: application forKey: [NSNumber numberWithInt: [application pid]]];

	// and post notification
	[[NSNotificationCenter defaultCenter] postNotificationName: PNApplicationWasAdded object: [application bundlePath] userInfo: userInfo];
}

@end