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
#import <PreferencePanes/NSPreferencePane.h> 
#import <Virtue/VTDesktopLayout.h> 

@interface VTLayoutPreferencesController : NSPreferencePane {
// outlets 
	IBOutlet NSBox*					mLayoutContainer; 
	IBOutlet NSPopUpButton*	mLayoutList; 
	IBOutlet NSView*				mMatrixLayoutView; 
	IBOutlet NSView*				mFixedMatrixLayoutView;
}

#pragma mark -
#pragma mark Accessors 
- (VTDesktopLayout*) activeLayout;

@end
