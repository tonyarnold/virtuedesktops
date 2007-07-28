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

#import "VTDesktopController.h"
#import "VTNotifications.h"
#import <Peony/Peony.h> 
#import <Zen/Zen.h> 

#import "VTDesktopCollectionViewController.h"
#import "VTDesktopViewController.h"


#define VTDesktopInspectIdentifier	@"VTDesktopInspectIdentifier"
#define VTDesktopAddIdentifier		@"VTDesktopAddIdentifier"
#define VTDesktopDeleteIdentifier	@"VTDesktopDeleteIdentifier"


#pragma mark -
@interface VTDesktopCollectionViewController (Private) 
#pragma mark -
- (void) bindDesktop: (VTDesktop*) desktop; 
- (void) unbindDesktop: (VTDesktop*) desktop; 
#pragma mark -
- (id) selectedItem; 
#pragma mark -
- (NSArray*) itemIdentifiers; 
#pragma mark -
- (NSAttributedString*) desktopDescription: (VTDesktop*) desktop; 
- (NSAttributedString*) applicationDescription: (PNApplication*) application; 
- (NSAttributedString*) windowDescription: (PNWindow*) window; 
@end 

#pragma mark -
@implementation VTDesktopCollectionViewController

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super initWithWindowNibName: @"DesktopCollection"]) {
		// attributes 
		mToolbar		= nil; 
		mToolbarItems	= [[NSMutableDictionary alloc] init]; 
    
		// caches 
		mApplicationCache = [[NSMutableDictionary alloc] init]; 
		// bindings to our desktops to update the outline view 
		[[VTDesktopController sharedInstance] addObserver: self forKeyPath: @"desktops" options: NSKeyValueObservingOptionNew context: NULL]; 
		// let there be notifications about desktop additions and removals 
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopWasAdded:) name: VTDesktopDidAddNotification object: nil];
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(onDesktopWasRemoved:) name: VTDesktopDidRemoveNotification object: nil]; 
		
		// and attach to all our known desktops 
		NSEnumerator*	desktopIter = [[[VTDesktopController sharedInstance] desktops] objectEnumerator]; 
		VTDesktop*		desktop		= nil; 
		
		while (desktop = [desktopIter nextObject]) {
			[self bindDesktop: desktop]; 
		}
		
		return self; 
	}
	
	return nil;
}

