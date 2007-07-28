/*!
 *	Peony - PNDesktop.m
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

+ (PNDesktop*) desktopWithId: (int) desktopId 
{
	// Create a new desktop and associate it with the passed workspace id
	return [[PNDesktop alloc] initWithId: desktopId];
}

+ (PNDesktop*) desktopWithId: (int) desktopId andName: (NSString*) name 
{
	// Create a new desktop and associate it with the passed workspace id
	return [[PNDesktop alloc] initWithId: desktopId andName: name];
}

+ (void) setDesktopId: (int) desktopId
{
    CGSConnection cgs = _CGSDefaultConnection();
    CGSSetWorkspace(cgs, desktopId);
}

#pragma mark -

- (id) init 
{
	return [self initWithId: -1];
}


- (id) initWithId:(int)desktopId
{
	// generate default name
	NSString* sDefaultName = [NSString stringWithFormat: @"Desktop %i", desktopId];
	  
	// Pass on initialisation to designated initialiser
	return [self initWithId: desktopId andName: sDefaultName];
}

- (id) initWithId:(int)desktopId andName:(NSString*)name {
	return [self initWithId: desktopId andName: name update: YES];
}

- (void) dealloc 
{
	[mDesktopName release];
	[mWindows release];
	[mApplications release];
  
	// Delegate deallocation to superclass
	[super dealloc];
}

#pragma mark -
#pragma mark NSCopying
- (id) copyWithZone:(NSZone*)zone
{
	PNDesktop* desktop = [[PNDesktop alloc] initWithId: mDesktopId
                                             andName: mDesktopName
                                              update: NO];
  
	desktop->mWindows = mWindows;
	desktop->mApplications	= mApplications;
  
	return desktop;
}

#pragma mark -
#pragma mark Attributes
+ (int) activeDesktopIdentifier
{
	// Get a connection to the CoreGraphics server
	CGSConnection connection = _CGSDefaultConnection();
	
	// Fetch the active desktop id and return nil in case of an error
	int iWorkspaceId;
  
	OSStatus result = CGSGetWorkspace(connection, &iWorkspaceId);
	if (result)
	{
		ZNLog( @"PNDesktop cannot access current workspace [Error: %i]", result);
		return kPnDesktopInvalidId;
	}
  
	return iWorkspaceId;
}

+ (int) firstDesktopIdentifier 
{
	return 1;
}

#pragma mark -
- (int) identifier 
{
	return mDesktopId;
}

- (void) setIdentifier: (int) identifier 
{
	mDesktopId = identifier;
  
	[self updateDesktop];
}


#pragma mark -
- (NSString*) name 
{
	return mDesktopName;
}

- (void) setName: (NSString*) name 
{
	if (mDesktopName == name)
	{
		return;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName: PNDesktopWillChangeName object: nil userInfo: nil];
  
	[mDesktopName release];
  
	if (name && ([name length] > 0))
	{
		mDesktopName = [name copy];
	}
	else
	{
		mDesktopName = @"None";
	}
  
	[[NSNotificationCenter defaultCenter] postNotificationName: PNDesktopDidChangeName object: nil userInfo: nil];
}


#pragma mark -

/**
* @brief KVO compliant list of windows contained in the desktop
 *
 */
- (NSArray*) windows 
{
	return mWindows;
}

/**
* @brief KVO compliant list of applications contained in the desktop
 *
 */
- (NSArray*) applications 
{
	return [mApplications allValues];
}

#pragma mark -

/**
* @brief Checks if the desktop is currently shown to the user
 *
 * @return	Returns @c YES if the desktop is the one the user is currently working on, @c NO if it is not.
 *
 */
- (BOOL) visible 
{
	CGSConnection oConnection = _CGSDefaultConnection();
  
	int iActiveWorkspace;
	OSStatus oResult = CGSGetWorkspace(oConnection, &iActiveWorkspace);
	if (oResult) {
		ZNLog( @"[Desktop %i] Failed getting active workspace [Error: %i]", mDesktopId, oResult);
		return NO;
	}
  
	return (mDesktopId == iActiveWorkspace);
}

