/*
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
 */

#import "VTHotkeyPreferencesController.h"
#import "VTTriggerToTypeImage.h"
#import "VTDesktopController.h"
#import "VTTriggerController.h"
#import "VTTriggerGroup.h"
#import "VTTriggerNotification.h"
#import "VTTrigger.h"
#import "VTHotkeyTrigger.h"
#import "VTMouseTrigger.h"
#import <Zen/Zen.h>


@interface VTHotkeyPreferencesController (Inspector)
- (void) updateInspectorView; 
- (void) setEdgeFromMarker; 
- (void) setPositionGridMarker;
@end

#pragma mark -
@implementation VTHotkeyPreferencesController

+ (void) initialize {
	// type transformer 
	VTTriggerToTypeImage* transformer = [[[VTTriggerToTypeImage alloc] init] autorelease]; 
	[NSValueTransformer setValueTransformer: transformer forName: @"VTTriggerType"]; 
}

#pragma mark -
#pragma mark Lifetime 
- (void) dealloc {
	[super dealloc]; 
}

#pragma mark -
#pragma mark NSOutlineView DataSource 

- (id) outlineView: (NSOutlineView*) outlineView child: (int) index ofItem: (id) item {
	if (item == nil) {
		// fetch top level items by index 
		return [[[VTTriggerController sharedInstance] items] objectAtIndex: index]; 
	}
	
	if ([item isKindOfClass: [VTTriggerGroup class]]) {
		// return notification from the hotkey group represented by the item 
		return [[item items] objectAtIndex: index]; 
	}
	
	return nil; 
}

- (BOOL) outlineView: (NSOutlineView*) outlineView isItemExpandable: (id) item {
	if ([item isKindOfClass: [VTTriggerNotification class]])
		return NO; 
	
	return YES; 
}

- (int) outlineView: (NSOutlineView*) outlineView numberOfChildrenOfItem: (id) item {
	if ([item isKindOfClass: [VTTriggerNotification class]])
		return 0; 
	
	if (item == nil)
		return [[[VTTriggerController sharedInstance] items] count]; 
	
	// return notification from the hotkey group represented by the item 
	return [[item items] count]; 
}

- (id) outlineView: (NSOutlineView*) outlineView objectValueForTableColumn: (NSTableColumn*) tableColumn byItem: (id) item {
	// if we requested information for the group...  
	if ([item isKindOfClass: [VTTriggerGroup class]]) {
		// provide data for the group 
		if ([[tableColumn identifier] isEqualToString: @"name"])
			return [item name]; 
		
		return nil; 
	}
	// if we requested information for the notification
	else if ([item isKindOfClass: [VTTriggerNotification class]]) {
		// provide data for the window 
		if ([[tableColumn identifier] isEqualToString: @"name"]) {
			return [(VTTriggerNotification*)item notification]; 
		}
	}
	
	return nil; 
}

- (void) outlineViewSelectionDidChange: (NSNotification*) notification {
	id selectedItem = [mAvailableTriggersView itemAtRow: [mAvailableTriggersView selectedRow]]; 
	[mSelectAndCloseButton setEnabled: [selectedItem isKindOfClass: [VTTriggerNotification class]]];
}

#pragma mark -
#pragma mark NSTableView 
- (void) tableViewSelectionDidChange: (NSNotification*) aNotification {
	[self updateInspectorView]; 
}

- (BOOL) tableView: (NSTableView*) aTableView shouldEditTableColumn: (NSTableColumn*) aTableColumn row: (int) rowIndex {
	// check for the type of trigger and only permit editing the triggers column if we got a 
	// hotkey trigger in hands, if it is a mouse trigger, we will open the inspector drawer
	// instead 
	if ([[aTableColumn identifier] isEqualToString: @"trigger"] == NO)
		return NO; 
	
	VTTrigger* trigger = [mAssignedTriggerController valueForKeyPath: @"selection.trigger"]; 
	if ([trigger isKindOfClass: [VTHotkeyTrigger class]]) {
		return YES; 
	}
	
	[mInspectorDrawer open]; 
	return NO; 
}

