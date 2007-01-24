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

#import "VTDesktopDecorationViewController.h"
#import "VTDesktopDecorationController.h"
#import "VTDecorationPrimitiveText.h"
#import "VTDecorationPrimitiveTint.h"
#import "VTDecorationPrimitiveWatermark.h"
#import "VTPlugin.h"
#import <Zen/Zen.h> 

#import "VTDecorationPrimitiveTextInspector.h" 
#import "VTDecorationPrimitiveBindings.h" 
#import "VTDecorationPrimitiveTintInspector.h" 
#import "VTPluginController.h"

#define kVtPrimitiveText		@"VTDecorationPrimitiveText"
#define kVtPrimitiveTint		@"VTDecorationPrimitiveTint"
#define kVtPrimitiveWatermark	@"VTDecorationPrimitiveWatermark"

@interface VTDesktopDecorationViewController (Private) 
- (void) createInspectors; 
- (void) createToolbarItems;

- (NSArray*) itemIdentifiers; 
@end 

@implementation VTDesktopDecorationViewController

#pragma mark -
#pragma mark Lifetime 

- (id) initWithDesktop: (VTDesktop*) desktop {
	if (self = [super initWithWindowNibName: @"Decoration"]) {
		// attributes 
		ZEN_ASSIGN(mDesktop, desktop); 

		// toolbar 
		mToolbar				= nil; 
		mCurrentInspector		= nil; 
		mToolbarItems			= [[NSMutableDictionary alloc] init]; 
		mPluginIdentifiers		= [[NSMutableArray alloc] init]; 
		mPrimitiveClasses		= [[NSMutableDictionary alloc] init]; 
		mPrimitiveInspectors	= [[NSMutableDictionary alloc] init]; 
		
		return self; 
	}
	
	return nil;
}

- (void) dealloc {
	ZEN_RELEASE(mToolbar); 
	ZEN_RELEASE(mToolbarItems); 
	ZEN_RELEASE(mPluginIdentifiers); 
	ZEN_RELEASE(mPrimitiveClasses); 
	ZEN_RELEASE(mPrimitiveInspectors); 
	ZEN_RELEASE(mCurrentInspector); 
	ZEN_RELEASE(mDesktop); 
	
	[super dealloc]; 
}


#pragma mark -
#pragma mark Attributes 

- (VTDesktop*) desktop {
	return mDesktop; 
}

#pragma mark -
#pragma mark NSWindowController overrides 

- (void) windowDidLoad {
	// handle the controller 
	[mDecorationController setContent: [mDesktop decoration]]; 
	
	// configure the window to not hide on deactivation
	[[self window] setHidesOnDeactivate: NO]; 
	
	// the toolbar 
	mToolbar = [[NSToolbar alloc] initWithIdentifier: @"DesktopDecorationToolbar"]; 
	
	[mToolbar setDelegate: self]; 
	[mToolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel]; 
	[mToolbar setAutosavesConfiguration: NO]; 
	
	[self createToolbarItems]; 
	[self createInspectors]; 
	
	// add the toolbar 
	[[self window] setToolbar: mToolbar]; 
}

#pragma mark -
#pragma mark NSWindow delegate 

- (void) windowWillClose: (NSNotification*) notification {
	// autoreleasing ourselves 
	[self autorelease]; 
}

#pragma mark -
#pragma mark NSToolbar delegate 

- (NSToolbarItem*) toolbar: (NSToolbar*) theToolbar itemForItemIdentifier: (NSString*) identifier willBeInsertedIntoToolbar: (BOOL) flag {
	return [mToolbarItems objectForKey: identifier]; 
}

- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar*) theToolbar {
	// we will assemble the array on our own to ensure the proper order 
	return [self itemIdentifiers];  
}

- (NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar*) theToolbar {
	return [self itemIdentifiers];  
}

- (BOOL) validateToolbarItem: (NSToolbarItem*) item {
	return YES; 
}	

#pragma mark -
#pragma mark Actions 

- (void) onToolbarClicked: (id) sender {
	// fetch information needed to perform operation
	Class primitiveClass = [mPrimitiveClasses objectForKey: [sender itemIdentifier]]; 
	
	// create a new instance and delete it again, for testing purposes 
	VTDecorationPrimitive* primitive = [[primitiveClass alloc] init]; 
	
	[[mDesktop decoration] willChangeValueForKey: @"decorationPrimitives"]; 
	[[mDesktop decoration] addDecorationPrimitive: primitive]; 
	[[mDesktop decoration] didChangeValueForKey: @"decorationPrimitives"]; 
}


#pragma mark -
#pragma mark NSTableView delegate 

- (void) tableViewSelectionDidChange: (NSNotification*) aNotification {
	[mCurrentInspectorView removeFromSuperview]; 
	ZEN_RELEASE(mCurrentInspectorView); 
	
	[mCurrentInspector didUnselect]; 
	ZEN_RELEASE(mCurrentInspector); 
	
	if ([mDecorationsController selectionIndex] == NSNotFound) {
		[mDecorationInspectorBox setTitle: @"No selection"]; 
		
		mCurrentInspector = nil; 
		mCurrentInspectorView = nil; 
		
		return; 
	}
	
	int selectionIndex = [mDecorationsController selectionIndex]; 
	VTDecorationPrimitive*	primitive	= [[[mDesktop decoration] decorationPrimitives] objectAtIndex: selectionIndex]; 
	VTInspector*			inspector	= [mPrimitiveInspectors objectForKey: NSStringFromClass([primitive class])]; 
	
	if (inspector == nil)
		return; 
		
	// and activate the inspector 
	mCurrentInspectorView	= [[inspector mainView] retain];  
	mCurrentInspector		= [inspector retain]; 
	// add it as a subview 
	[[mDecorationInspectorBox contentView] addSubview: mCurrentInspectorView]; 
	// notify inspector that it is now showing 
	[mCurrentInspector setInspectedObject: primitive]; 
	[mCurrentInspector didSelect]; 
}

