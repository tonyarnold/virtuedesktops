/******************************************************************************
* 
* Zen 
*
* A foundations framework 
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2006, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
******************************************************************************/ 

#import <Cocoa/Cocoa.h>


@interface NSFileManager(ZNAlias)

- (AliasHandle) makeAlias: (NSString*) path; 

@end
