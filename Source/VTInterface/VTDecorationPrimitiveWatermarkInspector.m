/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2007, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTDecorationPrimitiveWatermarkInspector.h"
#import "VTDecorationPrimitiveWatermark.h"
#import <Zen/Zen.h> 

@implementation VTDecorationPrimitiveWatermarkInspector

#pragma mark -
#pragma mark Lifetime 
- (id) init {
	if (self = [super init]) {
		[NSBundle loadNibNamed: @"PrimitiveWatermarkInspector" owner: self]; 
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

#pragma mark -
#pragma mark Actions 
- (IBAction) browseForWatermark: (id) sender {
	NSOpenPanel* openPanel = [NSOpenPanel openPanel]; 
	
	// and configure 
	[openPanel setCanChooseDirectories: NO]; 
	[openPanel setAllowsMultipleSelection: NO]; 
	
	// display modal 
	if ([openPanel runModalForDirectory: nil file: nil types: nil] == NSCancelButton) 
		return; 
	
	// here we fetch the selected file from the panel and set it in our
	// primitive 
	NSString* filePath = [[openPanel filenames] objectAtIndex: 0]; 
	if (filePath == nil) 
		return; 
	
	// set it already 
	[(VTDecorationPrimitiveWatermark*)[self inspectedObject] setImagePath: filePath]; 
}

@end
