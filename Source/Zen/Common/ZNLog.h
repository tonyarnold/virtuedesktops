//
//  ZNLog.h
//  Zen framework
//  
//  Originally designed by Scott Morrison - http://www.indev.ca/
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import <Cocoa/Cocoa.h>

@interface ZNLog : NSObject {}

+(void)file:(char*)sourceFile function:(char*)functionName lineNumber:(int)lineNumber format:(NSString*)format, ...;

#ifdef ZNDEBUG
#define ZNLog(s,...) [ZNLog file:__FILE__ function: (char *)__FUNCTION__ lineNumber:__LINE__ format:(s),##__VA_ARGS__]
#else
#define ZNLog(s,...) 
#endif

@end
