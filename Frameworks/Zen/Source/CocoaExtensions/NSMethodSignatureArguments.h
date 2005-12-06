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
*****************************************************************************
*
* Copyright, Colloquy Project 
* http://www.colloquy.info
*
*****************************************************************************/ 

#import <Cocoa/Cocoa.h>


@interface NSMethodSignature(ZNArguments)
+ (id) methodSignatureWithReturnAndArgumentTypes: (const char*) retType, ...;
@end
