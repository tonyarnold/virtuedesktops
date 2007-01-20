//
//  NSFileManager+Alias.m
//  Zen framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import "NSFileManager+Alias.h"

@implementation NSFileManager (ZenAlias) 

- (AliasHandle) makeAlias: (NSString*) path {
	FSRef		ref;
	NSURL*		url = [NSURL fileURLWithPath: path];
	AliasHandle alias;
	OSErr		err = noErr;
	
	if (CFURLGetFSRef((CFURLRef)url, &ref)) {
		err = FSNewAliasMinimal(&ref, &alias);
		if (noErr == err) {
			return alias;
		}
	}
	
	return nil; 
}

@end
