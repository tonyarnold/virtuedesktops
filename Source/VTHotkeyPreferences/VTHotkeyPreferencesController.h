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

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h> 
#import "VTTriggerNotification.h"
#import "VTPositionGrid.h"
#import "VTHotkeyTextField.h"
#import "VTHotkeyTextView.h"
#import "VTHotkeyCell.h"
#import "VTAssignedTriggerArrayController.h"

#pragma mark -
@interface VTHotkeyPreferencesController : NSPreferencePane {
	// outlets 
	IBOutlet NSArrayController*		mAssignedTriggerController; 
	IBOutlet NSPanel*				mAvailableTriggersPanel; 
	IBOutlet NSMenuItem*			mMouseTriggerItem; 
	IBOutlet NSMenuItem*			mKeyTriggerItem; 
	IBOutlet NSPopUpButtonCell*		mTriggerPopupCell; 
	IBOutlet NSOutlineView*			mAvailableTriggersView; 
	IBOutlet NSButton*				mSelectAndCloseButton; 
	IBOutlet NSDrawer*				mInspectorDrawer; 
	IBOutlet NSView*				mMouseInspectorView; 
	IBOutlet NSView*				mHotkeyInspectorView; 
	IBOutlet VTPositionGrid*		mPositionGrid; 
	IBOutlet NSTableView*			mTriggerTableView; 
	
	IBOutlet NSButton*				mControlButton; 
	IBOutlet NSButton*				mAlternateButton; 
	IBOutlet NSButton*				mCommandButton; 
	IBOutlet NSButton*				mShiftButton; 
	
	// Instance variables 
	VTTriggerNotification*	mSelectedNotification; 
	VTHotkeyTextView*       mFieldEditor;					//!< Used to edit keyboard triggers 
	id                      mOriginalDelegate; 
}

#pragma mark -
#pragma mark Actions 
- (IBAction) showAvailableTriggers: (id) sender; 
#pragma mark -
- (IBAction) selectAndEndSheet: (id) sender; 
- (IBAction) cancelAndEndSheet: (id) sender; 
#pragma mark -
- (IBAction) removeTrigger: (id) sender; 
#pragma mark -
- (IBAction) toggleClickCount: (id) sender; 
- (IBAction) toggleModifier: (id) sender; 
- (IBAction) toggleTriggerType: (id) sender;  
@end