#pragma mark -
#pragma mark NSPreferencePane 

- (void) mainViewDidLoad {
	VTHotkeyCell* hotkeyCell = [[[VTHotkeyCell alloc] init] autorelease]; 
	[hotkeyCell setAlignment: NSLeftTextAlignment]; 
	
	// create field editor 
	mFieldEditor = [[VTHotkeyTextView alloc] initWithFrame: NSMakeRect(0, 0, 10, 10)]; 
	[mFieldEditor setFieldEditor: YES]; 
	[mFieldEditor setTextContainerInset: NSMakeSize(0, 0)]; 

	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onEditEnded) name: NSTextDidEndEditingNotification object: mFieldEditor];
	
	// prepare controllers 
	[mAssignedTriggerController setContent: [[[VTTriggerController sharedInstance] root] allNotifications]]; 
	
	NSBundle*	bundle      = [NSBundle bundleForClass: [self class]]; 
	NSImage*	mouseImage	= [[[NSImage alloc] initByReferencingFile: [bundle pathForResource: @"imageMouseTrigger" ofType: @"png"]] autorelease]; 
	NSImage*	keyImage    = [[[NSImage alloc] initByReferencingFile: [bundle pathForResource: @"imageKeyboardTrigger" ofType: @"png"]] autorelease]; 
	
	// prepare menu 
	[mKeyTriggerItem setImage: keyImage];
	[mKeyTriggerItem setTag: 0];
	
	[mMouseTriggerItem setImage: mouseImage];
	[mMouseTriggerItem setTag: 1];
	
	// prepare popupbutton cell 
	[mTriggerPopupCell setImagePosition: NSImageOnly]; 
	[mTriggerPopupCell setArrowPosition: NSPopUpNoArrow]; 
	
	// prepare position grid 
	[mPositionGrid setMarkers: [NSArray arrayWithObjects: 
	[NSNumber numberWithInt: VTPositionMarkerLeft], 
	[NSNumber numberWithInt: VTPositionMarkerRight], 
	[NSNumber numberWithInt: VTPositionMarkerTop], 
	[NSNumber numberWithInt: VTPositionMarkerBottom],
	[NSNumber numberWithInt: VTPositionMarkerTopLeft],
	[NSNumber numberWithInt: VTPositionMarkerTopRight],
	[NSNumber numberWithInt: VTPositionMarkerBottomLeft],
	[NSNumber numberWithInt: VTPositionMarkerBottomRight],
	nil]]; 
	[mPositionGrid setTarget: self]; 
	[mPositionGrid setAction: @selector(onPositionSelected:)]; 
	
	// prepare outline view 
	[mAvailableTriggersView setTarget: self]; 
	[mAvailableTriggersView setDoubleAction: @selector(onTriggerActionDouble:)]; 
	
	// ivars 
	mSelectedNotification = nil; 
	
	// and start observing desktop collection changes 
	[[VTDesktopController sharedInstance] 
		addObserver: self 
		forKeyPath: @"desktops" 
		options: NSKeyValueObservingOptionNew 
		context: NULL]; 	
}

#pragma mark -
- (void) onEditEnded {
	VTHotkeyTrigger*		trigger				= [mFieldEditor hotkey];
	VTHotkeyTrigger*		existingTrigger		= nil;
	
	if ([trigger keyCode] < 0)
		return; 
	
	int selectionIndex = [mAssignedTriggerController selectionIndex];
	if (selectionIndex == NSNotFound) 
		return; 
	
	existingTrigger = [[[mAssignedTriggerController arrangedObjects] objectAtIndex: selectionIndex] objectForKey: @"trigger"]; 
	if (existingTrigger == nil)
		return; 
	
	// unregister trigger 
	[existingTrigger unregisterTrigger]; 
	// copy over settings 
	[existingTrigger setKeyCode: [trigger keyCode]]; 
	[existingTrigger setKeyModifiers: [trigger keyModifiers]]; 
	// and register trigger 
	[existingTrigger registerTrigger]; 
	
	// and we sync hotkeys (should not take too long) 
	[[VTTriggerController sharedInstance] synchronize]; 
}

