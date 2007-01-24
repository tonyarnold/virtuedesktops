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

#import "VTBehaviourPreferencesController.h"
#import "VTHotkeyController.h"
#import "VTHotkeyGroup.h"
#import "VTHotkeyNotification.h"
#import "VTHotkey.h"
#import "VTHotkeyController.h"
#import "VTHotkeyCell.h" 
#import <Zen/Zen.h> 

@implementation VTBehaviourPreferencesController

#pragma mark -
#pragma mark Lifetime 
- (void) dealloc {
	[mNavigationGroup removeObserver: self forKeyPath: @"notifications"]; 
	ZEN_RELEASE(mNavigationGroup); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark NSOutlineView DataSource 

- (id) outlineView: (NSOutlineView*) outlineView child: (int) index ofItem: (id) item {
	if (item == nil) {
		// fetch top level items by index 
		return [[[VTHotKeyController sharedInstance] items] objectAtIndex: index]; 
	}
	
	if ([item isKindOfClass: [VTHotkeyGroup class]]) {
		// return notification from the hotkey group represented by the item 
		return [[item items] objectAtIndex: index]; 
	}
	
	return nil; 
}

- (BOOL) outlineView: (NSOutlineView*) outlineView isItemExpandable: (id) item {
	if ([item isKindOfClass: [VTHotkeyNotification class]])
		return NO; 
	
	return YES; 
}

- (int) outlineView: (NSOutlineView*) outlineView numberOfChildrenOfItem: (id) item {
	if ([item isKindOfClass: [VTHotkeyNotification class]])
		return 0; 
	
	if (item == nil)
		return [[[VTHotKeyController sharedInstance] items] count]; 
	
	// return notification from the hotkey group represented by the item 
	return [[item items] count]; 
}

- (id) outlineView: (NSOutlineView*) outlineView objectValueForTableColumn: (NSTableColumn*) tableColumn byItem: (id) item {
	// if we requested information for the group...  
	if ([item isKindOfClass: [VTHotkeyGroup class]]) {
		// provide data for the group 
		if ([[tableColumn identifier] isEqualToString: @"action"])
			return [item name]; 
		
		return nil; 
	}
	// if we requested information for the notification
	else if ([item isKindOfClass: [VTHotkeyNotification class]]) {
		// provide data for the window 
		if ([[tableColumn identifier] isEqualToString: @"action"]) {
			return [item notification]; 
		}
		else if ([[tableColumn identifier] isEqualToString: @"hotkey"]) {
			if ([item hotkey])
				return [item hotkey]; 
			else 
				return [[[VTHotkey alloc] init] autorelease]; 
			
		} 
		else if ([[tableColumn identifier] isEqualToString: @"enabled"]) {
			return [NSNumber numberWithBool: [item isEnabled]]; 
		}
	}
	
	return nil; 
}

- (void) outlineView: (NSOutlineView*) outlineView setObjectValue: (id) object forTableColumn: (NSTableColumn*) tableColumn byItem: (id) item {
	if ([[tableColumn identifier] isEqualToString: @"enabled"] == NO)
		return; 
	
	if ([item isKindOfClass: [VTHotkeyNotification class]] == NO) 
		return; 
	
	if ([object isKindOfClass: [NSNumber class]] == NO) 
		return; 
	
	[(VTHotkeyNotification*)item setEnabled: [object boolValue]]; 
}

- (void) outlineView: (NSOutlineView*) outlineView willDisplayCell: (id) cell forTableColumn: (NSTableColumn*) tableColumn item: (id) item {
	if ([[tableColumn identifier] isEqualToString: @"enabled"]) {
		if ([item isKindOfClass: [VTHotkeyGroup class]]) {
			// hide our checkbox cell 
			[cell setTransparent: YES]; 
			[cell setEnabled: NO]; 
		}
		else {
			// check if we got a hotkey assigned and only show the check box 
			// if we have... 
			if ([(VTHotkeyNotification*)item hotkey]) {
				[cell setTransparent: NO]; 
				[cell setEnabled: YES]; 
			}
			else {
				[cell setTransparent: YES]; 
				[cell setEnabled: NO]; 
			}
		}
	}
}

#pragma mark -
#pragma mark NSPreferencePane 

- (void) mainViewDidLoad {
	VTHotkeyCell* hotkeyCell = [[[VTHotkeyCell alloc] init] autorelease]; 
	[hotkeyCell setAlignment: NSLeftTextAlignment]; 
	
	[[mHotkeyOutline tableColumnWithIdentifier: @"hotkey"] setDataCell: hotkeyCell]; 
	
	mFieldEditor = [[VTHotkeyTextView alloc] initWithFrame: NSMakeRect(0, 0, 10, 10)]; 
	[mFieldEditor setFieldEditor: YES]; 
	[mFieldEditor setTextContainerInset: NSMakeSize(0, -2)]; 

	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onEditEnded) name: NSTextDidEndEditingNotification object: mFieldEditor];
	
	// fetch navigation group, as we want to watch its notifications to recreate 
	// the outlined data as necessary 
	mNavigationGroup = [[[VTHotKeyController sharedInstance] groupWithName: VTHotkeyGroupNavigationName] retain]; 
	[mNavigationGroup addObserver: self 
					   forKeyPath: @"notifications"
						  options: NSKeyValueObservingOptionNew
						  context: NULL]; 
}

#pragma mark -
- (void) onEditEnded {
	VTHotkey*				hotkey				= [mFieldEditor hotkey];
	VTHotkeyNotification*	hotkeyNotification	= [mHotkeyOutline itemAtRow: [mHotkeyOutline selectedRow]]; 
	
	if ([hotkey keyCode] < 0)
		[hotkeyNotification setHotkey: nil]; 
	else	
		[hotkeyNotification setHotkey: hotkey]; 
	
	// and we sync hotkeys (should not take too long) 
	[[VTHotKeyController sharedInstance] synchronize]; 
}

#pragma mark -
#pragma mark NSWindow delegate 

- (id) windowWillReturnFieldEditor: (NSWindow*) sender toObject: (id) anObject {
	if ([anObject isKindOfClass: [NSOutlineView class]]) 
		return mFieldEditor;
	
	return nil;
}

#pragma mark -
#pragma mark KVO Sink 

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString: @"notifications"]) {
		// TODO: Optimize to only reload changed data 
		[mHotkeyOutline reloadData];
	}
}

@end
