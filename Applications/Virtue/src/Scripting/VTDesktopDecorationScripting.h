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

#import <Cocoa/Cocoa.h>
#import <Virtue/VTDesktopDecoration.h>
#import <Virtue/VTDecorationPrimitive.h>

@interface VTDesktopDecoration(VTScripting)
- (NSNumber*) uniqueIdentifier; 
- (NSScriptObjectSpecifier*) objectSpecifier; 
- (VTDecorationPrimitive*) valueInDecorationPrimitivesWithName: (NSString*) name; 
@end