#pragma mark -
- (void) didSelect {
	// prepare window delegate 
	mOriginalDelegate = [[[self mainView] window] delegate]; 
	[[[self mainView] window] setDelegate: self]; 
	// prepare drawer 
	[mInspectorDrawer setParentWindow: [[self mainView] window]]; 
	// and set offsets 
	[mInspectorDrawer setLeadingOffset: 54]; 
	[mInspectorDrawer setTrailingOffset: 0]; 
}

- (void) willUnselect {
	[[[self mainView] window] setDelegate: mOriginalDelegate]; 
	// hide 
	[mInspectorDrawer close]; 
}

#pragma mark -
#pragma mark NSWindow delegate
- (id) windowWillReturnFieldEditor: (NSWindow*) sender toObject: (id) anObject {
	if ([anObject isEqual: mTriggerTableView]) {
		return mFieldEditor; 
	}
	
	return nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	// check for path that changed 
	if ([keyPath isEqual: @"desktops"]) {
		VTTriggerGroup* navigationGroup = [[VTTriggerController sharedInstance] groupWithName: VTTriggerGroupNavigationName]; 
		// we will collapse all open nodes so they are read out again
		[mAvailableTriggersView collapseItem: navigationGroup collapseChildren: YES];
	}
}

#pragma mark -
#pragma mark Actions 
- (IBAction) showAvailableTriggers: (id) sender {
	[[NSApplication sharedApplication] beginSheet: mAvailableTriggersPanel 
	modalForWindow: [[self mainView] window] 
	modalDelegate: self 
	didEndSelector: @selector(availableTriggersPanelEnded:returnCode:contextInfo:) 
	contextInfo: NULL];
}

#pragma mark -
- (IBAction) selectAndEndSheet: (id) sender {
	// fetch the selection
	mSelectedNotification = [[mAvailableTriggersView itemAtRow: [mAvailableTriggersView selectedRow]] retain]; 
	
	[mAvailableTriggersPanel close]; 
	[[NSApplication sharedApplication] endSheet: mAvailableTriggersPanel returnCode: NSOKButton]; 
}

- (IBAction) cancelAndEndSheet: (id) sender {
	[mAvailableTriggersPanel close]; 
	[[NSApplication sharedApplication] endSheet: mAvailableTriggersPanel returnCode: NSCancelButton]; 	
}

#pragma mark -
- (IBAction) removeTrigger: (id) sender {
	// fetch selection 
	VTTriggerNotification*	notification	= [mAssignedTriggerController valueForKeyPath: @"selection.notification"];
	VTTrigger*				trigger			= [mAssignedTriggerController valueForKeyPath: @"selection.trigger"]; 
	
	// remove the trigger 
	int index = [[notification triggers] indexOfObject: trigger]; 
	[notification removeObjectFromTriggersAtIndex: index]; 
	
	// and rearrange 
	[mAssignedTriggerController rearrangeObjects]; 
	[mInspectorDrawer close]; 
}

#pragma mark -
- (IBAction) toggleModifier: (id) sender {
	// fetch notification and trigger 
	VTTrigger*	trigger	= [mAssignedTriggerController valueForKeyPath: @"selection.trigger"]; 
	
	int state			= [sender state]; 
	int modifiers		= [(VTMouseTrigger*)trigger modifiers]; 
	int modifier		= 0; 
	
	// handle different buttons 
	if ([sender isEqual: mShiftButton])
		modifier = NSShiftKeyMask; 
	else if ([sender isEqual: mControlButton]) 
		modifier = NSControlKeyMask; 
	else if ([sender isEqual: mAlternateButton]) 
		modifier = NSAlternateKeyMask; 
	else if ([sender isEqual: mCommandButton])
		modifier = NSCommandKeyMask; 
	
	if (state == NSOnState) 
		modifiers |= modifier; 
	else
		modifiers ^= modifier; 
	
	[(VTMouseTrigger*)trigger setModifiers: modifiers];
	
	[self updateInspectorView]; 
	[mAssignedTriggerController rearrangeObjects]; 
}