- (void) dealloc {
	// attributes 
	ZEN_RELEASE(mToolbar); 
	ZEN_RELEASE(mToolbarItems); 
	
	ZEN_RELEASE(mApplicationCache); 
	
	// observers 
	[[VTDesktopController sharedInstance] removeObserver: self forKeyPath: @"desktops"]; 
	[[NSNotificationCenter defaultCenter] removeObserver: self]; 
  
	// all desktops.. 
	NSEnumerator*	desktopIter = [[[VTDesktopController sharedInstance] desktops] objectEnumerator]; 
	VTDesktop*		desktop		= nil; 
	
	while (desktop = [desktopIter nextObject]) {
		[self unbindDesktop: desktop]; 
	}
	
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Actions 

- (void) onDesktopAdd: (id) sender {
	// create a new desktop 
	VTDesktop*	newDesktop		= [[VTDesktopController sharedInstance] desktopWithFreeId]; 
	// set up the desktop 
	[newDesktop setName: [NSString stringWithFormat: @"Desktop %i", [newDesktop identifier]]]; 
	// and add it to our collection 
	[[VTDesktopController sharedInstance] addInDesktops: newDesktop]; 
}

- (void) onDesktopDelete: (id) sender {
	// the selected item plus sanity check 
	id  selectedItem = [self selectedItem]; 
	if ([selectedItem isKindOfClass: [VTDesktop class]] == NO)
		return; 
	
	VTDesktop*	desktop			= (VTDesktop*) selectedItem; 
  int                     desktopIndex    = [[[VTDesktopController sharedInstance] desktops] indexOfObject: desktop];
  
  // remove the selected desktop
  [[VTDesktopController sharedInstance] removeObjectFromDesktopsAtIndex: desktopIndex];
}

- (void) onDesktopInspect: (id) sender {
	// the selected item plus sanity check 
	id  selectedItem = [self selectedItem]; 
	if ([selectedItem isKindOfClass: [VTDesktop class]] == NO)
		return; 
	
	VTDesktop* desktop = (VTDesktop*) selectedItem; 
	
	// create us a new inspector and display 
	VTDesktopViewController* controller = [[VTDesktopViewController alloc] initWithDesktop: desktop]; 
	[controller window]; 
	[controller showWindow: sender]; 
}


#pragma mark -
#pragma mark NSWindowController overrides 

- (void) windowDidLoad {
	// configure the window to not hide on deactivation
	[[self window] setHidesOnDeactivate: NO]; 
		
	// configure the toolbar 
	mToolbar = [[NSToolbar alloc] initWithIdentifier: @"DesktopCollectionToolbar"]; 
	
	// create the needed toolbar items 
	NSToolbarItem* toolbarItem = nil; 
	
	// Add
	toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: VTDesktopAddIdentifier] autorelease]; 
	[toolbarItem setLabel: @"Add"]; 
	[toolbarItem setImage: [NSImage imageNamed: @"imageDesktopAdd.png"]]; 
	[toolbarItem setTarget: self]; 
	[toolbarItem setAction: @selector(onDesktopAdd:)]; 
	[mToolbarItems setObject: toolbarItem forKey: VTDesktopAddIdentifier]; 
	
	// Delete
	toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: VTDesktopDeleteIdentifier] autorelease]; 
	[toolbarItem setLabel: @"Delete"]; 
	[toolbarItem setImage: [NSImage imageNamed: @"imageDesktopDelete.png"]]; 
	[toolbarItem setTarget: self]; 
	[toolbarItem setAction: @selector(onDesktopDelete:)]; 
	[mToolbarItems setObject: toolbarItem forKey: VTDesktopDeleteIdentifier]; 
	
	// Inspect 
	toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: VTDesktopInspectIdentifier] autorelease]; 
	[toolbarItem setLabel: @"Info"]; 
	[toolbarItem setImage: [NSImage imageNamed: @"imageInfo.tif"]]; 	
	[toolbarItem setTarget: self]; 
	[toolbarItem setAction: @selector(onDesktopInspect:)]; 
	[mToolbarItems setObject: toolbarItem forKey: VTDesktopInspectIdentifier]; 
		
	[mToolbar setDelegate: self]; 
	[mToolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel]; 
	[mToolbar setAutosavesConfiguration: NO]; 
	[mToolbar setSelectedItemIdentifier: VTDesktopAddIdentifier];
		
	// add the toolbar 
	[[self window] setToolbar: mToolbar]; 
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
	if ([[item itemIdentifier] isEqualToString: VTDesktopDeleteIdentifier]) {
		// check that we got a desktop selected 
		if ([[self selectedItem] isKindOfClass: [VTDesktop class]] == NO)
			return NO; 
		
		return [[VTDesktopController sharedInstance] canDelete]; 
	}
	if ([[item itemIdentifier] isEqualToString: VTDesktopInspectIdentifier]) {
		return ([self selectedItem] != nil); 
	}
	
	return YES; 
}	


#pragma mark -
#pragma mark NSOutlineView DataSource implementation 

- (id) outlineView: (NSOutlineView*) outlineView child: (int) olIndex ofItem: (id) item {
  //	if (item == nil) {
  //		// fetch desktop as the top-level item 
  //		return [[[VTDesktopController sharedInstance] desktops] objectAtIndex: index]; 
  //	}
	
	// we are dealing with a desktop item here 
	if ([item isKindOfClass: [VTDesktop class]]) {
		VTDesktop* desktop = (VTDesktop*)item; 
		
		// fetch all of its applications and return the correct application instance 
		NSArray* applications = [desktop applications]; 
		return [applications objectAtIndex: olIndex]; 
	}
	
	// we are dealing with an application item here 
	if ([item isKindOfClass: [PNApplication class]]) {
		PNApplication*	application	= (PNApplication*)item; 
    
		// fetch all of its windows and return the correct window instance 
		NSArray* applicationWindows	= [application windows];
		
		return [applicationWindows objectAtIndex: olIndex]; 
	}
	
	// nothing if we are not asked for the toplevel item or the item is no
	// application or desktop object 
	return nil; 
}

