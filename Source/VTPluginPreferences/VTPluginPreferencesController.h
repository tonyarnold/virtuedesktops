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
#import <PreferencePanes/NSPreferencePane.h> 

@interface VTPluginsArrayController : NSArrayController 
@end 


#pragma mark -
@interface VTPluginPreferencesController : NSPreferencePane {
	// outlets 
	IBOutlet NSArrayController* mPluginsController; 
}

@end
