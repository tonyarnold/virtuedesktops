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
*******************************************************************************/ 

#import "NSFileManagerAlias.h"

@implementation NSFileManager(ZNAlias) 


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