- (BOOL) outlineView: (NSOutlineView*) outlineView isItemExpandable: (id) item {
	// windows never expand 
	if ([item isKindOfClass: [PNWindow class]])
		return NO; 
	
	// here we have to decide if we should expand based on the number of subitems 
	if ([item isKindOfClass: [VTDesktop class]]) 
		return ([[(VTDesktop*)item applications] count] > 0); 
	if ([item isKindOfClass: [PNApplication class]]) 
		return ([[(PNApplication*)item windows] count] > 0); 
	
	// default is no 
	return NO; 
}

- (int) outlineView: (NSOutlineView*) outlineView numberOfChildrenOfItem: (id) item {
	if (item == nil) 
		return [[[VTDesktopController sharedInstance] desktops] count]; 
	
	// desktop items... 
	if ([item isKindOfClass: [VTDesktop class]]) {
		NSArray* applications = [(VTDesktop*)item applications]; 
		return [applications count]; 
	}
	// application items 
	if ([item isKindOfClass: [PNApplication class]]) {
		NSArray* applicationWindows	= [(PNApplication*)item windows]; 
		return [applicationWindows count]; 
	}
	
	return 0; 
}

- (id) outlineView: (NSOutlineView*) outlineView objectValueForTableColumn: (NSTableColumn*) tableColumn byItem: (id) item {
	// desktop items 
	if ([item isKindOfClass: [VTDesktop class]]) {
		return [self desktopDescription: (VTDesktop*)item];  
	}
	
	// application items 
	if ([item isKindOfClass: [PNApplication class]]) {
		return [self applicationDescription: (PNApplication*)item]; 
	}
	
	// window icons 
	if ([item isKindOfClass: [PNWindow class]]) {
		return [self windowDescription: (PNWindow*)item]; 
	}
  
	// nothing to display here 
	return nil; 
}

#pragma mark -
#pragma mark Notification Sink 

- (void) onDesktopWasAdded: (NSNotification*) notification {
	[self bindDesktop: [notification object]]; 
}

- (void) onDesktopWasRemoved: (NSNotification*) notification {
	[self unbindDesktop: [notification object]]; 
}

#pragma mark -
#pragma mark KVO Sink 

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString: @"desktops"] ||
      [keyPath isEqualToString: @"name"] ||
      [keyPath isEqualToString: @"applications"]) {
		// update the outline view 
		[mCollectionOutline reloadData]; 
	} 
}


@end 

#pragma mark -
@implementation VTDesktopCollectionViewController (Private) 

- (NSArray*) itemIdentifiers {
	return [NSArray arrayWithObjects: 
		VTDesktopInspectIdentifier, 
		NSToolbarSeparatorItemIdentifier, 
		VTDesktopAddIdentifier,
		VTDesktopDeleteIdentifier,
		NSToolbarSeparatorItemIdentifier,
		nil]; 
}

#pragma mark -
- (void) bindDesktop: (VTDesktop*) desktop {
	// add observer to the desktop 
	[desktop addObserver: self forKeyPath: @"name" options: NSKeyValueObservingOptionNew context: NULL]; 
	[desktop addObserver: self forKeyPath: @"applications" options: NSKeyValueObservingOptionNew context: NULL]; 	
}

- (void) unbindDesktop: (VTDesktop*) desktop {
	// remove observers of desktop 
	[desktop removeObserver: self forKeyPath: @"name"]; 
	[desktop removeObserver: self forKeyPath: @"applications"]; 	
}

#pragma mark -
- (id) selectedItem {
	int selectionIndex = [mCollectionOutline selectedRow]; 
	if (selectionIndex < 0)
		return nil; 
	
	return [mCollectionOutline itemAtRow: selectionIndex]; 
}

#pragma mark -

