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

#import "NSBundlePlugin.h"

#define VTPluginInfoDictionaryKey	@"VTPlugin"

@implementation NSBundle(VTPlugin) 

- (NSDictionary*) pluginInfoDictionary {
	return [self objectForInfoDictionaryKey: VTPluginInfoDictionaryKey]; 
}

@end
