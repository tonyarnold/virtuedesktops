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

#import "VTApplicationDelegateScripting.h"


@implementation VTApplicationDelegate(VTScripting)

- (BOOL) application: (NSApplication*) sender delegateHandlesKey: (NSString*) key {
	if ([key isEqualToString: @"desktopController"] || [key isEqualToString: @"desktopDecorationController"])
		return YES;
	
	return NO;
}

@end
