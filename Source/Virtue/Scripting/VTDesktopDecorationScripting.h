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
#import "VTDesktopDecoration.h"
#import "VTDecorationPrimitive.h"

@interface VTDesktopDecoration(VTCoreScripting)
- (NSNumber*) uniqueIdentifier; 
- (NSScriptObjectSpecifier*) objectSpecifier; 
- (VTDecorationPrimitive*) valueInDecorationPrimitivesWithName: (NSString*) name; 
@end
