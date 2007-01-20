//
//  NSFileManager+Alias.h
//  Zen framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

/*!
    @header     NSFileManager+Alias
    @abstract   Defines an NSFileManager category to add creation of alias handles
    @discussion The category contained in this header extends the default file manager to support the creation of alias handles via a simple, cocoa-like method.
*/

#import <Cocoa/Cocoa.h>
/*!
    @category     NSFileManager (ZenAlias)
    @abstract     Extends the default file manager to support creation of alias handles
    @discussion   This category extends the default file manager to support the creation of alias handles via a simple, cocoa-like method.
*/
@interface NSFileManager (ZenAlias)
/*!
    @method     makeAlias:
    @abstract   Create a new alias handle using a specified path
    @discussion Creates a new alias handle using the specified file system path.
    @param      path  The path to create the alias handle from
    @result     An AliasHandle for the specified path
*/
- (AliasHandle) makeAlias: (NSString*) path; 
@end