@end 

#pragma mark -
@implementation VTDesktopDecorationViewController (Private) 

- (void) createInspectors {
	// create built-in inspectors
	VTInspector* inspector = nil; 
	
	// VTDecorationPrimitiveTextInspector 
	inspector = [[VTDecorationPrimitiveTextInspector alloc] init]; 
	[mPrimitiveInspectors setObject: inspector forKey: NSStringFromClass([VTDecorationPrimitiveText class])]; 
	// VTDecorationPrimitiveTintInspector 
	inspector = [[VTDecorationPrimitiveTintInspector alloc] init]; 
	[mPrimitiveInspectors setObject: inspector forKey: NSStringFromClass([VTDecorationPrimitiveTint class])]; 
	
	// Plugins 
	NSArray*		pluginDecorations	= [[VTPluginController sharedInstance] pluginsOfType: @protocol(VTPluginDecoration)]; 
	NSEnumerator*	pluginIter			= [pluginDecorations objectEnumerator]; 
	VTPluginBase<VTPluginDecoration>* plugin = nil; 
	
	while (plugin = [pluginIter nextObject]) {
		inspector = [plugin decorationPrimitiveInspector]; 
		
		if (inspector == nil)
			continue; 
		
		[mPrimitiveInspectors setObject: inspector forKey: NSStringFromClass([plugin decorationPrimitiveClass])]; 
	}
		
	
}

- (void) createToolbarItems { 
	NSToolbarItem* toolbarItem = nil; 
	
	// create the built in items first
	// Text Primitive 
	toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: kVtPrimitiveText] autorelease]; 
	[toolbarItem setLabel: @"Text"]; 
	[toolbarItem setTarget: self]; 
	[toolbarItem setAction: @selector(onToolbarClicked:)]; 
	[toolbarItem setImage: [NSImage imageNamed: @"imageText.tiff"]]; 

	[mToolbarItems setObject: toolbarItem forKey: kVtPrimitiveText]; 
	[mPrimitiveClasses setObject: [VTDecorationPrimitiveText class] forKey: kVtPrimitiveText];

	// Tint Primitive 
	toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: kVtPrimitiveTint] autorelease]; 
	[toolbarItem setLabel: @"Tint"]; 
	[toolbarItem setTarget: self]; 
	[toolbarItem setAction: @selector(onToolbarClicked:)]; 
	[toolbarItem setImage: [NSImage imageNamed: @"imageTint.tiff"]]; 
	
	[mToolbarItems setObject: toolbarItem forKey: kVtPrimitiveTint]; 
	[mPrimitiveClasses setObject: [VTDecorationPrimitiveTint class] forKey: kVtPrimitiveTint]; 

	// Watermark Primitive 
	toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: kVtPrimitiveWatermark] autorelease]; 
	[toolbarItem setLabel: @"Watermark"]; 
	[toolbarItem setTarget: self]; 
	[toolbarItem setAction: @selector(onToolbarClicked:)]; 
	[toolbarItem setImage: [NSImage imageNamed: @"imageImage.png"]]; 
	
	[mToolbarItems setObject: toolbarItem forKey: kVtPrimitiveWatermark]; 
	[mPrimitiveClasses setObject: [VTDecorationPrimitiveWatermark class] forKey: kVtPrimitiveWatermark]; 
	
	
	// now we are adding plugin decorations 
	NSArray*		pluginDecorations	= [[VTPluginController sharedInstance] pluginsOfType: @protocol(VTPluginDecoration)]; 
	NSEnumerator*	pluginIter			= [pluginDecorations objectEnumerator]; 
	VTPluginBase<VTPluginDecoration>* plugin = nil; 
	
	while (plugin = [pluginIter nextObject]) {
		toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: [plugin pluginIdentifier]] autorelease]; 
		[toolbarItem setLabel: [plugin pluginName]]; 
		[toolbarItem setTarget: self]; 
		[toolbarItem setAction: @selector(onToolbarClicked:)]; 
		[toolbarItem setImage: [[[NSImage alloc] initByReferencingFile: [plugin pluginIconPath]] autorelease]]; 
	
		[mToolbarItems setObject: toolbarItem forKey: [plugin pluginIdentifier]]; 
		[mPluginIdentifiers addObject: [plugin pluginIdentifier]]; 
		[mPrimitiveClasses setObject: [plugin decorationPrimitiveClass] forKey: [plugin pluginIdentifier]]; 
		
	}
}

- (NSArray*) itemIdentifiers {
	NSMutableArray* identifiers = [NSMutableArray array]; 
	
	// built-in
	[identifiers addObject: kVtPrimitiveText]; 
	[identifiers addObject: kVtPrimitiveTint]; 
	[identifiers addObject: kVtPrimitiveWatermark]; 
	// ---
	[identifiers addObject: NSToolbarSeparatorItemIdentifier]; 
	// plugins 
	[identifiers addObjectsFromArray: mPluginIdentifiers]; 
	
	return identifiers; 
}

@end 
