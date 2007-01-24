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
#import "VTDecorationPrimitive.h" 
#import "VTInspector.h" 
#import "VTPositionGrid.h" 

@interface VTDecorationPrimitiveViewController : NSWindowController {
// outlets 
	IBOutlet NSObjectController*	mPrimitiveController; 
	IBOutlet NSBox*					mInspectorContainer; 
	IBOutlet VTPositionGrid*		mPositionGrid; 
	IBOutlet NSButton*				mRelativePositionButton; 
	
// ivars 
	VTDecorationPrimitive*	mPrimitive; 
	VTInspector*			mInspector; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) init; 

#pragma mark -
#pragma mark Actions 
- (void) startSheetForPrimitive: (VTDecorationPrimitive*) primitive inspector: (VTInspector*) inspector window: (NSWindow*) window delegate: (id) delegate didEndSelector: (SEL) selector; 
- (IBAction) endSheet: (id) sender; 
- (IBAction) positionSelectionChanged: (id) sender; 


@end
