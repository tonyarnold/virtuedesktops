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

#import "VTDesktopTemplatePreferences.h"
#import "VTPreferenceKeys.h" 

#import "VTDecorationPrimitiveText.h"
#import "VTDecorationPrimitiveTextInspector.h"
#import "VTDecorationPrimitiveTint.h" 
#import "VTDecorationPrimitiveTintInspector.h"
#import "VTDecorationPrimitiveWatermark.h"
#import "VTDecorationPrimitiveWatermarkInspector.h"

#import "VTPlugin.h" 
#import "VTPluginCollection.h" 
#import "VTNotifications.h"
#import "VTDesktopController.h" 

#import <Peony/Peony.h> 
#import <Zen/Zen.h> 

#define kVtMovedRowsDropType @"VIRTUE_DESKTOP_COLLECTION_MOVE"

#pragma mark -
@interface VTDesktopTemplatePreferences (Decorations) 
- (VTInspector*) inspectorForPrimitive: (VTDecorationPrimitive*) primitive; 
- (VTDecorationPrimitive*) selectedPrimitive; 
- (void) onAddPrimitive: (id) sender; 
- (void) createDecorationAddMenu; 
- (void) createInspectors; 
@end 

#pragma mark -
@implementation VTDesktopTemplatePreferences

- (void) dealloc {
	// attributes 
	ZEN_RELEASE(mPrimitiveInspectors); 
	
	// super 
	[super dealloc]; 
}

#pragma mark -
#pragma mark NSPreferencePane delegate 

- (void) mainViewDidLoad {
	// inspectors
	mPrimitiveInspectors = [[NSMutableDictionary alloc] init]; 
	[self createInspectors]; 	
	
	// decoration controller 
	[mDecorationsController bind: @"contentArray" toObject: [[VTDesktopController sharedInstance] decorationPrototype] withKeyPath: @"decorationPrimitives" options: nil]; 
	
	// Decorations table view 
	[mDecorationsTableView registerForDraggedTypes: [NSArray arrayWithObjects: kVtMovedRowsDropType, nil]];	
	[self createDecorationAddMenu]; 
		
	// create inspector 
	mInspectorController = [[VTDecorationPrimitiveViewController alloc] init]; 
}

- (void) willUnselect {
	// encode preferences 
	NSMutableDictionary* decorationDict = [NSMutableDictionary dictionary]; 
	[[[VTDesktopController sharedInstance] decorationPrototype] encodeToDictionary: decorationDict]; 
	
	// write them 
	[[NSUserDefaults standardUserDefaults] setObject: decorationDict forKey: VTPreferencesDecorationTemplateName]; 
	// and sync 
	[[NSUserDefaults standardUserDefaults] synchronize]; 
}

#pragma mark -
#pragma mark Actions 
- (IBAction) deletePrimitive: (id) sender {
	// fetch the currently selected primitive and remove it from our container 
	VTDecorationPrimitive* selectedPrimitive = [self selectedPrimitive]; 
	[[[VTDesktopController sharedInstance] decorationPrototype] delDecorationPrimitive: selectedPrimitive]; 
}

- (IBAction) inspectPrimitive: (id) sender {
	VTDecorationPrimitive* selectedPrimitive = [self selectedPrimitive]; 
	
	// if there is no primitive, return 
	if (selectedPrimitive == nil)
		return; 
	
	// find the inspector for our primitive 
	VTInspector* inspector = [self inspectorForPrimitive: selectedPrimitive]; 
	// setup inspector 
	[inspector setInspectedObject: selectedPrimitive]; 
	
	[mInspectorController window]; 
	[mInspectorController startSheetForPrimitive: selectedPrimitive
									   inspector: inspector
										  window: [[self mainView] window] 
										delegate: self 
								  didEndSelector: @selector(inspectorPanelDidEnd:returnCode:contextInfo:)]; 
}

- (IBAction) applyPrototype: (id) sender {
	[[VTDesktopController sharedInstance] applyDecorationPrototype: NO]; 
}

