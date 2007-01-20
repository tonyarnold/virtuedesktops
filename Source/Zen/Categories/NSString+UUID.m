//
//  NSString+UUID.m
//  Zen framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import "NSString+UUID.h"


@implementation NSString (UUID)
+ (NSString*)stringWithUUID
{
  CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
  NSString* str = (NSString*)CFUUIDCreateString(kCFAllocatorDefault, uuid);
  CFRelease(uuid);
  return [str autorelease];
}
@end
