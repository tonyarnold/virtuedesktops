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
#import "VTDesktopDecoration.h"
#import "VTDecorationPrimitive.h"

@interface VTDesktopDecoration(VTScripting)
- (NSNumber*) uniqueIdentifier; 
- (NSScriptObjectSpecifier*) objectSpecifier; 
- (VTDecorationPrimitive*) valueInDecorationPrimitivesWithName: (NSString*) name; 
@end
