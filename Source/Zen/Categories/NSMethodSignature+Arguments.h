//
//  NSMethodSignatureArguments.m
//  Zen framework
//
//  Originally taken from the Colloquy project - http://colloquy.info
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import <Cocoa/Cocoa.h>


@interface NSMethodSignature(ZNArguments)
+ (id) methodSignatureWithReturnAndArgumentTypes: (const char*) retType, ...;
@end
