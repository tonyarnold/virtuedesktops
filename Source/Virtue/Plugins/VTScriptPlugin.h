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
#import "VTPluginScript.h"

@interface VTScriptPlugin : NSObject<VTPluginScript> {
	NSAppleScript*		mScript;
	NSMutableArray*		mIgnoredSelectors;
}

@end
