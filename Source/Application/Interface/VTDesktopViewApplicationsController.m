/******************************************************************************
* 
* Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTDesktopViewApplicationsController.h"
#import <Zen/Zen.h> 
#import "Peony/Peony.h" 

@interface VTDesktopViewApplicationsController(Private)
- (void) updateStickyButton; 
@end

#pragma mark -
@implementation VTDesktopViewApplicationsController

#pragma mark -
#pragma mark Lifetime 
- (id) init {
	if (self = [super init]) {
		// attributes 
		mDesktop = nil; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mDesktop); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 
- (void) setDesktop: (VTDesktop*) desktop {
	ZEN_ASSIGN(mDesktop, desktop); 
	
	[mApplicationView reloadData]; 
}

#pragma mark -
#pragma mark Actions 
- (IBAction) toggleSticky: (id) sender {
	// first, get selected item 
	// fetch our selection 
	int selectionIndex = [mApplicationView selectedRow]; 
	
	if (selectionIndex == -1)
		return; 
	
	id selectedItem = [mApplicationView itemAtRow: selectionIndex]; 
	
	if (([selectedItem isKindOfClass: [PNApplication class]] == NO) &&
		([selectedItem isKindOfClass: [PNWindow class]] == NO))
		return; 
		
	// now toggle the sticky state 
	if ([selectedItem isSticky])
		[selectedItem setSticky: NO]; 
	else
		[selectedItem setSticky: YES]; 
	
	// we have to reload the data now 
	[mApplicationView reloadItem: selectedItem reloadChildren: YES]; 
	// and update our button 
	[self updateStickyButton]; 
}


#pragma mark -
#pragma mark NSObject

- (void) awakeFromNib {
	// set button images 
	[mStickyButton setImage: [NSImage imageNamed: @"imageWidgetSticky.png"]]; 
	[mStickyButton setAlternateImage: [NSImage imageNamed: @"imageWidgetStickyPressed.png"]]; 
	// tooltip
	[mStickyButton setToolTip: @"Toggle sticky state of window or whole application"]; 
	// disable per default 
	[mStickyButton setEnabled: NO]; 
}

#pragma mark -
#pragma mark NSOutlineView DataSource implementation 

- (id) outlineView: (NSOutlineView*) outlineView child: (int) index ofItem: (id) item {
	if (item == nil) {
		// fetch application
		return [[mDesktop applications] objectAtIndex: index]; 
	}
	
	if ([item isKindOfClass: [PNApplication class]]) {
		PNApplication*	application			= (PNApplication*)item; 
		NSArray*		applicationWindows	= [application windows];
		
		return [applicationWindows objectAtIndex: index]; 
	}
	
	// nothing if we are not asked for the toplevel item or the item is no
	// application object 
	return nil; 
}

- (BOOL) outlineView: (NSOutlineView*) outlineView isItemExpandable: (id) item {
	if ([item isKindOfClass: [PNWindow class]])
		return NO; 
	
	return YES; 
}

- (int) outlineView: (NSOutlineView*) outlineView numberOfChildrenOfItem: (id) item {
	if (item == nil) 
		return [[mDesktop applications] count]; 
	
	if ([item isKindOfClass: [PNApplication class]]) {
		PNApplication*	application			= (PNApplication*)item; 
		NSArray*		applicationWindows	= [application windows]; 
		
		return [applicationWindows count]; 
	}
	
	return 0; 
}

- (id) outlineView: (NSOutlineView*) outlineView objectValueForTableColumn: (NSTableColumn*) tableColumn byItem: (id) item {
	if ([item isKindOfClass: [PNApplication class]]) {
		// provide data for the application 
		if ([[tableColumn identifier] isEqualToString: @"icon"]) {
			NSImage*	icon		= [(PNApplication*)item icon]; 
			NSSize		iconSize	= NSMakeSize(16, 16); 
			[icon setSize: iconSize]; 
			
			return icon; 
		}
		else if ([[tableColumn identifier] isEqualToString: @"name"]) {
			return [(PNApplication*)item name];
		}
		else if ([[tableColumn identifier] isEqualToString: @"sticky"]) {
			if ([(PNApplication*)item isSticky]) 
				return [NSImage imageNamed: @"imageIsSticky.png"]; 

			return nil; 
		}
	}
	else if ([item isKindOfClass: [PNWindow class]]) {
		// provide data for the window 
		if ([[tableColumn identifier] isEqualToString: @"icon"])
			return nil; 
		else if ([[tableColumn identifier] isEqualToString: @"name"]) {
			NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys: 
				[NSFont labelFontOfSize: [NSFont labelFontSize]], NSFontAttributeName,
				[NSColor darkGrayColor], NSForegroundColorAttributeName, 
				nil]; 
			
			return [[[NSAttributedString alloc] initWithString: [(PNWindow*)item name] attributes: attributes] autorelease]; 
		}
		else if ([[tableColumn identifier] isEqualToString: @"sticky"]) {
			if ([(PNWindow*)item isSticky]) 
				return [NSImage imageNamed: @"imageIsSticky.png"]; 
			
			return nil; 
		}
	}
	
	return nil; 
}


- (void) outlineViewSelectionDidChange: (NSNotification*) notification {
	[self updateStickyButton]; 
}

@end

#pragma mark -
@implementation VTDesktopViewApplicationsController(Private) 

- (void) updateStickyButton {
	// fetch our selection 
	int selectionIndex = [mApplicationView selectedRow]; 
	
	if (selectionIndex == -1) {
		// disable our sticky button 
		[mStickyButton setEnabled: NO]; 
		// return
		return; 
	}
	
	id selectedItem = [mApplicationView itemAtRow: selectionIndex]; 
	
	if ([selectedItem isKindOfClass: [PNApplication class]] ||
		[selectedItem isKindOfClass: [PNWindow class]]) {
		// enable our button 
		[mStickyButton setEnabled: YES]; 
		
		// and make sure we are displaying the correct button images 
		BOOL isSticky = [selectedItem isSticky]; 
		
		if (isSticky) {
			[mStickyButton setImage: [NSImage imageNamed: @"imageWidgetUnsticky.png"]]; 
			[mStickyButton setAlternateImage: [NSImage imageNamed: @"imageWidgetUnstickyPressed.png"]]; 
		}
		else {
			[mStickyButton setImage: [NSImage imageNamed: @"imageWidgetSticky.png"]]; 
			[mStickyButton setAlternateImage: [NSImage imageNamed: @"imageWidgetStickyPressed.png"]]; 
		}	
	}
}

@end 
