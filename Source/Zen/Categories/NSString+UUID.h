//
//  NSString+UUID.h
//  Zen framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//

/*!
 @header     NSString+UUID
 @abstract   Defines an NSString category to generate unique identifiers
 @discussion The category contained in this header extends the default string object to support the generation of unique identifier strings.
 */

#import <Cocoa/Cocoa.h>
/*!
 @category     NSString (UUID)
 @abstract     Extends the default string object to support generation of unique identifiers
 @discussion   This category extends the default string object to support the generation of unique identifier strings.
 */
@interface NSString (UUID)
/*!
 @method     stringWithUUID
 @abstract   Generate a unique identifier
 @discussion Generates a unique identifier string.
 @result     A unique identifier string
 */
+ (NSString*)stringWithUUID;
@end
