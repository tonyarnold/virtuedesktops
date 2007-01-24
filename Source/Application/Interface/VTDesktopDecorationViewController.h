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

@interface VTDesktopDecorationViewController : NSWindowController {
	// outlets 
	IBOutlet NSObjectController*	mDecorationController; 
	IBOutlet NSArrayController*		mDecorationsController; 
	IBOutlet NSBox*					mDecorationInspectorBox; 
	
	// ivars 
	VTDesktop*				mDesktop;		//!< The model we are dealing with 
	NSToolbar*				mToolbar;		//!< The window toolbar 
	NSMutableDictionary*	mToolbarItems;	//!< Items in the toolbar 
	NSMutableDictionary*	mPrimitiveClasses; 
	NSMutableDictionary*	mPrimitiveInspectors; 
	NSMutableArray*			mPluginIdentifiers; 
	
	NSView*					mCurrentInspectorView; 
	VTInspector*			mCurrentInspector; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) initWithDesktop: (VTDesktop*) desktop; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (VTDesktop*) desktop; 

@end
