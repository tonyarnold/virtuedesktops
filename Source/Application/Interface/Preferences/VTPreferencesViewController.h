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
#import <PreferencePanes/NSPreferencePane.h>

@interface VTPreferencesViewController : NSWindowController {
// outlets 
	IBOutlet NSArrayController*	mPreferencePanesController; 
	IBOutlet NSBox*							mPreferencePaneContainer; 
	IBOutlet NSView*						mPreferencePaneLoading;
	IBOutlet NSTableView*				mPreferencePanesTable; 
// ivars
	NSMutableArray*				mAvailablePreferencePanes;	//!< Array of dictionaries describing a preference pane 

	NSMutableDictionary*	mToolbarItems;		//!< Available toolbar items 
	NSMutableDictionary*	mPreferencePanes;	//!< Available panes 
	NSPreferencePane*			mCurrentPane;		//!< Currently displayed pane 
}

#pragma mark -
#pragma mark Color Helpers 

#if 0
- (void) setPagerBackgroundColor: (NSColor*) color; 
- (NSColor*) pagerBackgroundColor; 
- (void) setPagerBackgroundHighlightColor: (NSColor*) color; 
- (NSColor*) pagerBackgroundHighlightColor; 
- (void) setPagerTextColor: (NSColor*) color; 
- (NSColor*) pagerTextColor; 
- (void) setPagerWindowColor: (NSColor*) color; 
- (NSColor*) pagerWindowColor; 
- (void) setPagerWindowHighlightColor: (NSColor*) color; 
- (NSColor*) pagerWindowHighlightColor; 
- (void) setOperationsTintColor: (NSColor*) color; 
- (NSColor*) operationsTintColor; 
#endif 
@end
