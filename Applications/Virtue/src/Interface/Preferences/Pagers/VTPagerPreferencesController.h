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


@interface VTPagerPreferencesController : NSPreferencePane {
// outlets 
	IBOutlet NSView*		mAppearanceView;			// built-in pager view
	IBOutlet NSView*		mBehaviourView;				// built-in pager view
	
	IBOutlet NSTabViewItem*	mAppearanceTabItem;
	IBOutlet NSTabViewItem* mBehaviourTabItem; 
	
	IBOutlet NSPopUpButton*	mAvailablePagerButton; 
}

#pragma mark -
#pragma mark Color Helpers 


@end
