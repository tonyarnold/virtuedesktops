/******************************************************************************
* 
* VirtueDesktops 
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
#import <Virtue/VTDesktop.h>
#import <Zen/ZNImagePopUpButton.h>
#import "VTDecorationPrimitiveViewController.h" 
#import "VTImageViewFileDropper.h" 
#import "VTHotkeyTextField.h" 
#import "VTHotkeyTextView.h" 
#import "VTHotkeyCell.h"
#import "VTColorLabelButton.h" 
#import "VTMatrixDesktopLayout.h"

@interface VTDesktopViewController : NSWindowController {
	// Outlets
	IBOutlet NSArrayController*       mDesktopsController; 
	IBOutlet NSObjectController*      mDesktopController; 
	IBOutlet NSArrayController*       mDecorationsController; 
	IBOutlet VTColorLabelButton*      mLabelButton;
	IBOutlet NSTableView*             mDecorationsTableView; 
	IBOutlet NSButton*                mInspectPrimitiveButton; 
	IBOutlet NSMenu*                  mAddPrimitiveMenu;
	
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

#pragma mark -
#pragma mark Accessors
- (VTMatrixDesktopLayout*) activeDesktopLayout;

@end