- (NSAttributedString*) desktopDescription: (VTDesktop*) desktop {
	// we transform the desktop by extracting the name and applications and return a nicely 
	// formatted attributed string to display 
	NSDictionary* desktopDescriptorAttr = nil; 
	if ([desktop visible]) {
		desktopDescriptorAttr = [NSDictionary dictionaryWithObjectsAndKeys: 
			[NSFont boldSystemFontOfSize: [NSFont systemFontSize]], NSFontAttributeName, 
			nil]; 
	}
	
	NSMutableAttributedString* desktopDescriptor = [[[NSMutableAttributedString alloc] initWithString: [desktop name] attributes: desktopDescriptorAttr] autorelease]; 
	
	NSNumber* applicationCount			= [NSNumber numberWithInt: [[desktop applications] count]]; 
	NSString* applicationCountString	= [applicationCount intValue] == 0 ? @"no" : [applicationCount stringValue]; 
	NSString* applicationString			= [applicationCount intValue] == 1 ? @"application" : @"applications"; 
	
	NSString* applicationDescr			= [NSMutableString stringWithFormat: @"\nShowing %@ %@", applicationCountString, applicationString]; 
	
	// assemble attributed string describing applications open 
	NSDictionary* applicationDescriptorAttr		= [NSDictionary dictionaryWithObjectsAndKeys: 
		[NSFont labelFontOfSize: [NSFont labelFontSize]], NSFontAttributeName,
		[NSColor lightGrayColor], NSForegroundColorAttributeName, 
		nil]; 
	NSAttributedString* applicationDescriptor	= [[[NSMutableAttributedString alloc] initWithString: applicationDescr attributes: applicationDescriptorAttr] autorelease]; 
	
	// assemble compound string 
	[desktopDescriptor appendAttributedString: applicationDescriptor]; 
	
	return desktopDescriptor; 
}

- (NSAttributedString*) applicationDescription: (PNApplication*) application {
	NSMutableAttributedString* applicationDescriptor = [[[NSMutableAttributedString alloc] init] autorelease]; 
#if 0
		// application icon 
		NSTextAttachment*	attachment	= [[[NSTextAttachment alloc] init] autorelease]; 
		NSImage*			image		= [application icon]; 
		NSSize				imageSize	= NSMakeSize(24, 24); 
		
		[image setSize: imageSize]; 
		
		[[attachment attachmentCell] setImage: image]; 
		[applicationDescriptor appendAttributedString: [NSAttributedString attributedStringWithAttachment: attachment]];
#endif 
		
    // description 
    NSMutableAttributedString* description = [[[NSMutableAttributedString alloc] init] autorelease]; 
    [description appendAttributedString: [[[NSAttributedString alloc] initWithString: [NSString stringWithFormat: @"%@\n", [application name]]] autorelease]]; 
    
    NSNumber* windowCount		= [NSNumber numberWithInt: [[application windows] count]]; 
    NSString* windowCountString	= [windowCount intValue] == 0 ? @"no" : [windowCount stringValue]; 
    NSString* windowString		= [windowCount intValue] == 1 ? @"window" : @"windows"; 
    
    NSString* windowDescription	= [NSMutableString stringWithFormat: @"Showing %@ %@", windowCountString, windowString]; 
    
    // assemble attributed string describing windows open 
    NSDictionary* windowDescriptorAttr = [NSDictionary dictionaryWithObjectsAndKeys: 
      [NSFont labelFontOfSize: [NSFont labelFontSize]], NSFontAttributeName,
      [NSColor lightGrayColor], NSForegroundColorAttributeName, 
      nil]; 
    NSAttributedString* windowDescriptor = [[[NSMutableAttributedString alloc] initWithString: windowDescription attributes: windowDescriptorAttr] autorelease]; 
    
    [description appendAttributedString: windowDescriptor]; 
		
    // attach to final string 
    [applicationDescriptor appendAttributedString: description]; 
    
    return applicationDescriptor; 
}

- (NSAttributedString*) windowDescription: (PNWindow*) window {
	return [[[NSAttributedString alloc] initWithString: [window name]] autorelease]; 
}


@end 
