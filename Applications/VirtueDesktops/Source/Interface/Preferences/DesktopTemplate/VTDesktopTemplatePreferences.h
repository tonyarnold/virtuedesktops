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
#import <PreferencePanes/NSPreferencePane.h> 

#import "VTDecorationPrimitiveViewController.h" 
#import <Zen/ZNImagePopUpButton.h> 

@interface VTDesktopTemplatePreferences : NSPreferencePane {
// outlets 
	IBOutlet NSArrayController*			mDecorationsController; 

	IBOutlet NSTableView*						mDecorationsTableView; 
	IBOutlet NSButton*							mInspectPrimitiveButton; 
	IBOutlet NSButton*							mDeletePrimitiveButton; 
	IBOutlet ZNImagePopUpButton*		mAddPrimitiveButton; 
	IBOutlet NSMenu*								mAddPrimitiveMenu; 

// ivars
	VTDecorationPrimitiveViewController*	mInspectorController; 
	NSMutableDictionary*									mPrimitiveInspectors; 	
}

#pragma mark -
#pragma mark Actions 
- (IBAction) inspectPrimitive: (id) sender; 
- (IBAction) deletePrimitive: (id) sender; 

- (IBAction) applyPrototype: (id) sender; 
- (IBAction) replacePrototype: (id) sender; 
@end
