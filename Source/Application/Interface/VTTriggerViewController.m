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

#import "VTTriggerViewController.h"
#import <Zen/Zen.h> 

@implementation VTTriggerViewController

#pragma mark -
#pragma mark Lifetime 
- (id) initForWindow: (NSWindow*) window owner: (id) owner {
	if (self = [super initWithWindowNibName: @"VTTriggerInspector"]) {
		mTrigger		= nil; 
		mNotification	= nil; 
		
		ZEN_ASSIGN(mModalWindow, window); 
		mOwner = owner; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mTrigger); 
	ZEN_RELEASE(mNotification); 
	ZEN_RELEASE(mModalWindow); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 
- (void) setTrigger: (VTTrigger*) trigger {
	ZEN_ASSIGN(mTrigger, trigger); 
}

- (VTTriggerNotification*) selectedNotification {
	return mNotification; 
}

#pragma mark -
#pragma mark Actions 
- (void) beginActionSelectionWithDidEndSelector: (SEL) didEndSelector {
	// reset notification
	ZEN_RELEASE(mNotification); 
	
	// begin sheet 
	[[NSApplication sharedApplication] beginSheet: mAvailableTriggersPanel
								   modalForWindow: mModalWindow
									modalDelegate: self
								   didEndSelector: didEndSelector
									  contextInfo: NULL];
}


#pragma mark -
- (void) showTriggerInspector {
	[mInspectorDrawer open]; 
}

- (void) hideTriggerInspector {
	[mInspectorDrawer close]; 
}

- (void) toggleTriggerInspector {
	[mInspectorDrawer toggle: self]; 
}

#pragma mark -
- (IBAction) selectAndEndSheet: (id) sender {
	// fetch the selection
	mNotification = [[mAvailableTriggersView itemAtRow: [mAvailableTriggersView selectedRow]] retain]; 
	
	[mAvailableTriggersPanel close]; 
	[[NSApplication sharedApplication] endSheet: mAvailableTriggersPanel returnCode: NSOKButton]; 
}

- (IBAction) cancelAndEndSheet: (id) sender {
	// end sheet 
	[mAvailableTriggersPanel close]; 
	[[NSApplication sharedApplication] endSheet: mAvailableTriggersPanel returnCode: NSCancelButton]; 	
}


#pragma mark -
#pragma mark NSObject delegate 
- (void) windowDidLoad {
	// prepare position grid 
	[mPositionGrid setMarkers: [NSArray arrayWithObjects: 
		[NSNumber numberWithInt: VTPositionMarkerLeft], 
		[NSNumber numberWithInt: VTPositionMarkerRight], 
		[NSNumber numberWithInt: VTPositionMarkerTop], 
		[NSNumber numberWithInt: VTPositionMarkerBottom],
		nil]]; 
	[mPositionGrid setTarget: self]; 
	[mPositionGrid setAction: @selector(onPositionSelected:)]; 
	
	// prepare outline view 
	[mAvailableTriggersView setTarget: self]; 
	[mAvailableTriggersView setDoubleAction: @selector(onTriggerActionDouble:)]; 	
}

@end
