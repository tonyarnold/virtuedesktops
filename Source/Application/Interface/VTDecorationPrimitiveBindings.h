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
#import "VTDecorationPrimitive.h"

@interface VTDecorationPrimitive(VTBindings)

#pragma mark -
#pragma mark Attributes 
- (int) positionTypeTag; 
- (void) setPositionTypeTag: (int) tag; 

#pragma mark -
- (BOOL) isAbsolutePosition; 
- (void) setAbsolutePosition: (BOOL) flag;
- (BOOL) isRelativePosition; 
- (void) setRelativePosition: (BOOL) flag; 

#pragma mark -
- (BOOL) supportsAbsolutePosition; 
- (BOOL) supportsRelativePosition; 

#pragma mark -
- (int) positionX; 
- (void) setPositionX: (int) x; 

#pragma mark -
- (int) positionY; 
- (void) setPositionY: (int) y; 

@end
