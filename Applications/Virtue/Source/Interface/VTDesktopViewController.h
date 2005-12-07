/******************************************************************************
* 
* Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import <Cocoa/Cocoa.h>
#import "VTDecorationPrimitiveViewController.h" 
#import <Virtue/VTDesktop.h>
#import "VTImageViewFileDropper.h" 
#import "VTHotkeyTextField.h" 
#import "VTHotkeyTextView.h" 
#import "VTHotkeyCell.h"
#import "VTColorLabelButton.h" 
#import <Zen/ZNImagePopUpButton.h> 

@interface VTDesktopViewController : NSWindowController {
	// outlets 
	IBOutlet NSArrayController*				mDesktopsController; 
	IBOutlet NSObjectController*			mDesktopController; 
	IBOutlet NSArrayController*				mDecorationsController; 
	
	IBOutlet VTHotkeyTextField*				mHotkeyField; 
	IBOutlet VTImageViewFileDropper*	mImageView; 

	IBOutlet VTColorLabelButton*			mLabelButton;
	IBOutlet NSTableView*							mDesktopsTableView; 
	IBOutlet NSTableView*							mDecorationsTableView; 
	
	IBOutlet NSButton*								mInspectPrimitiveButton; 
	IBOutlet NSButton*								mDeletePrimitiveButton; 
	IBOutlet NSButton*								mDeleteDesktopButton; 
	IBOutlet ZNImagePopUpButton*			mAddPrimitiveButton; 
	IBOutlet NSMenu*									mAddPrimitiveMenu; 
	IBOutlet NSPopUpButton*						mTriggerTypePopup; 
	IBOutlet NSMenuItem*							mKeyTriggerItem; 
	IBOutlet NSMenuItem*							mMouseTriggerItem; 
	
// ivars 
	VTDesktop*					mDesktop;		//!< The model we are dealing with 
	VTHotkeyTextView*		mFieldEditor;	//!< Used to edit the hotkey 

	VTDecorationPrimitiveViewController*	mInspectorController; 
	NSMutableDictionary*									mPrimitiveInspectors;
	NSMutableDictionary*									mPrimitiveNames; 
}

#pragma mark -
#pragma mark Attributes 
- (VTDesktop*) desktop; 

#pragma mark -
#pragma mark Actions 
- (IBAction) inspectPrimitive: (id) sender; 

- (IBAction) addDesktop: (id) sender; 
- (IBAction) deleteDesktop: (id) sender; 
- (IBAction) deletePrimitive: (id) sender; 

- (void) showWindowForDesktop: (VTDesktop*) desktop; 

@end
