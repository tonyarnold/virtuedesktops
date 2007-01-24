/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTDesktopViewDecorationsController.h"
#import "VTDecorationPrimitiveBindings.h" 
#import "VTDecorationPrimitiveTextInspector.h" 
#import "VTDecorationPrimitiveTintInspector.h" 
#import "VTDecorationPrimitiveWatermarkInspector.h" 
#import "VTDecorationPrimitivePositionMarkers.h" 
#import "VTPluginCollection.h" 
#import "VTDesktopDecorationController.h"
#import "VTDecorationPrimitiveText.h"
#import "VTDecorationPrimitiveTint.h"
#import "VTDecorationPrimitiveWatermark.h"
#import "VTPlugin.h" 
#import <Zen/Zen.h> 

#define kVtMovedRowsDropType @"VIRTUE_DESKTOP_COLLECTION_MOVE"

#pragma mark -
@interface VTDesktopViewDecorationsController (Private) 
- (void) createInspectors;
- (void) createAddMenu; 
#pragma mark -
- (void) updateInspector; 
#pragma mark -
- (VTDecorationPrimitive*) selectedPrimitive; 
#pragma mark -
- (void) setInspectedObject: (VTDecorationPrimitive*) primitive withInspector: (VTInspector*) inspector; 
@end 

#pragma mark -
@implementation VTDesktopViewDecorationsController

