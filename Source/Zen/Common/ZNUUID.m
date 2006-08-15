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
