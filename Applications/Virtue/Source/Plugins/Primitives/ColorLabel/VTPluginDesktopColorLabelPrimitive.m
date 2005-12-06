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

#import "VTPluginDesktopColorLabelPrimitive.h"
#import "VTPrimitiveDesktopColorLabelInspector.h"
#import "VTDesktopColorLabelPrimitive.h" 

@implementation VTPluginDesktopColorLabelPrimitive

#pragma mark -
#pragma mark Type information

- (Class) decorationPrimitiveClass {
	return [VTDesktopColorLabelPrimitive class];  
}

- (VTInspector*) decorationPrimitiveInspector {
	return [[[VTPrimitiveDesktopColorLabelInspector alloc] init] autorelease]; 
}

@end
