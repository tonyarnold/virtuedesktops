/****************************************************************************
 *
 Peony framework
 *
 * A desktop extension for MacOS X
 *
 * Copyright 2004, Thomas Staller <playback@users.sourceforge.net>
 * Copyright 2007, Tony Arnold <tony@tonyarnold.com>
 *
 * See COPYING for licensing details
 *
 ****************************************************************************/

#import "PNWindowPool.h"
#import "PNWindow.h" 
#import "PNNotifications.h" 

@implementation PNWindowPool

#pragma mark -
#pragma mark Lifetime 

+ (id) sharedWindowPool {
	static PNWindowPool* ms_oINSTANCE = nil; 
	
	if (ms_oINSTANCE == nil)
		ms_oINSTANCE = [[PNWindowPool alloc] init];  
	
	return ms_oINSTANCE; 
}

- (id) init {
	if (self = [super init]) {
		// initialize attributes 
		mWindows = [[NSMutableDictionary dictionary] retain]; 
		// register observers 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onWindowRemoved:) name: kPnOnWindowRemoved object: nil]; 
	
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	// unregister 
	[[NSNotificationCenter defaultCenter] removeObserver: self]; 
	// release attributes 
	[mWindows release]; 
	// super...
	[super dealloc]; 
}

#pragma mark -
#pragma mark Operations 

- (PNWindow*) windowWithId: (CGSWindow) windowId {
	// try to find it in our dictionary 
	PNWindow* window = [mWindows objectForKey: [NSNumber numberWithInt: windowId]]; 
	
	// create and add it if necessary 
	if (window == nil) {
		window = [[PNWindow alloc] initWithWindowId: windowId]; 
		[mWindows setObject: window forKey: [NSNumber numberWithInt: windowId]]; 
		// releasing window as retained by the dictionary 
	}
	
	return window; 
}

#pragma mark -
#pragma mark Notification Sinks 

- (void) onWindowRemoved: (NSNotification*) notification {
	PNWindow* window = [notification object]; 
		
#if 0
	// check if the window is still valid, and if it isn't remove it form the map
	if ([window isValid])
		return; 
#endif 
	
	// hmm, now we remove the dead window proxy as it is no longer contained in any 
	// desktop
	[mWindows removeObjectForKey: [NSNumber numberWithInt: [window nativeWindow]]]; 
}

@end
