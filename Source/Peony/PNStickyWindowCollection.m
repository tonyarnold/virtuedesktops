//
//  PNStickyWindowCollection.m
//  Peony framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import "PNStickyWindowCollection.h"
#import "PNNotifications.h" 

@implementation PNStickyWindowCollection

+ (id) stickyWindowCollection
{
	static PNStickyWindowCollection* msINSTANCE = nil; 
  
	if (msINSTANCE == nil)
		msINSTANCE = [[PNStickyWindowCollection alloc] init]; 
	
	return msINSTANCE; 
}

- (id) init
{
	if (self = [super init])
	{
		// initialize attributes 
		mWindows = [[PNWindowList alloc] init]; 
		
		// register observers 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopWillActivate:) name: kPnOnDesktopWillActivate object: nil]; 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopDidActivate:) name: kPnOnDesktopDidActivate object: nil]; 		
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onWindowStickied:) name: kPnOnWindowStickied object: nil]; 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onWindowUnstickied:) name: kPnOnWindowUnstickied object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onApplicationStickied:) name: kPnOnApplicationStickied object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onApplicationUnstickied:) name: kPnOnApplicationUnstickied object: nil];
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc
{
	// unregister observers 
	[[NSNotificationCenter defaultCenter] removeObserver: self]; 
	// release attributes 
	[mWindows release]; 
	
	[super dealloc]; 
}

- (void) addWindow: (PNWindow*) window
{
	[mWindows addWindow: window]; 
}

- (void) delWindow: (PNWindow*) window
{
	[mWindows delWindow: window]; 
}

- (NSArray*) windows 
{
	return [mWindows windows];  
}

#pragma mark Notification sinks 

- (void) onDesktopWillActivate: (NSNotification*) aNotification
{
	// sticky all windows in our list to transfer them over to the next desktop 
	[mWindows setSticky: YES];
}

- (void) onDesktopDidActivate: (NSNotification*) aNotification
{
	// Ensure that our window will actually show up given that we're switching sticky windows off after the switch
	[mWindows setDesktop: (PNDesktop*)[aNotification object]];
	
	// unsticky all windows to have them show up in the window lists returned by the CGSGetWorkspaceWindowList functions (is this intended behaviour or a bug in that function?)
	[mWindows setSticky: NO];
}

- (void) onWindowStickied: (NSNotification*) aNotification
{
	// fetch the window that was just stickied and add it to our list 
	[self addWindow: [aNotification object]]; 
}

- (void) onWindowUnstickied: (NSNotification*) aNotification
{
	// fetch the window that was just unstickied and remove it from our list
	[self delWindow: [aNotification object]]; 
}

- (void) onApplicationStickied: (NSNotification*) aNotification
{
	// fetch the windows that were just stickied and add them to our list 
	[mWindows addWindows: [aNotification object]];
  
  // Ideally, we'd also move the windows affected to the current desktop as well
}

- (void) onApplicationUnstickied: (NSNotification*) aNotification
{
	// fetch the windows that were just unstickied and remove them from our list 
	[mWindows delWindows: [aNotification object]];
}

@end
