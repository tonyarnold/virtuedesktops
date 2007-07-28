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

#import "VTLayoutPreferencesController.h"
#import "VTLayout.h"
#import "VTLayoutController.h"
#import "NSUserDefaultsColor.h" 

#pragma mark -
@interface VTLayoutPreferencesController (Selection)
- (void) prepareSelectables; 
- (void) selectLayout: (VTDesktopLayout*) layout; 
- (VTDesktopLayout*) selectedLayout; 
@end 

#pragma mark -
@implementation VTLayoutPreferencesController

#pragma mark -
#pragma mark NSPreferencePane Delegate 

- (void) mainViewDidLoad {
	// prepare
	[self prepareSelectables]; 
	// and select the initially shown layout
	[self selectLayout: [self selectedLayout]];
}

- (void) willUnselect {
	// we have to persist the desktop layout to be sure we do not loose any setting
	// here... 
	[[VTLayoutController sharedInstance] synchronize]; 
	[[NSUserDefaults standardUserDefaults] synchronize]; 
}

#pragma mark -
#pragma mark Actions 

- (void) onPagerSelected: (id) sender {
	[self selectLayout: [self selectedLayout]]; 
}

#pragma mark -
#pragma mark Accessors 
- (VTDesktopLayout*) activeLayout {
	return [[VTLayoutController sharedInstance] activeLayout]; 
}

@end 

#pragma mark -
@implementation VTLayoutPreferencesController (Selection) 

- (void) prepareSelectables {
	// set up available layout button 
//	[mLayoutList removeAllItems]; 
//	
//	NSMenuItem* menuItem; 
//	
//	NSEnumerator*			layoutIter	= [[[VTLayoutController sharedInstance] layouts] objectEnumerator]; 
//	VTDesktopLayout*	layout			= nil; 
//	int								activeIndex	= -1; 
//	
//	while (layout = [layoutIter nextObject]) {
//		menuItem = [[[NSMenuItem alloc] initWithTitle: [layout name] action: @selector(onPagerSelected:) keyEquivalent: @""] autorelease]; 
//		[menuItem setRepresentedObject: layout]; 
//		[[mLayoutList menu] insertItem: menuItem atIndex: [mLayoutList numberOfItems]]; 
//		
//		if ([layout isEqual: [[VTLayoutController sharedInstance] activeLayout]]) 
//			activeIndex = [mLayoutList numberOfItems] - 1; 
//	}	
//	
//	// and set up 
//	[mLayoutList selectItemAtIndex: activeIndex];
}

- (void) selectLayout: (VTDesktopLayout*) layout {
	// check for selected pager item and update content views accordingly
	//if ([NSStringFromClass([[[mLayoutList selectedItem] representedObject] class]) isEqualToString: @"VTMatrixDesktopLayout"]) {
		// this is our built-in pager 
		[mLayoutContainer setContentView: mMatrixLayoutView]; 
		
	//	return; 
	//}
	
	// else check views and set them for the plugin 	
}

- (VTDesktopLayout*) selectedLayout {
//	return [[mLayoutList selectedItem] representedObject]; 
    return nil;
}

@end 

