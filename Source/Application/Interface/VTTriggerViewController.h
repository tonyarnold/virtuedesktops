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

#import <Cocoa/Cocoa.h>
#import <Virtue/VTTrigger.h> 
#import <Virtue/VTTriggerNotification.h> 
#import "VTPositionGrid.h" 

@interface VTTriggerViewController : NSWindowController {
// outlets 
	IBOutlet NSWindow*			mAvailableTriggersPanel; 
	IBOutlet NSOutlineView*		mAvailableTriggersView; 
	IBOutlet NSButton*			mSelectAndCloseButton; 
	IBOutlet NSDrawer*			mInspectorDrawer; 
	IBOutlet NSView*			mMouseInspectorView; 
	IBOutlet NSView*			mHotkeyInspectorView; 
	IBOutlet VTPositionGrid*	mPositionGrid; 
	
// ivars 
	NSWindow*				mModalWindow; 
	id						mOwner; 
	
	VTTrigger*				mTrigger; 
	VTTriggerNotification*	mNotification; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) initForWindow: (NSWindow*) window owner: (id) owner; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (void) setTrigger: (VTTrigger*) trigger; 
- (VTTriggerNotification*) selectedNotification; 

#pragma mark -
#pragma mark Actions 
- (void) beginActionSelectionWithDidEndSelector: (SEL) didEndSelector; 

#pragma mark -
- (void) showTriggerInspector; 
- (void) hideTriggerInspector; 
- (void) toggleTriggerInspector; 

#pragma mark -
- (IBAction) selectAndEndSheet: (id) sender; 
- (IBAction) cancelAndEndSheet: (id) sender; 

@end
