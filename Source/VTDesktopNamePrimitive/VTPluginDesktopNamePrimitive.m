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

#import "VTPluginDesktopNamePrimitive.h"
#import "VTPrimitiveDesktopNameInspector.h"
#import "VTDesktopNamePrimitive.h" 

@implementation VTPluginDesktopNamePrimitive

#pragma mark -
#pragma mark VTPluginDecoration 

- (Class) decorationPrimitiveClass {
	return [VTDesktopNamePrimitive class];  
}

- (VTInspector*) decorationPrimitiveInspector {
	return [[[VTPrimitiveDesktopNameInspector alloc] init] autorelease]; 
}

@end
