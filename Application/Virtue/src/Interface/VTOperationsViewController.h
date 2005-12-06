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
#import <Peony/Peony.h> 
#import <Virtue/VTDesktopController.h>
#import <Virtue/VTApplicationWrapper.h> 

@interface VTOperationsViewController : NSWindowController {
	// Outlets 
	IBOutlet NSObjectController*	mController; 
	IBOutlet NSPopUpButton*			mApplicationDesktopButton; 
	IBOutlet NSPopUpButton*			mWindowDesktopButton; 	

	// Objects 
	NSWindow*							mOverlayWindow;						//!< Window used to tint our target
	PNWindow*							mRepresentedWindow;				//!< Our target 
	VTApplicationWrapper*	mRepresentedWrapper;			//!< The application wrapper 
	PNApplication*				mRepresentedApplication;	//!< The application 
}

#pragma mark -
#pragma mark Lifetime 
- (id) init;
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (PNWindow*) representedWindow; 
- (PNApplication*) representedApplication; 
- (VTApplicationWrapper*) representedWrapper; 
- (VTDesktopController*) desktopController; 

#pragma mark -
#pragma mark Actions 
- (IBAction) hideSheet: (id) sender; 

#pragma mark -
- (IBAction) setDesktopForWindow: (id) sender; 
- (IBAction) setDesktopForApplication: (id) sender; 

#pragma mark -
#pragma mark Operations 
- (void) display;

@end