#pragma mark -
#pragma mark NSObject

- (BOOL) isEqual: (id) other 
{
	if ([other isKindOfClass: [PNDesktop class]] == NO)
		return NO;
  
	return (mDesktopId == [(PNDesktop*)other identifier]);
}

- (NSString*) description 
{
	return [self name];
}

#pragma mark -
#pragma mark Activation

/**
* @brief Activates the desktop using the default transition and duration settings
 *
 */
- (void) activate 
{
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
 * The passed transition type has to be different from peonyTransitionAny. If peonyTransitionAny is passed, peonyTransitionNone will be used as the type passed to CGS.
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
- (void) activateWithTransition: (PNTransitionType) transition option: (PNTransitionOption) option duration: (float) seconds 
{
	NSDictionary* infoDict = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt: mDesktopId], @"desktop", nil];
	
  // Notify clients that we will soon be the active desktop
	[[NSNotificationCenter defaultCenter] postNotificationName: kPnOnDesktopWillActivate object: self];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName: kPnOnDesktopWillActivate object: nil userInfo: infoDict];
  
	// Get the connection to the CoreGraphics server
	CGSConnection cgs = _CGSDefaultConnection();
	
	if ((int)transition == -1) {
		transition = CGSNone;
		seconds = 0;
	}
  
	// Set-up the transition "effect" first
	int handle;
  
  // Set the colour of the backdrop for the CGSTransition
	float rgb[3] = { 0.0, 0.0, 0.0 };
  
	CGSTransitionSpec spec;
	spec.unknown1		= 0;
	spec.type				= transition;
	spec.option			= option;
	spec.wid				= 0;
	spec.backColour	= rgb;
	
	// Create the transition, freezing all on-screen activity		
	CGSNewTransition(cgs, &spec, &handle);
  
  // Now switch the workspace while the screen is frozen, setting up the transition target
	[PNDesktop setDesktopId: mDesktopId];
	
  // Notify listeners that we are now the active desktop
	[[NSNotificationCenter defaultCenter] postNotificationName: kPnOnDesktopDidActivate object: self];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName: kPnOnDesktopDidActivate object: nil userInfo: infoDict];
  
	// tony@tonyarnold.com: Previously, I would insert a usleep(100000); here, so that the desktop picture had time to update before the transition was released. I think we need to find a faster way to set the desktop picture and get it onscreen - or accept the fact that desktop picture transitions are something that will only display properly on fast machines.
		
	// Run the transition	
	CGSInvokeTransition(cgs, handle, seconds);
		
	// We need to wait for the length of the transition before releasing
	usleep((useconds_t)(seconds*1000000));
		
	// Now release the transition from memory
	CGSReleaseTransition(cgs, handle);
    handle = 0;
    
    [mActiveApp activate];
}

- (BOOL) activateTopApplication
{
    return [self activateTopApplicationIgnoring:nil];
}

- (BOOL) activateTopApplicationIgnoring: (PNApplication *) ignored
{
    PNApplication*  application         = nil;
    NSEnumerator*   enumerator          = [mApplications objectEnumerator];
	int				realCount			= 0;
    
    if (mActiveApp != nil && ![mActiveApp isSticky] && [mActiveApp activate]) {
        return FALSE;
    }
	
	// count non-hidden applications and remember the first non-hidden application we encounter for later use
    while (application = [enumerator nextObject]) {
        if ([application isHidden] == NO && [application isUnfocused] == NO && [application pid] != [ignored pid]) {
            realCount++;
        }
    }
	
	// more than one application means, we have at least one application but the finder active, so lets return 
	if (realCount <= 1) {
        return FALSE;
	}

	// we will exclude applications that were set as "hidden", that is why we have to loop here
    PNWindow *frontWindow = nil;
    enumerator = [mWindows objectEnumerator];
    while (frontWindow = [enumerator nextObject]) {
		PNApplication*	frontWindowOwner	= [self applicationForPid: [frontWindow ownerPid]]; 
		
		if ([frontWindowOwner isHidden] == NO && [frontWindowOwner isUnfocused] == NO && [frontWindowOwner pid] != [ignored pid]) {
            if ([frontWindowOwner activate]) {
                [self setActiveApplication: frontWindowOwner];
                return TRUE;
            }
		}
	}
    return FALSE;
}