#pragma mark -
#pragma mark Lifetime 
- (id) init {
	if (self = [super init]) {
		// attributes 
		mDesktop				= nil; 
		mPrimitiveInspectors	= [[NSMutableDictionary alloc] init]; 
			
		mCurrentInspectorView	= nil; 
		mCurrentInspector		= nil; 
		mCurrentPrimitive		= nil; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {	
	// close the inspector if we got any 
	ZEN_RELEASE(mCurrentInspectorView); 
	ZEN_RELEASE(mCurrentInspector); 
	ZEN_RELEASE(mCurrentPrimitive); 
	
	ZEN_RELEASE(mDesktop); 
	ZEN_RELEASE(mPrimitiveInspectors); 
		
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 
- (void) setDesktop: (VTDesktop*) desktop {
	ZEN_ASSIGN(mDesktop, desktop); 

	// and also take care of our controller object 
	[mDecorationController setContent: [mDesktop decoration]]; 	
}

#pragma mark -
#pragma mark Actions 
- (IBAction) showInspector: (id) sender {
	[mDrawer toggle: sender]; 
}

- (IBAction) deletePrimitive: (id) sender {
	// fetch the currently selected primitive and remove it from our container 
	VTDecorationPrimitive* selectedPrimitive = [self selectedPrimitive]; 
	
	// no primitive, nothing to do here 
	if (selectedPrimitive == nil)
		return; 
	
	[[mDesktop decoration] delDecorationPrimitive: selectedPrimitive]; 
}

- (IBAction) orderUpPrimitive: (id) sender {
}

- (IBAction) orderDownPrimitive: (id) sender {
}

#pragma mark -
#pragma mark NSWindow delegates 
- (void) windowWillClose: (NSNotification*) notification {
	[mPrimitiveController setContent: nil]; 
	[mDecorationView unregisterDraggedTypes]; 
}

#pragma mark -
#pragma mark NSObject delegates 

- (void) awakeFromNib {
	[self createInspectors]; 
	[self createAddMenu]; 
	
	// setup our buttons 
	[mDeleteButton setImage: [NSImage imageNamed: @"imageWidgetDelete.png"]]; 
	[mDeleteButton setAlternateImage: [NSImage imageNamed: @"imageWidgetDeletePressed.png"]]; 
	[mInfoButton setImage: [NSImage imageNamed: @"imageWidgetInfo.png"]]; 
	[mInfoButton setAlternateImage: [NSImage imageNamed: @"imageWidgetInfoPressed.png"]]; 
	[mAddButton setImage: [NSImage imageNamed: @"imageWidgetAddPopup.png"]]; 
	[mAddButton setAlternateImage: [NSImage imageNamed: @"imageWidgetAddPopupPressed.png"]]; 
	
	// position view 
	[mPositionGrid setTarget: self]; 
	[mPositionGrid setAction: @selector(onPositionSelected:)]; 
	
	// prepare the table view for drag and drop operations 
	[mDecorationView registerForDraggedTypes: [NSArray arrayWithObjects: kVtMovedRowsDropType, nil]];	
}

#pragma mark -
#pragma mark NSTableView delegate 

- (void) tableViewSelectionDidChange: (NSNotification*) aNotification {
	// update delete button 
	if ([self selectedPrimitive] == nil)
		[mDeleteButton setEnabled: NO]; 
	else
		[mDeleteButton setEnabled: YES]; 
	
	// if we are displaying the inspector, change the object there 
	[self updateInspector]; 
}

- (BOOL) tableView: (NSTableView*) tv writeRows: (NSArray*) rows toPasteboard: (NSPasteboard*) pboard {
    NSArray* typesArray = [NSArray arrayWithObjects: kVtMovedRowsDropType, nil];
	[pboard declareTypes: typesArray owner: self];
	
    // add rows array for local move
    [pboard setPropertyList: rows forType: kVtMovedRowsDropType];
	
	return YES; 
}

- (NSDragOperation) tableView: (NSTableView*) tv validateDrop: (id <NSDraggingInfo>) info proposedRow: (int) row proposedDropOperation: (NSTableViewDropOperation) op {
    NSDragOperation dragOp = NSDragOperationCopy;
    
    // if drag source is self, it's a move
    if ([info draggingSource] == mDecorationView) {
		dragOp = NSDragOperationMove;
    }
	
    // we want to put the object at, not over, the current row (contrast NSTableViewDropOn) 
    [tv setDropRow: row dropOperation: NSTableViewDropAbove];
	
    return dragOp;
}

- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op {
    if (row < 0)
		row = 0;
    
    // if drag source is self, it's a move
    if ([info draggingSource] == mDecorationView) {
		NSArray*	rows		= [[info draggingPasteboard] propertyListForType: kVtMovedRowsDropType];
		int			fromIndex   = [[rows objectAtIndex: 0] intValue]; 
		
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

#pragma mark -
#pragma mark NSMenu Actions 

- (void) onAddPrimitive: (id) sender {
	// fetch information needed to perform operation
	Class primitiveClass = NSClassFromString([sender representedObject]); 
	
	// create a new instance of the fetched class and ... 
	VTDecorationPrimitive* primitive = [[primitiveClass alloc] init]; 
	// insert it into the decoration collection 
	[[mDesktop decoration] addDecorationPrimitive: primitive]; 
}

#pragma mark -
#pragma mark Actions 
- (void) onPositionSelected: (id) sender {
	if (mCurrentPrimitive == nil) 
		return; 
	
	[mCurrentPrimitive setMarkerPosition: [mPositionGrid selectedMarker]];  
}


@end

#pragma mark -
@implementation VTDesktopViewDecorationsController (Private) 

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
	[mPrimitiveInspectors setObject: inspector forKey: @"VTDecorationPrimitiveWatermark"]; 
	
	// Plugins 
	NSArray*				pluginDecorations	= [[VTPluginCollection sharedInstance] pluginsOfType: @protocol(VTPluginDecoration)]; 
	NSEnumerator*			pluginIter			= [pluginDecorations objectEnumerator]; 
	id<VTPluginDecoration>	plugin				= nil; 
	
	while (plugin = [[pluginIter nextObject] instance]) {
		inspector = [plugin decorationPrimitiveInspector]; 
		
		if (inspector == nil)
			continue; 
		
		[mPrimitiveInspectors setObject: inspector forKey: NSStringFromClass([plugin decorationPrimitiveClass])]; 
	}
	
}

- (void) createAddMenu {
	NSMenuItem* item; 	
	
	// we expect the menu to be empty... and start creating our 
	// items beginning with built-in items at the top... 
	
	// Text-Primitive 
	item = [[[NSMenuItem alloc] initWithTitle: @"Text Primitive" action: @selector(onAddPrimitive:) keyEquivalent: @""] autorelease]; 
	[item setRepresentedObject: NSStringFromClass([VTDecorationPrimitiveText class])]; 
	[item setTarget: self]; 
	[mAddMenu addItem: item]; 
	// Tint-Primitive 
	item = [[[NSMenuItem alloc] initWithTitle: @"Tint Primitive" action: @selector(onAddPrimitive:) keyEquivalent: @""] autorelease]; 
	[item setRepresentedObject: NSStringFromClass([VTDecorationPrimitiveTint class])]; 
	[item setTarget: self]; 
	[mAddMenu addItem: item]; 
	// Watermark-Primitive 
	item = [[[NSMenuItem alloc] initWithTitle: @"Watermark Primitive" action: @selector(onAddPrimitive:) keyEquivalent: @""] autorelease]; 
	[item setRepresentedObject: NSStringFromClass([VTDecorationPrimitiveWatermark class])]; 
	[item setTarget: self]; 
	[mAddMenu addItem: item]; 
	// Separator 
	[mAddMenu addItem: [NSMenuItem separatorItem]]; 
	
	// Plugins 
	NSArray*				pluginDecorations	= [[VTPluginCollection sharedInstance] pluginsOfType: @protocol(VTPluginDecoration)]; 
	NSEnumerator*			pluginIter			= [pluginDecorations objectEnumerator]; 
	id<VTPluginDecoration>	plugin				= nil; 
	
	while (plugin = [[pluginIter nextObject] instance]) {
		item = [[[NSMenuItem alloc] initWithTitle: [plugin pluginDisplayName] action: @selector(onAddPrimitive:) keyEquivalent: @""] autorelease]; 
		[item setRepresentedObject: NSStringFromClass([plugin decorationPrimitiveClass])]; 
		[item setTarget: self]; 
		[mAddMenu addItem: item]; 
	}
}

#pragma mark -
- (void) updateInspector {
	VTDecorationPrimitive* selectedPrimitive = [self selectedPrimitive]; 

	if (selectedPrimitive == nil) {
		[self setInspectedObject: nil withInspector: nil]; 
		return; 
	}
	
	// set inspector according to selected primitive 
	VTInspector* inspector = [mPrimitiveInspectors objectForKey: NSStringFromClass([selectedPrimitive class])]; 
	
	// no inspector for the view, no inspector to display 
	if (inspector == nil) {
		[self setInspectedObject: selectedPrimitive withInspector: nil]; 
		return; 
	}
	
	// now set up the inspector object... 
	[inspector setInspectedObject: selectedPrimitive]; 
	// and the inspector view 
	[self setInspectedObject: selectedPrimitive withInspector: inspector]; 	
}

#pragma mark -
- (VTDecorationPrimitive*) selectedPrimitive {
	int selectionIndex = [mDecorationsController selectionIndex]; 
	
	// no selection, no primitive  
	if (selectionIndex == NSNotFound)
		return nil; 

	return [[[mDesktop decoration] decorationPrimitives] objectAtIndex: selectionIndex]; 
}

#pragma mark -
- (void) setInspectedObject: (VTDecorationPrimitive*) primitive withInspector: (VTInspector*) inspector {
	
	// first we have to remove the current inspector view from our box ...
	if (mCurrentInspectorView) {
		ZEN_RELEASE(mCurrentInspectorView); 
	}
	// ... and unselect the current inspector 
	if (mCurrentInspector) 
		[mCurrentInspector didUnselect]; 
	
	ZEN_ASSIGN(mCurrentPrimitive, primitive); 
	ZEN_ASSIGN(mCurrentInspector, inspector); 
	
	// primitive view
	if (mCurrentPrimitive)
		[mDrawer setContentView: mPrimitiveView]; 
	else 
		[mDrawer setContentView: mPrimitiveNoneView]; 
	
	// get the new inspector view...
	if (mCurrentInspector) 
		mCurrentInspectorView = [[mCurrentInspector mainView] retain];  
	
	if (mCurrentInspectorView) {
		[mInspectorContainer setContentView: mCurrentInspectorView]; 
	}
	else {
		[mInspectorContainer setContentView: mInspectorNonView]; 
	}
	
	// handle inspector 
	if (mCurrentInspector)
		[mCurrentInspector didSelect]; 
	
	// handle controller content 
	[mPrimitiveController setContent: primitive];
	
	if (primitive) {
		[mPositionGrid setMarkers: [primitive supportedMarkers]]; 
		[mPositionGrid setSelectedMarker: [primitive markerPosition]]; 
	}
	else {
		[mPositionGrid setMarkers: nil]; 
	}

	ZEN_ASSIGN(mCurrentPrimitive, primitive); 
	
}

@end 