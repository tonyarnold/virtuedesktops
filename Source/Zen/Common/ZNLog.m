//
//  ZNLog.m
//  Zen framework
//  
//  Originally designed by Scott Morrison - http://www.indev.ca/
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import "ZNLog.h"

@implementation ZNLog

+ (void)file:(char*)sourceFile function:(char*)functionName lineNumber:(int)lineNumber format:(NSString*)format, ...
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  va_list ap;
  NSString *print, *file, *function;
  va_start(ap,format);
  file = [[NSString alloc] initWithBytes: sourceFile length: strlen(sourceFile) encoding: NSUTF8StringEncoding];
  
  function = [NSString stringWithCString: functionName];
  print = [[NSString alloc] initWithFormat: format arguments: ap];
  va_end(ap);
  NSLog(@"%@:%d %@; %@", [file lastPathComponent], lineNumber, function, print);
  [print release];
  [file release];
  [pool release];    
}

@end
