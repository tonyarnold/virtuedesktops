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

#include <Cocoa/Cocoa.h>

@protocol VTCoding 

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary; 
- (id) decodeFromDictionary: (NSDictionary*) dictionary; 

@end 

