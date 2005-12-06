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
#import <Virtue/VTHotkeyGroup.h> 
#import "VTHotkeyTextView.h" 


@interface VTBehaviourPreferencesController : NSPreferencePane {
// outlets 
	IBOutlet NSOutlineView*		mHotkeyOutline; 
// ivars 
	VTHotkeyTextView*	mFieldEditor; 
	VTHotkeyGroup*		mNavigationGroup; 
}

@end
