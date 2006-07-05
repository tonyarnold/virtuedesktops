/******************************************************************************
* 
* Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2006, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import <Virtue/VTDesktopBackgroundHelper.h>
#import "VTDesktopViewController.h"
#import "VTColorLabelButtonCell.h" 
#import "VTApplicationRunningCountTransformer.h" 
#import <Virtue/VTDecorationPrimitiveText.h>
#import "VTDecorationPrimitiveTextInspector.h" 
#import <Virtue/VTDecorationPrimitiveTint.h> 
#import "VTDecorationPrimitiveTintInspector.h" 
#import <Virtue/VTDecorationPrimitiveWatermark.h>
#import "VTDecorationPrimitiveWatermarkInspector.h"

#import <Virtue/VTPlugin.h> 
#import <Virtue/VTPluginCollection.h> 
#import <Virtue/VTNotifications.h>
#import <Virtue/VTDesktopController.h> 
#import <Virtue/VTLayoutController.h> 

#import <Peony/Peony.h> 
#import <Zen/Zen.h> 

#define kVtMovedRowsDropType @"VIRTUE_DESKTOP_COLLECTION_MOVE"

@interface VTDesktopViewController (Selection) 
- (VTDesktop*) selectedDesktop; 
- (void) setSelectedDesktop: (VTDesktop*) desktop; 
- (void) showDesktop: (VTDesktop*) desktop; 
@end 

#pragma mark -
@interface VTDesktopViewController (Decorations)
- (VTInspector*) inspectorForPrimitive: (VTDecorationPrimitive*) primitive; 
- (VTDecorationPrimitive*) selectedPrimitive; 
- (void) createDecorationAddMenu; 
- (void) createInspectors; 
@end 

#pragma mark -
@implementation VTDesktopViewController

+ (void) initialize {
	NSValueTransformer* transformer = nil; 
	
	transformer = [[[VTApplicationRunningCountTransformer alloc] init] autorelease]; 
	[NSValueTransformer setValueTransformer: transformer forName: @"VTApplicationRunningCount"]; 
}

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super initWithWindowNibName: @"VTDesktopInspector"]) {		
		mPrimitiveInspectors = [[NSMutableDictionary alloc] init]; 
		mActiveDesktopLayout = (VTMatrixDesktopLayout*)[[VTLayoutController sharedInstance] activeLayout];
		[self createInspectors]; 
		return self;
	}
	
	return nil;
}

- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver: self]; 	
	
	ZEN_RELEASE(mDesktop); 
	ZEN_RELEASE(mInspectorController); 
	ZEN_RELEASE(mPrimitiveInspectors); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Actions 
- (IBAction) addDesktop: (id) sender {
	// create a new desktop 
	VTDesktop*	newDesktop = [[VTDesktopController sharedInstance] desktopWithFreeId]; 
	
	// set up the desktop 
	[newDesktop setName: [NSString stringWithFormat: @"Desktop %i", [newDesktop identifier]]]; 
	
	// and add it to our collection 
	[[VTDesktopController sharedInstance] insertObject: newDesktop inDesktopsAtIndex: [[[VTDesktopController sharedInstance] desktops] count]];
}

- (IBAction) deleteDesktop: (id) sender {
	VTDesktop* desktop	= [self selectedDesktop]; 
	int desktopIndex		= [[[VTDesktopController sharedInstance] desktops] indexOfObject: desktop]; 
	
	// remove the selected desktop 
	[[VTDesktopController sharedInstance] removeObjectFromDesktopsAtIndex: desktopIndex]; 
	[mDesktopsController rearrangeObjects]; 
}

- (IBAction) deletePrimitive: (id) sender {
	// fetch the currently selected primitive and remove it from our container 
	VTDecorationPrimitive* selectedPrimitive = [self selectedPrimitive]; 
	int primitiveIndex = [[[mDesktop decoration] decorationPrimitives] indexOfObject: selectedPrimitive]; 
	
	[[mDesktop decoration] delDecorationPrimitive: selectedPrimitive]; 
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
																				window: [self window] 
																			delegate: self 
																didEndSelector: @selector(inspectorPanelDidEnd:returnCode:contextInfo:)]; 
}

- (IBAction) showWindow: (id) sender {
	[self showWindowForDesktop: [[VTDesktopController sharedInstance] activeDesktop]]; 
}

- (void) showWindowForDesktop: (VTDesktop*) desktop {
	[self setSelectedDesktop: desktop]; 
	[super showWindow: self]; 
}

#pragma mark -
#pragma mark Attributes 

- (VTDesktop*) desktop {
	return mDesktop; 
}

#pragma mark -
#pragma mark NSWindowController overrides 

- (void) windowDidLoad {
	// color labels 
	NSArray* colors = [NSArray arrayWithObjects: 
		[NSColor redColor], 
		[NSColor orangeColor],
		[NSColor yellowColor],
		[NSColor greenColor], 
		[NSColor blueColor],
		[NSColor magentaColor],
		[NSColor lightGrayColor],
		nil]; 
	[mLabelButton setDisplaysClearButton: YES]; 
	[mLabelButton setColorLabels: colors]; 
	
	// Decorations table view 
	[mDecorationsTableView registerForDraggedTypes: [NSArray arrayWithObjects: kVtMovedRowsDropType, nil]];	
	[self createDecorationAddMenu]; 
	
	[[self window] setAcceptsMouseMovedEvents: YES]; 
	[[self window] setHidesOnDeactivate: NO];
	[[self window] setDelegate: self]; 
	
	// create inspector 
	mInspectorController = [[VTDecorationPrimitiveViewController alloc] init]; 
		
	// set up the desktop collection controller 
	[mDesktopsController bind: @"contentArray" 
									 toObject: mActiveDesktopLayout
								withKeyPath: @"orderedDesktops" 
										options: nil];

	// set up delete button binding 
	[mDeleteDesktopButton bind: @"enabled" 
										toObject: [VTDesktopController sharedInstance] 
								 withKeyPath: @"canDelete" 
										 options: nil]; 
	
	//Setup add button binding
	[mAddDesktopButton bind: @"enabled"
								 toObject: [VTDesktopController sharedInstance]
							withKeyPath: @"canAdd"
									options: nil];
	
	// and select a desktop 
	[self showDesktop: [self selectedDesktop]]; 
}


#pragma mark -
#pragma mark NSWindow delegate 

- (void) windowWillClose: (NSNotification*) notification {	
	// remove bindings 
	[mImageView 					unbind: @"imagePath"];
	[mLabelButton 				unbind: @"selectedColorLabel"]; 
  [mDesktop             unbind: @"showsBackground"];
	[mDesktop 						unbind: @"desktopBackground"];
	[mDesktop 						unbind: @"colorLabel"]; 
	[mDeleteDesktopButton unbind: @"enabled"]; 
	
	// and write out preferences to be sure 
	[[NSUserDefaults standardUserDefaults] synchronize]; 
	// and also the desktop settings 
	[[VTDesktopController sharedInstance] serializeDesktops]; 
}

#pragma mark -
#pragma mark NSTableView delegate 
- (void) tableViewSelectionDidChange: (NSNotification*) notification {
	// Desktops table view
	if ([[notification object] isEqual: mDesktopsTableView]) 
		[self showDesktop: [self selectedDesktop]];
}

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

- (BOOL)tableView:(NSTableView*)delegateTableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op {
	// Decorations table view
	if ([delegateTableView isEqual: mDecorationsTableView]) {   
		if (row < 0)
			row = 0;
    
		// if drag source is self, it's a move
		if ([info draggingSource] == mDecorationsTableView) {
			NSArray*	rows				= [[info draggingPasteboard] propertyListForType: kVtMovedRowsDropType];
			int				fromIndex   = [[rows objectAtIndex: 0] intValue]; 
		
			// if the index would not change, we do not do anything 
			if (fromIndex == row)
				return NO; 
		
			[mDecorationsController setSelectionIndex: -1]; 
			[[mDesktop decoration] moveObjectAtIndex: fromIndex toIndex: row]; 
			[mDecorationsController setSelectionIndex: row]; 
		
			return YES;
		}
	
		return NO;
	}
	
	return NO; 
}

#pragma mark -
#pragma mark Modal delegate 
- (void) inspectorPanelDidEnd: (NSWindow*) sheet returnCode: (int) returnCode contextInfo: (void*) contextInfo {
	// set button state of inspector button to off 
	[mInspectPrimitiveButton setState: NSOffState]; 
}

@end

#pragma mark -
@implementation VTDesktopViewController (Selection) 

- (VTDesktop*) selectedDesktop {
	int selectedIndex = [mDesktopsController selectionIndex]; 
	
	if (selectedIndex == NSNotFound)
		return nil; 
	
	return [[[[VTLayoutController sharedInstance] activeLayout] orderedDesktops] objectAtIndex: selectedIndex]; 
}

- (void) setSelectedDesktop: (VTDesktop*) desktop {
	// get index of passed desktop 
	unsigned int index = [[[[VTLayoutController sharedInstance] activeLayout] orderedDesktops] indexOfObject: desktop]; 
	// and select it in the table view 
	[mDesktopsTableView selectRowIndexes: [NSIndexSet indexSetWithIndex: index] 
									byExtendingSelection: NO];
}

- (void) showDesktop: (VTDesktop*) desktop {
	// remove bindings 
	[mImageView		unbind: @"imagePath"];
	[mLabelButton unbind: @"selectedColorLabel"]; 
	[mDesktop			unbind: @"desktopBackground"];
	[mDesktop			unbind: @"colorLabel"]; 
	
	// attributes 
	ZEN_ASSIGN(mDesktop, desktop);
		
  [mImageView   setImagePath:     [mDesktop desktopBackground]];
	[mLabelButton selectColorLabel: [mDesktop colorLabel]];
  
	// configure image view binding 
	[mDesktop   bind: @"desktopBackground"  toObject: mImageView  withKeyPath: @"imagePath"         options: nil];
	[mImageView bind: @"imagePath"          toObject: mDesktop    withKeyPath: @"desktopBackground" options: nil]; 
	
	// configure color label binding 
	[mDesktop     bind: @"colorLabel"         toObject: mLabelButton  withKeyPath: @"selectedColorLabel"  options: nil];
	[mLabelButton	bind: @"selectedColorLabel" toObject: mDesktop      withKeyPath: @"colorLabel"          options: nil]; 
}

@end 

#pragma mark -
@implementation VTDesktopViewController (Decorations) 
- (VTInspector*) inspectorForPrimitive: (VTDecorationPrimitive*) primitive {
	return [mPrimitiveInspectors objectForKey: NSStringFromClass([primitive class])]; 
}

- (VTDecorationPrimitive*) selectedPrimitive {
	int selectionIndex = [mDecorationsController selectionIndex]; 
	
	// no selection, no primitive  
	if (selectionIndex == NSNotFound)
		return nil; 
	
	return [[[mDesktop decoration] decorationPrimitives] objectAtIndex: selectionIndex]; 	
}

- (void) onAddPrimitive: (id) sender {
	// fetch information needed to perform operation
	Class			primitiveClass = NSClassFromString([sender representedObject]);
	NSString*	primitiveName  = [sender title]; 
	
	// create a new instance of the fetched class and ... 
	VTDecorationPrimitive* primitive = [[primitiveClass alloc] init];
	[primitive setName: primitiveName]; 
	
	// insert it into the decoration collection 
	[[mDesktop decoration] addDecorationPrimitive: primitive]; 
}

- (void) createDecorationAddMenu {
	NSMenuItem* item; 	
	
	// we expect the menu to be empty... and start creating our 
	// items beginning with built-in items at the top... 
	
	// Text-Primitive 
	item = [[[NSMenuItem alloc] initWithTitle: NSLocalizedStringFromTable(NSStringFromClass([VTDecorationPrimitiveText class]), @"DefaultPrimitiveNames", @"Text Primitive") 
																		 action: @selector(onAddPrimitive:) 
															keyEquivalent: @""] autorelease]; 
	
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
	NSArray*					pluginDecorations	= [[VTPluginCollection sharedInstance] pluginsOfType: @protocol(VTPluginDecoration)]; 
	NSEnumerator*			pluginIter				= [pluginDecorations objectEnumerator]; 
	VTPluginInstance*	plugin						= nil; 
	
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
	NSEnumerator*		pluginIter				= [pluginDecorations objectEnumerator]; 
	
	id<VTPluginDecoration>	plugin				= nil; 
	
	while (plugin = [[pluginIter nextObject] instance]) {
		inspector = [plugin decorationPrimitiveInspector]; 
		
		if (inspector == nil)
			continue; 
		
		[mPrimitiveInspectors setObject: inspector forKey: NSStringFromClass([plugin decorationPrimitiveClass])]; 
	}	
}

@end 