- (IBAction) replacePrototype: (id) sender {
	[[VTDesktopController sharedInstance] applyDecorationPrototype: YES]; 	
}


#pragma mark -
#pragma mark Modal delegate 
- (void) inspectorPanelDidEnd: (NSWindow*) sheet returnCode: (int) returnCode contextInfo: (void*) contextInfo {
	// set button state of inspector button to off 
	[mInspectPrimitiveButton setState: NSOffState]; 
}

#pragma mark -
#pragma mark NSTableView delegate 
- (BOOL) tableView: (NSTableView*) tv writeRows: (NSArray*) rows toPasteboard: (NSPasteboard*) pboard {
	// Decorations table view
	if ([tv isEqual: mDecorationsTableView]) {
		NSArray* typesArray = [NSArray arrayWithObjects: kVtMovedRowsDropType, nil];
		[pboard declareTypes: typesArray owner: self];
		
		// add rows array for local move
		[pboard setPropertyList: rows forType: kVtMovedRowsDropType];
		
		return YES; 
	}
	
	return NO; 
}

- (NSDragOperation) tableView: (NSTableView*) tv validateDrop: (id <NSDraggingInfo>) info proposedRow: (int) row proposedDropOperation: (NSTableViewDropOperation) op {
	// Decorations table view
	if ([tv isEqual: mDecorationsTableView]) {
		NSDragOperation dragOp = NSDragOperationCopy;
		
		// if drag source is self, it's a move
		if ([info draggingSource] == mDecorationsTableView) {
			dragOp = NSDragOperationMove;
		}
		
		// we want to put the object at, not over, the current row (contrast NSTableViewDropOn) 
		[tv setDropRow: row dropOperation: NSTableViewDropAbove];
		
		return dragOp;
	}
	
	return NSDragOperationNone; 
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op {
	// Decorations table view
	if ([tv isEqual: mDecorationsTableView]) {   
		if (row < 0)
			row = 0;
		
		// if drag source is self, it's a move
		if ([info draggingSource] == mDecorationsTableView) {
			NSArray*	rows		= [[info draggingPasteboard] propertyListForType: kVtMovedRowsDropType];
			int			fromIndex   = [[rows objectAtIndex: 0] intValue]; 
			
			// if the index would not change, we do not do anything 
			if (fromIndex == row)
				return NO; 
			
			[mDecorationsController setSelectionIndex: -1]; 
			[[[VTDesktopController sharedInstance] decorationPrototype] moveObjectAtIndex: fromIndex toIndex: row]; 
			[mDecorationsController setSelectionIndex: row]; 
			
			return YES;
		}
		
		return NO;
	}
	
	return NO; 
}

@end

#pragma mark -
@implementation VTDesktopTemplatePreferences (Decorations) 
- (VTInspector*) inspectorForPrimitive: (VTDecorationPrimitive*) primitive {
	return [mPrimitiveInspectors objectForKey: NSStringFromClass([primitive class])]; 
}

- (VTDecorationPrimitive*) selectedPrimitive {
	int selectionIndex = [mDecorationsController selectionIndex]; 
	
	// no selection, no primitive  
	if (selectionIndex == NSNotFound)
		return nil; 
	
	return [[[[VTDesktopController sharedInstance] decorationPrototype] decorationPrimitives] objectAtIndex: selectionIndex]; 	
}

- (void) onAddPrimitive: (id) sender {
	// fetch information needed to perform operation
	Class		primitiveClass = NSClassFromString([sender representedObject]);
	NSString*	primitiveName  = [sender title]; 
	
	// create a new instance of the fetched class and ... 
	VTDecorationPrimitive* primitive = [[primitiveClass alloc] init];
	[primitive setName: primitiveName]; 

	// insert it into the decoration collection 
	[[[VTDesktopController sharedInstance] decorationPrototype] addDecorationPrimitive: primitive]; 
}

- (void) createDecorationAddMenu {
	NSMenuItem* item; 	
	
	// we expect the menu to be empty... and start creating our 
	// items beginning with built-in items at the top... 
	
	// Text-Primitive 
	item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedStringFromTable(NSStringFromClass([VTDecorationPrimitiveText class]), @"DefaultPrimitiveNames", @"Text Primitive") action: @selector(onAddPrimitive:) keyEquivalent: @""] autorelease]; 
	[item setRepresentedObject: NSStringFromClass([VTDecorationPrimitiveText class])]; 
	[item setTarget: self]; 
	[mAddPrimitiveMenu addItem: item]; 
	// Tint-Primitive 
	item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedStringFromTable(NSStringFromClass([VTDecorationPrimitiveTint class]), @"DefaultPrimitiveNames", @"Tint Primitive") action: @selector(onAddPrimitive:) keyEquivalent: @""] autorelease]; 
	[item setRepresentedObject: NSStringFromClass([VTDecorationPrimitiveTint class])]; 
	[item setTarget: self]; 
	[mAddPrimitiveMenu addItem: item]; 
	// Watermark-Primitive 
	item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedStringFromTable(NSStringFromClass([VTDecorationPrimitiveWatermark class]), @"DefaultPrimitiveNames", @"Watermark Primitive") action: @selector(onAddPrimitive:) keyEquivalent: @""] autorelease]; 
	[item setRepresentedObject: NSStringFromClass([VTDecorationPrimitiveWatermark class])]; 
	[item setTarget: self]; 
	[mAddPrimitiveMenu addItem: item]; 
	// Separator 
	[mAddPrimitiveMenu addItem: [NSMenuItem separatorItem]]; 
	
	// Plugins 
	NSArray*				pluginDecorations	= [[VTPluginCollection sharedInstance] pluginsOfType: @protocol(VTPluginDecoration)]; 
	NSEnumerator*			pluginIter			= [pluginDecorations objectEnumerator]; 
	VTPluginInstance*		plugin				= nil; 
	
	while (plugin = [pluginIter nextObject]) {
		id<VTPluginDecoration> pluginInstance = [plugin instance]; 
		
		item = [[[NSMenuItem alloc] initWithTitle: [plugin pluginName] action: @selector(onAddPrimitive:) keyEquivalent: @""] autorelease]; 
		[item setRepresentedObject: NSStringFromClass([pluginInstance decorationPrimitiveClass])]; 
		[item setTarget: self]; 
		[mAddPrimitiveMenu addItem: item]; 
	}
}	

