//
//  NSStringWithModifiers.h
//  Zen framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import <Cocoa/Cocoa.h>

@interface NSString(ZNKeyModifiers)
+ (NSString*) stringWithModifiers: (int) keyModifiers; 
@end