- (IBAction) toggleClickCount: (id) sender {
	[mAssignedTriggerController rearrangeObjects]; 
}

#pragma mark -
- (IBAction) toggleTriggerType: (id) sender {
	// selection index...
	int	notificationSel = [mAssignedTriggerController selectionIndex]; 
	
	if (notificationSel == NSNotFound)
		return; 
	
	// fetch notification and trigger 
	VTTriggerNotification*	notification	= [mAssignedTriggerController valueForKeyPath: @"selection.notification"];
	VTTrigger*				trigger			= [mAssignedTriggerController valueForKeyPath: @"selection.trigger"]; 
	VTTrigger*				newTrigger		= nil; 
	
	int index = [[notification triggers] indexOfObject: trigger];
	if (index == NSNotFound)
		return; 
	
	// check which type to give 
	if ([sender tag] == 0) {
		if ([trigger isKindOfClass: [VTHotkeyTrigger class]])
			return;
		
		// create new hotkey trigger 
		newTrigger = [[[VTHotkeyTrigger alloc] init] autorelease]; 
		[notification insertObjectInTriggers: newTrigger atIndex: index]; 
		
		// remove the old trigger 
		[notification removeObjectFromTriggersAtIndex: index+1]; 
	}
	else if ([sender tag] == 1) {
		if ([trigger isKindOfClass: [VTMouseTrigger class]])
			return; 
		
		// create new mouse trigger 
		newTrigger = [[[VTMouseTrigger alloc] init] autorelease]; 
		[notification insertObjectInTriggers: newTrigger atIndex: index]; 
		
		[trigger retain]; 
		// remove the old trigger 
		[notification removeObjectFromTriggersAtIndex: index+1]; 
	}
	
	// and rearrange 
	[mAssignedTriggerController rearrangeObjects];
	[mAssignedTriggerController setSelectionIndex: notificationSel]; 
	
	[self updateInspectorView]; 
	
	if ([newTrigger isKindOfClass: [VTMouseTrigger class]]) {	
		// if we have a mouse trigger in place, show the inspector drawer 
		[mInspectorDrawer open]; 
		[trigger release]; 
	}
}

#pragma mark -
- (void) onTriggerActionDouble: (id) sender {
	id selectedItem = [mAvailableTriggersView itemAtRow: [mAvailableTriggersView selectedRow]]; 
	
	if ([selectedItem isKindOfClass: [VTTriggerNotification class]]) {
		[self selectAndEndSheet: sender]; 
	}
}

#pragma mark -
#pragma mark Modal Delegate 
- (void) availableTriggersPanelEnded: (NSWindow*) panel returnCode: (int) returnCode contextInfo: (void*) contextInfo {
	if (returnCode == NSOKButton) {
		// create a new empty hotkey trigger per default 
		VTHotkeyTrigger* trigger = [[[VTHotkeyTrigger alloc] init] autorelease]; 
		// inject into selected notification 
		[mSelectedNotification insertObjectInTriggers: trigger atIndex: 0]; 
		
		// rearrange objects 
		[mAssignedTriggerController rearrangeObjects]; 
	}
	
	ZEN_RELEASE(mSelectedNotification);
}

#pragma mark -
#pragma mark Position Grid delegate 
- (void) onPositionSelected: (id) sender {
	[self setEdgeFromMarker]; 
	[mAssignedTriggerController rearrangeObjects]; 
}
@end

