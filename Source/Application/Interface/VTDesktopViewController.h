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

#import <Cocoa/Cocoa.h>
#import "VTDesktop.h"
#import <Zen/Zen.h>
#import "VTDecorationPrimitiveViewController.h" 
#import "VTImageViewFileDropper.h" 
#import "VTHotkeyTextField.h" 
#import "VTHotkeyTextView.h" 
#import "VTHotkeyCell.h"
#import "VTMatrixDesktopLayout.h"
#import <TAUserInterfaceElements/TAUIColorLabelButton.h>

@interface VTDesktopViewController : NSWindowController {
	// Outlets
  IBOutlet NSTableView*             mDesktopsTableView;
	IBOutlet NSArrayController*       mDesktopsController; 
	IBOutlet NSArrayController*       mDecorationsController; 
	IBOutlet NSTableView*             mDecorationsTableView; 
	IBOutlet NSButton*                mInspectPrimitiveButton; 
	IBOutlet NSMenu*                  mAddPrimitiveMenu;
  IBOutlet TAUIColorLabelButton*    mColorLabelButton;
	IBOutlet VTImageViewFileDropper*  mImageView;
  
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
