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
#import "VTDecorationPrimitiveViewController.h" 
#import <Virtue/VTDesktop.h>
#import "VTImageViewFileDropper.h" 
#import "VTHotkeyTextField.h" 
#import "VTHotkeyTextView.h" 
#import "VTHotkeyCell.h"
#import "VTColorLabelButton.h" 
#import <Zen/ZNImagePopUpButton.h> 
#import "VTMatrixDesktopLayout.h"

@interface VTDesktopViewController : NSWindowController {
	// Outlets
	IBOutlet NSArrayController*				mDesktopsController; 
	IBOutlet NSObjectController*			mDesktopController; 
	IBOutlet NSArrayController*				mDecorationsController; 
	IBOutlet VTImageViewFileDropper*	mImageView; 
	IBOutlet VTColorLabelButton*			mLabelButton;
	IBOutlet NSTableView*							mDesktopsTableView; 
	IBOutlet NSTableView*							mDecorationsTableView; 
	IBOutlet NSButton*								mInspectPrimitiveButton; 
	IBOutlet NSButton*								mDeletePrimitiveButton; 
	IBOutlet NSButton*								mAddDesktopButton;
	IBOutlet NSButton*								mDeleteDesktopButton; 
	IBOutlet ZNImagePopUpButton*			mAddPrimitiveButton; 
	IBOutlet NSMenu*									mAddPrimitiveMenu;
	
	// Instance variables 
	VTDesktop*														mDesktop;			//!< The model we are dealing with 
	VTMatrixDesktopLayout*								mActiveDesktopLayout;
	VTDecorationPrimitiveViewController*	mInspectorController; 
	NSMutableDictionary*									mPrimitiveInspectors;
	NSMutableDictionary*									mPrimitiveNames; 
	NSMutableArray*												desktops;
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