- (void) setActiveApplication: (PNApplication*) application
{
    if ([application isSticky] || [application isUnfocused] || [self applicationForPid:[application pid]] == nil) {
        return;
    }
    ZEN_RELEASE(mActiveApp);
    ZEN_ASSIGN(mActiveApp, application);
}

- (PNApplication*) activeApplication
{
    return mActiveApp;
}

#pragma mark -
#pragma mark Window operations

- (void) moveAllWindowsToDesktop: (PNDesktop*) desktop 
{
	// Update to ensure all our windows are listed and current
	[self updateDesktop];
	
	// Now go through the window list and move them to the new desktop
	NSEnumerator*		windowIter = [mWindows objectEnumerator];
	PNWindow*				window		 = nil;
  
	// TODO: Move functionality to use a PNWindowList for mass-window operations
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

/*!
 @method orderWindowBack
 @brief Orders the passed window to the back of the current desktop
 @param window  Window to order to the back
 */
- (void) orderWindowBack: (PNWindow*) window {
  if ([mWindows count] == 0)
    return;
  
  PNWindow* bmWindow = [self bottomMostWindow];
  
  if (!bmWindow)
    return;
  
  if (bmWindow == window)
    return;
  
  [window orderBelow: bmWindow];
}

/*!
 @method    sendWindowUnderCursorBack
 @abstract  Sends the window under cursor behind all windows on the desktop
 */
- (void) sendWindowUnderCursorBack
{
    PNWindow* wcpWindow = [self windowUnderCursor];
    if (!wcpWindow)
        return;
  
    [self orderWindowBack: wcpWindow];
}

#pragma mark -
#pragma mark Moving windows

/*!
 @method    moveWindowUnderCursorToDesktop:
 @abstract  Sends the window under the cursor to the specified desktop
 @param     desktop   The target desktop
 */
- (void) moveWindowUnderCursorToDesktop: (PNDesktop*) desktop
{
    PNWindow* wcpWindow = [self windowUnderCursor];
    if (!wcpWindow)
        return;

    [wcpWindow setDesktop: desktop];
}


#pragma mark -
#pragma mark Updating
- (PNApplication*)applicationForWindow:(PNWindow*)window
{
	PNApplication *application = [mApplications objectForKey: [NSNumber numberWithInt: [window ownerPid]]];
	
	// if the application container does not contain a reference to the application, create a new one
	if (application == nil)
	{
		application = [[PNApplication alloc] initWithPid: [window ownerPid] onDesktop: self];
		
		if (application != nil)
		{
			// and attach
			[self attachApplication: application];
		}
		
		[application autorelease];
		
	}
	
	return application;
}

- (int)numberOfWindows
{
	ZNLog(@"Starting");
	// get connection
	CGSConnection connection = _CGSDefaultConnection();
	ZNLog(@"Created connection");
	OSStatus result;
	
	int numberOfWindows = -1;
	
	// first we have to query for the number of windows in our workspace
	result = CGSGetWorkspaceWindowCount(connection, mDesktopId, &numberOfWindows);
	ZNLog(@"Queried workspace for number of windows");
	if (result)
	{
		ZNLog( @"[Desktop %i] CGSGetWorkspaceWindowCount failed [%i]", mDesktopId, result);
	}
	ZNLog(@"Ending");
	return numberOfWindows;
}

- (NSData*)windowsInWorkspaceUptoIndex:(int)index numberRetrieved:(int*)retrieved
{
	ZNLog(@"Starting");
	CGSConnection connection = _CGSDefaultConnection();
	ZNLog(@"Created connection");
	NSMutableData *windows = nil;
	OSStatus result;
	// query the list of windows in our workspace
	windows = [NSMutableData dataWithCapacity: index * sizeof(int)];
	ZNLog(@"Created windows variable");
	result = CGSGetWorkspaceWindowList(connection, mDesktopId, index, [windows mutableBytes], (int*)&retrieved);
	ZNLog(@"Queried workspace for list of windows");
	if (result) 
	{
		ZNLog( @"[Desktop %i] CGSGetWorkspaceWindowList failed [%i]", mDesktopId, result);
	}
	ZNLog(@"Ending");
	return windows;
}

- (void)addWindows:(NSArray*)windows
{
	ZNLog(@"Starting");

	NSEnumerator *windowsEnumerator = [windows objectEnumerator];
	PNWindow *window = nil;
	
	ZNLog(@"Going to loop over windows to add");
	while (window = [windowsEnumerator nextObject])
	{
		[mWindows addObject:window];
		ZNLog(@"Window added in array");
		
		PNApplication *application = [self applicationForWindow:window];
		ZNLog(@"Got application for window");
		if ([application isValid])
		{
			[application bindWindow:window];
			[self attachApplication:application];
			ZNLog(@"Bound window");
		}
	}
	
	ZNLog(@"Ended");
}

- (void)removeWindows:(NSArray*)windows
{
	ZNLog(@"Starting");
	// All windows that are still left in the copied window list were not touched by the loop above and are no longer on the desktop, so we will remove them from the list of windows
	NSEnumerator *windowsEnumerator = [windows objectEnumerator];
	PNWindow *window = nil;
	
	ZNLog(@"Going to loop over windows to remove");
	while (window = [windowsEnumerator nextObject])
	{    
		[mWindows removeObject: window];
		ZNLog(@"Removed window from array");
		// handle application windows
		PNApplication *application = [self applicationForWindow: window];
		ZNLog(@"Got application for window");
		// check if the application is still valid
		if ([application isValid])
		{
			[application unbindWindow: window];
			ZNLog(@"Unbound window");
			// check if there are still windows contained in the application wrappers and
			// remove the application if there are none...
			if ([[application windows] count] == 0)
			{
				[self detachApplication: application];
				ZNLog(@"Detached application");
			}
		}
		else
		{
			[self detachApplication: application];
			ZNLog(@"Detached application");
		}
		
		// and post notification that the window was removed
		[[NSNotificationCenter defaultCenter] postNotificationName: kPnOnWindowRemoved object: window];
		ZNLog(@"Posted notification");
	}
	ZNLog(@"Ended");
}

- (void)nonExistentWindowsAfterSyncing:(NSMutableArray*)newWindows withExistentWindows:(NSMutableArray*)oldWindows
{
	ZNLog(@"Starting");
	NSData* windows = nil;
	
	int numberOfWindows = [self numberOfWindows];
	ZNLog(@"Got number of windows");
	int i = 0;
	
	// if the number of desktops is 0, we will skip fetching windows
	if (numberOfWindows == 0)
	{
		ZNLog(@"No window to treat");
		return;
	}
	
	windows = [self windowsInWorkspaceUptoIndex: numberOfWindows numberRetrieved: &numberOfWindows];
	ZNLog(@"Got list of windows");
	
	int *windowIds = (int*)[windows bytes];
	ZNLog(@"Created window IDs");
	// Now we can start synchronizing. We will iterate over all windows and check if we already know about them. If we find a window we do not know, we will add it. we will also remove windows we found from the copy.
	ZNLog(@"Going to loop over windows");
	for ( i = 0; i < numberOfWindows; i++ )
	{
		// get entry from list of fetched windows
		CGSWindow windowId = windowIds[i];
		
		// get the window proxy
		PNWindow* window = [PNWindow windowWithWindowId: windowId];		
		// ignore menus, and windows that are marked special
		if (window == nil || [window isMenu] || [window isSpecial])
		{
			continue;
		}

		// If it is a utility palette, we should make it sticky, so palettes don't get lost across desktops
		if ([window isPalette])
		{
			[window setSticky: YES];
			ZNLog(@"Set window to be sticky");
		}
			
		if ([mWindows containsObject:window] == NO)
		{
			[newWindows addObject: window];
			ZNLog(@"Inserted window in new window array");			
		}
		else
		{
			// we already knew about this window, and it apparently still exists, so we will remove it from the list of previous windows
			[oldWindows addObject: window];
			ZNLog(@"Window will be considered dead");
		}
	}
	ZNLog(@"Ending");
}

/*!
  @method     updateDesktop
  @abstract   Clear the list of windows and fetch all windows in the workspace
  @discussion Queries windows for the wrapped desktop and adds new windows not yet contained in the internal list of windows. Windows that are contained in the internal list but were not returned by the windows query, will be removed from the internal list. We also try to validate all sticky windows in this run and remove invalid sticky windows (those that were closed) from the sticky window list. 
 
      This method is inherently costly, it should not be called every millisecond and the caller should be prepared to wait a bit here.
 */
- (void)updateDesktop 
{
	if (mDesktopId < 0)
	{
		return;
	}
	ZNLog(@"Starting");
	
	// Copy the current list of windows for cross checking
	NSMutableArray* previousWindows = [[NSMutableArray alloc] initWithArray: [self windows]];
	NSMutableArray* newWindows		= [[NSMutableArray alloc] init];
	NSMutableArray* oldWindows		= [[NSMutableArray alloc] init];
	
	[self nonExistentWindowsAfterSyncing:newWindows withExistentWindows:oldWindows];
	[previousWindows removeObjectsInArray:oldWindows];
	ZNLog(@"Clean window list");
	
	// now handle sticky windows, this will only change the window list, if we are not the active desktop
	PNStickyWindowCollection *stickyWindowCollection = [PNStickyWindowCollection stickyWindowCollection];
	NSArray *stickyWindowsCopy						 = [stickyWindowCollection windows];
	NSEnumerator *stickyIter						 = [stickyWindowsCopy objectEnumerator];
	PNWindow *stickyWindow							 = nil;
	
	while (stickyWindow = [stickyIter nextObject])
	{
		// we take the chance and remove all the sticky windows that are no longer valid
		if (![stickyWindow isValid])
		{
			[stickyWindowCollection delWindow: stickyWindow];
			if ([previousWindows containsObject: stickyWindow] == NO)
			{
				[previousWindows addObject:stickyWindow];      
				[[NSNotificationCenter defaultCenter] postNotificationName: kPnOnWindowRemoved object: stickyWindow];
				ZNLog(@"Posted notification");
			}
		}
		else
		{
			// remove from previous list if it is there
			[previousWindows removeObject: stickyWindow];
			ZNLog(@"Removed window from dead windows");
      
			if (stickyWindow != nil && ([stickyWindow isSpecial] == NO) && ([mWindows containsObject: stickyWindow] == NO))
			{
				[newWindows addObject:stickyWindow];
			}
		}
	}

	[self willChangeValueForKey: @"windows"]; 
	[self removeWindows: previousWindows];
	ZNLog(@"Removed dead windows");
	[self addWindows: newWindows];
	ZNLog(@"Add new windows");
	[self didChangeValueForKey: @"windows"]; 

	
	ZNLog(@"Ending");
	
	// clear the list of previous windows
	[previousWindows release];
	[newWindows release];
	[oldWindows release];
}


#pragma mark -
#pragma mark Queries

/**
 * @brief Finds the topmost window placed under the mouse cursor
 */
- (PNWindow*) windowUnderCursor {
    if (![self visible])
        return nil;

    NSPoint mouseLoc = [NSEvent mouseLocation];
    NSSize screenSize = [[NSScreen mainScreen] frame].size;
    mouseLoc.y = screenSize.height - mouseLoc.y;
    return [self windowContainingPoint: mouseLoc];
}

/**
 * @brief Finds the topmost window in the hierarchy containing the passed point
 *
 * @param point Point to search for
 *
 * The method will skip windows marked as special and windows not living on the
 * kCGNormalWindowLevel window level
 *
 */
- (PNWindow*) windowContainingPoint: (NSPoint) point 
{
	// iterate windows until we find a window containing the passed
	// point or we reached the end of the list. we will not consider
	// windows that were marked as special
  
	NSEnumerator*		windowIter	= [mWindows objectEnumerator];
	PNWindow*				window	= nil;
    PNWindow*             selected  = nil;        
  
	while (window = [windowIter nextObject]) {
		//if ([window isSpecial])
		//	continue;
		//if ([window level] != kCGNormalWindowLevel)
		//	continue;
    
		// fetch the screen rect to check
		NSRect	windowRect = [window screenRectangle];
    
		if (NSMouseInRect(point, windowRect, NO)) {
            if (selected != nil) {
                if ([window level] > [selected level]) {
                    selected = window;
                } else if ([window level] == [selected level]) {
                    PNApplication *application = [self applicationForWindow:window];
                    if ([application isFrontmost]) {
                        selected = window;
                    }
                }
            } else {
                selected = window;
            }
		}
	}
  
    if (selected == nil || [selected isSticky]) {
        return nil;
    } else {
        return selected;
    }
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
- (PNApplication*) applicationForPid: (pid_t) pid 
{
	return [mApplications objectForKey: [NSNumber numberWithInt: pid]];
}

/**
 * @brief Searches for the application with the passed PSN
 *
 * @param psd Process Serial Number for the application to return
 *
 * @return Returns the application instance matching the passed psn or @c nil
 *         if the desktop does not contain an application with the passed psn
 */
- (PNApplication*) applicationForPSN: (ProcessSerialNumber) psn
{
	OSStatus status;
	pid_t    pid;
	status = GetProcessPID(&psn, &pid);
	if (status) {
		return nil;
	}
	return [self applicationForPid:pid];
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
- (PNWindow*) windowForId: (CGSWindow) window 
{
	return [self windowWithId: window];
}

/**
* @brief Searches for the bottom-most window
 *
 * @return	Returns the bottom-most window if any or nil
 *
 */
- (PNWindow*) bottomMostWindow {
  int nWindows = [mWindows count];
  if (nWindows == 0)
    return nil;
  
  PNWindow* window = (PNWindow*)[mWindows objectAtIndex: (nWindows - 1)];
  
  if (!window)
    return nil;
  
  return window;
}

/**
* @todo	Remove and change over to windowForId
 *
 */
- (PNWindow*) windowWithId: (CGSWindow) windowId 
{
	// iterate through the list of windows until we find the passed window id
	NSEnumerator*		windowIter	= [mWindows objectEnumerator];
	PNWindow*       window		= nil;
  
	while (window = [windowIter nextObject]) {
		if ([window nativeWindow] == windowId)
			return window;
	}
  
	return nil;
}

- (id) initWithId: (int) desktopId andName: (NSString*) name update: (BOOL) update 
{
	if (self = [super init]) {
		// initialise attributes
		mDesktopId		= desktopId;
		mDesktopName	= [name retain];
		mWindows      = [[NSMutableArray array] retain];
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
- (void) detachApplication: (PNApplication*) application 
{
	if (application == nil || [application path] == nil)
	{
		return;
	}
  
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys: application, PNApplicationInstanceParam, self, PNApplicationDesktopParam, nil];
  
	[mApplications removeObjectForKey: [NSNumber numberWithInt: [application pid]]];
    
    if ([mActiveApp pid] == [application pid]) {
        ZEN_RELEASE(mActiveApp);
    }
  
	// and post notification
	[self willChangeValueForKey: @"applications"];
	[self didChangeValueForKey: @"applications"];
	[[NSNotificationCenter defaultCenter] postNotificationName: PNApplicationWasRemoved object: [application path] userInfo: userInfo];
}

- (void) attachApplication: (PNApplication*) application 
{
	if (application == nil || [application path] == nil)
	{
		return;
	}
	
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys: application, PNApplicationInstanceParam, self, PNApplicationDesktopParam, nil];
  
	[mApplications setObject: application forKey: [NSNumber numberWithInt: [application pid]]];
	
	// and post notification
	[self willChangeValueForKey: @"applications"];
	[self didChangeValueForKey: @"applications"];
	[[NSNotificationCenter defaultCenter] postNotificationName: PNApplicationWasAdded object: [application path] userInfo: userInfo];
}

@end