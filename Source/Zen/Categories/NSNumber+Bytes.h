//
//  NSNumberBytes.h
//  Zen framework
//  
//  Originally taken from the Colloquy project - http://colloquy.info
//  
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  
/*!
    @header     NSNumber (ZenBytes)
    @abstract   Gets an NSNumber from bytes
    @discussion Returns an NSNumber directly from bytes
*/

#import <Cocoa/Cocoa.h>
/*!
    @category    NSNumber
    @abstract    (brief description)
    @discussion  (comprehensive description)
*/

@interface NSNumber(ZenBytes)

+ (NSNumber*) numberWithBytes: (const void*) bytes objCType: (const char*) type; 

@end
