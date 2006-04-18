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
