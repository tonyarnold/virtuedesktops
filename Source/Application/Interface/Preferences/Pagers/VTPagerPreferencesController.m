/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2007, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTPagerPreferencesController.h"
#import "VTPreferences.h"
#import "VTLayoutController.h"
#import "NSUserDefaultsColor.h"

@interface VTPagerPreferencesController(Private) 
- (void) selectPager; 
@end 

#pragma mark -
@implementation VTPagerPreferencesController

#pragma mark -
#pragma mark NSPreferencePane 

- (void) mainViewDidLoad {
	// Set-up available layout button 
	[mAvailablePagerButton removeAllItems]; 

	NSMenuItem* menuItem; 
	
	NSEnumerator*			layoutIter	= [[[VTLayoutController sharedInstance] layouts] objectEnumerator]; 
	VTDesktopLayout*	layout		= nil; 
	int								activeIndex	= -1; 
	
	while (layout = [layoutIter nextObject]) {
		menuItem = [[[NSMenuItem alloc] initWithTitle: [layout name] action: @selector(onPagerSelected:) keyEquivalent: @""] autorelease]; 
		[menuItem setRepresentedObject: layout]; 
		[[mAvailablePagerButton menu] insertItem: menuItem atIndex: [mAvailablePagerButton numberOfItems]]; 
		
		if ([layout isEqual: [[VTLayoutController sharedInstance] activeLayout]]) 
			activeIndex = [mAvailablePagerButton numberOfItems] - 1; 
	}	
	
	[mAvailablePagerButton selectItemAtIndex: activeIndex]; 
	[self selectPager]; 
}
	
#pragma mark -
#pragma mark Actions 

- (void) onPagerSelected: (id) sender {
	[self selectPager]; 
}

#pragma mark -
#pragma mark Color helpers 

#pragma mark -
#pragma mark Attributes 
- (VTDesktopLayout*) activeLayout {
	return [[VTLayoutController sharedInstance] activeLayout]; 
}

@end

@implementation VTPagerPreferencesController(Private) 

- (void) selectPager {
	// check for selected pager item and update content views accordingly
	if ([[[[mAvailablePagerButton selectedItem] representedObject] name] isEqualToString: @"Matrix Layout"] || [[[[mAvailablePagerButton selectedItem] representedObject] name] isEqualToString: @"Fixed Matrix Layout"]) {
		// this is our built-in pager 
		[mAppearanceTabItem setView: mAppearanceView]; 
		[mBehaviourTabItem setView: mBehaviourView]; 
		
		return; 
	}
	
	// else check views and set them for the plugin 
	
}

@end 