#pragma mark -
@implementation VTHotkeyPreferencesController (Inspector)
- (void) updateInspectorView {
	// if there are no more triggers to inspect, hide the view 
	if ([[mAssignedTriggerController arrangedObjects] count] == 0) {
		[mInspectorDrawer close]; 
		return; 
	}
	
	// set content view of drawer 
	VTTrigger* trigger = [mAssignedTriggerController valueForKeyPath: @"selection.trigger"];
	
	if (trigger == nil)
		return; 
	
	if ([trigger isKindOfClass: [VTHotkeyTrigger class]]) {
		[mInspectorDrawer setContentView: mHotkeyInspectorView]; 
	}
	else if ([trigger isKindOfClass: [VTMouseTrigger class]]) {
		[mInspectorDrawer setContentView: mMouseInspectorView];
		[self setPositionGridMarker]; 
		
		int modifiers = [(VTMouseTrigger*)trigger modifiers];
		
		// set up buttons 
		[mCommandButton setState: (modifiers & NSCommandKeyMask) ? NSOnState : NSOffState]; 
		[mAlternateButton setState: (modifiers & NSAlternateKeyMask) ? NSOnState : NSOffState]; 
		[mShiftButton setState: (modifiers & NSShiftKeyMask) ? NSOnState : NSOffState]; 
		[mControlButton setState: (modifiers & NSControlKeyMask) ? NSOnState : NSOffState]; 
		
	}	
}

- (void) setPositionGridMarker {
	VTTrigger* trigger = [mAssignedTriggerController valueForKeyPath: @"selection.trigger"]; 
	if ([trigger isKindOfClass: [VTMouseTrigger class]] == NO) 
		return; 
	
	VTMouseTrigger* mouseTrigger = (VTMouseTrigger*)trigger; 
	// translate edge to position marker 
	VTPositionGridMarker marker = VTPositionMarkerNone; 
	
	switch ([mouseTrigger edge]) {
	case ZNEdgeTop: 
		marker = VTPositionMarkerTop; 
		break; 
	case ZNEdgeBottom: 
		marker = VTPositionMarkerBottom; 
		break; 
	case ZNEdgeLeft: 
		marker = VTPositionMarkerLeft; 
		break; 
	case ZNEdgeRight: 
		marker = VTPositionMarkerRight; 
		break; 
	case ZNEdgeTopLeft: 
		marker = VTPositionMarkerTopLeft; 
		break; 
	case ZNEdgeTopRight: 
		marker = VTPositionMarkerTopRight; 
		break; 
	case ZNEdgeBottomLeft: 
		marker = VTPositionMarkerBottomLeft; 
		break; 
	case ZNEdgeBottomRight: 
		marker = VTPositionMarkerBottomRight; 
		break; 
	default:
		break;
	}
	
	[mPositionGrid setSelectedMarker: marker]; 
}

- (void) setEdgeFromMarker {
	VTTrigger* trigger = [mAssignedTriggerController valueForKeyPath: @"selection.trigger"]; 
	if ([trigger isKindOfClass: [VTMouseTrigger class]] == NO) 
		return; 
	
	VTMouseTrigger*	mouseTrigger = (VTMouseTrigger*)trigger; 
	VTPositionGridMarker marker	= [mPositionGrid selectedMarker];  
	
	switch (marker) {
	case VTPositionMarkerTop: 
		[mouseTrigger setEdge: ZNEdgeTop]; 
		break; 
	case VTPositionMarkerBottom: 
		[mouseTrigger setEdge: ZNEdgeBottom]; 
		break; 
	case VTPositionMarkerLeft: 
		[mouseTrigger setEdge: ZNEdgeLeft]; 
		break; 
	case VTPositionMarkerRight: 
		[mouseTrigger setEdge: ZNEdgeRight]; 
		break; 
	case VTPositionMarkerTopLeft: 
		[mouseTrigger setEdge: ZNEdgeTopLeft]; 
		break; 
	case VTPositionMarkerTopRight: 
		[mouseTrigger setEdge: ZNEdgeTopRight]; 
		break; 
	case VTPositionMarkerBottomLeft: 
		[mouseTrigger setEdge: ZNEdgeBottomLeft]; 
		break; 
	case VTPositionMarkerBottomRight: 
		[mouseTrigger setEdge: ZNEdgeBottomRight]; 
		break;
	default:
		break;
	}; 
}

@end 
