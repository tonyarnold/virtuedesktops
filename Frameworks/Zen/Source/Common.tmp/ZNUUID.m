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
*****************************************************************************/ 

#import "ZNUUID.h"

@implementation ZNUUID

+ (NSString*) uuid {
	CFUUIDRef	uidRef; 
	NSString*	uidString; 

	uidRef		= CFUUIDCreate(NULL); 
	uidString	= (NSString *)CFUUIDCreateString(NULL, uidRef); 
	CFRelease(uidRef); 
	
	return [uidString autorelease]; 
}

@end
