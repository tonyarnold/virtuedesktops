//
//  NSNumber+Bytes.h
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
    @header     NSNumber+Bytes.h
    @abstract   Defines an NSSNumber category that gets an NSNumber directly from bytes
    @discussion This header defines an NSSNumber category that gets an NSNumber directly from bytes.
*/

#import <Cocoa/Cocoa.h>
/*!
    @category   NSNumber (ZenBytes)
    @abstract   Gets an NSNumber from bytes
    @discussion Returns an NSNumber directly from bytes
*/

@interface NSNumber (ZenBytes)

/*!
    @method     numberWithBytes: objCType:
    @abstract   Gets an NSNumber directly from bytes
    @discussion This method gets an NSNumber directly from bytes.
*/
+ (NSNumber*) numberWithBytes: (const void*) bytes objCType: (const char*) type; 

@end