- (void) createInspectors {
	// create built-in inspectors
	VTInspector* inspector = nil; 
	
	// VTDecorationPrimitiveTextInspector 
	inspector = [[[VTDecorationPrimitiveTextInspector alloc] init] autorelease]; 
	[mPrimitiveInspectors setObject: inspector forKey: NSStringFromClass([VTDecorationPrimitiveText class])]; 
	// VTDecorationPrimitiveTintInspector 
	inspector = [[[VTDecorationPrimitiveTintInspector alloc] init] autorelease]; 
	[mPrimitiveInspectors setObject: inspector forKey: NSStringFromClass([VTDecorationPrimitiveTint class])]; 
	// VTDecorationPrimitiveWatermarkInspector
	inspector = [[[VTDecorationPrimitiveWatermarkInspector alloc] init] autorelease]; 
	[mPrimitiveInspectors setObject: inspector forKey: NSStringFromClass([VTDecorationPrimitiveWatermark class])]; 
	
	// Plugins 
	NSArray*				pluginDecorations	= [[VTPluginCollection sharedInstance] pluginsOfType: @protocol(VTPluginDecoration)]; 
	NSEnumerator*			pluginIter			= [pluginDecorations objectEnumerator]; 
	id<VTPluginDecoration>	plugin		= nil; 
	
	while (plugin = [[pluginIter nextObject] instance]) {
		inspector = [plugin decorationPrimitiveInspector]; 
		
		if (inspector == nil)
			continue; 
		
		[mPrimitiveInspectors setObject: inspector forKey: NSStringFromClass([plugin decorationPrimitiveClass])]; 
	}	
}

@end 