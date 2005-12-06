/******************************************************************************
* 
* Zen 
*
* A foundations framework 
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
******************************************************************************/ 

#import <Cocoa/Cocoa.h>


@interface NSFileManager(ZNAlias)

- (AliasHandle) makeAlias: (NSString*) path; 

@end
