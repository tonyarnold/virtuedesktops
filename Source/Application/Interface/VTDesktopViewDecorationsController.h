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

#import <Cocoa/Cocoa.h>
#import "VTDesktop.h"
#import "VTInspector.h"
#import "VTDecorationPrimitive.h" 
#import "VTPositionGrid.h" 
#import <Zen/ZNImagePopUpButton.h> 

@interface VTDesktopViewDecorationsController : NSObject {
// controller outlets  
	IBOutlet NSObjectController*	mDecorationController; 
	IBOutlet NSArrayController*		mDecorationsController; 
	IBOutlet NSObjectController*	mPrimitiveController; 
	
// widgets 
	IBOutlet NSButton*				mInfoButton; 
	IBOutlet NSButton*				mDeleteButton;
	IBOutlet ZNImagePopUpButton*	mAddButton;
	IBOutlet NSMenu*				mAddMenu; 
	IBOutlet NSTableView*			mDecorationView; 
	IBOutlet NSPopUpButton*			mPositionTypeButton; 
	IBOutlet NSBox*					mDecorationBackground; 
// inspector drawer 
	IBOutlet NSDrawer*				mDrawer; 
	IBOutlet NSBox*					mInspectorContainer; 
	IBOutlet NSView*				mInspectorNonView; 
	IBOutlet NSView*				mPrimitiveView; 
	IBOutlet NSView*				mPrimitiveNoneView; 
	IBOutlet VTPositionGrid*		mPositionGrid; 
	
// ivars 
	VTDesktop*						mDesktop; 
	NSMutableDictionary*			mPrimitiveInspectors; 
	
	NSView*							mCurrentInspectorView; 
	VTInspector*					mCurrentInspector; 
	VTDecorationPrimitive*			mCurrentPrimitive; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) init; 

#pragma mark -
#pragma mark Attributes 
- (void) setDesktop: (VTDesktop*) desktop; 

#pragma mark -
#pragma mark Actions 
- (IBAction) showInspector: (id) sender; 
- (IBAction) deletePrimitive: (id) sender;
- (IBAction) orderUpPrimitive: (id) sender; 
- (IBAction) orderDownPrimitive: (id) sender;

@end
