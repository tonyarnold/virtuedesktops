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

+ (id) sharedWindowPool 
{
	static PNWindowPool* ms_oINSTANCE = nil; 
	
	if (ms_oINSTANCE == nil)
  {
		ms_oINSTANCE = [[PNWindowPool alloc] init];  
	}
  
	return ms_oINSTANCE; 
}

- (id) init 
{
	if (self = [super init]) 
  {
		mWindows = [[NSMutableDictionary alloc] init]; 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onWindowRemoved:) name: kPnOnWindowRemoved object: nil]; 
		return self; 
	}
	
	return nil; 
}

- (void) dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver: self]; 
	[mWindows release]; 
	[super dealloc]; 
}

#pragma mark -
#pragma mark Methods

- (PNWindow*) windowWithId: (CGSWindow) windowId 
{
  // If the window is not present in the current pool, create a new instance with the specified ID and add it
	if ([mWindows objectForKey: [NSNumber numberWithInt: windowId]] == nil) {
		[mWindows setObject: [[PNWindow alloc] initWithWindowId: windowId] forKey: [NSNumber numberWithInt: windowId]];
	}
  
	return [mWindows objectForKey: [NSNumber numberWithInt: windowId]]; 
}

#pragma mark -
#pragma mark Notification Sinks 

- (void) onWindowRemoved: (NSNotification*) notification 
{
	// Remove the dead window proxy as it is no longer contained in any desktop
	[mWindows removeObjectForKey: [NSNumber numberWithInt: [(PNWindow*)[notification object] nativeWindow]]];
}

@end
