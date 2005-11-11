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

@interface VTPluginsArrayController : NSArrayController 
@end 


#pragma mark -
@interface VTPluginPreferencesController : NSPreferencePane {
	// outlets 
	IBOutlet NSArrayController* mPluginsController; 
}

@end
