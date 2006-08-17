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

#import "NSUserDefaultsControllerKeyFactory.h"


@implementation NSUserDefaultsController(VTKeyFactory)

+ (NSString*) pathForKey: (NSString*) key {
	return [NSString stringWithFormat: @"values.%@", key]; 
}

@end
