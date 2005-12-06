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


@interface VTApplicationPreferencesController : NSPreferencePane {
	IBOutlet NSButton*		mControlButton; 
	IBOutlet NSButton*		mAlternateButton; 
	IBOutlet NSButton*		mCommandButton; 
	IBOutlet NSButton*		mShiftButton; 
}

#pragma mark -
#pragma mark Actions 
- (IBAction) toggleModifier: (id) sender;

#pragma mark -
#pragma mark Attributes 
- (BOOL) isLoginItem; 
- (void) setLoginItem: (BOOL) flag; 

@end
