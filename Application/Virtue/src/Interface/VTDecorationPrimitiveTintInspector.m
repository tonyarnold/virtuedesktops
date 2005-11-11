/******************************************************************************
* 
* Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTDecorationPrimitiveTintInspector.h"
#import <Virtue/VTDecorationPrimitiveTint.h>
#import <Zen/Zen.h> 

@implementation VTDecorationPrimitiveTintInspector

- (id) init {
	if (self = [super init]) {
		[NSBundle loadNibNamed: @"PrimitiveTintInspector" owner: self]; 
		// and assign main view 
		mMainView = [[mWindow contentView] retain]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mMainView); 
	
	[super dealloc]; 
}

@end
