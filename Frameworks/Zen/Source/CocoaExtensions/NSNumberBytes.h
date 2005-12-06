/******************************************************************************
* 
* Zen 
*
* A foundations framework 
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************
*
* Copyright, Colloquy Project 
* http://www.colloquy.info
*
*****************************************************************************/ 

#import <Cocoa/Cocoa.h>

@interface NSNumber(VTBytes)

+ (NSNumber*) numberWithBytes: (const void*) bytes objCType: (const char*) type; 

@end
