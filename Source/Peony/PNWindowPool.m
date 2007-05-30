/*
	PNWindowPool.m
	See COPYING for licensing details
	Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
	Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com>
 */

#import "PNWindowPool.h"
#import "PNWindow.h" 
#import "PNNotifications.h" 

@implementation PNWindowPool

#pragma mark -
#pragma mark Initialization and lifecycle

+ (PNWindowPool*) sharedWindowPool 
{
	static PNWindowPool* ms_INSTANCE = nil; 
	
	if (ms_INSTANCE == nil)
    {
		ms_INSTANCE = [[PNWindowPool alloc] init];  
	}
  
	return ms_INSTANCE; 
}

- (id) init 
{
	if (self = [super init]) 
  {
		_windowDict = [[NSMutableDictionary alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onWindowRemoved:) name: kPnOnWindowRemoved object: nil]; 
		return self; 
	}
	
	return nil; 
}

- (void) dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver: self]; 
	[_windowDict release];
	[super dealloc]; 
}

#pragma mark -
#pragma mark Methods

- (PNWindow*) windowWithId: (CGSWindow) windowId 
{
	NSNumber *number = [NSNumber numberWithInt: windowId];
    // If the window is not present in the current pool, create a new instance with the specified ID and add it
	if ([_windowDict objectForKey:number] == nil) 
    {
		[_windowDict setObject: [[PNWindow alloc] initWithWindowId: windowId] forKey:number];
    }
    
	return [_windowDict objectForKey:number]; 
}

- (PNWindowList*) windowsOnDesktopId: (int) desktopId
{
    PNWindowList *list = [[PNWindowList alloc] init];
    NSEnumerator *iter = [_windowDict objectEnumerator];
    PNWindow     *window = nil;
    
    while (window = [iter nextObject]) {
        if ([window desktopId] == desktopId) {
            [list addWindow:window];
        }
    }
    return list;
}

#pragma mark -
#pragma mark Notification Sinks 

- (void) onWindowRemoved: (NSNotification*) notification 
{
	// Remove the dead window proxy as it is no longer contained in any desktop
	[_windowDict removeObjectForKey: [NSNumber numberWithInt: [(PNWindow*)[notification object] nativeWindow]]];
}

@end
