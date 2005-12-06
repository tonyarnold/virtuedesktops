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

#import "VTPluginPreferencesController.h"
#import <Virtue/VTPluginCollection.h> 

@implementation VTPluginsArrayController 

- (NSArray*) arrangeObjects: (NSArray*) objects {
	// we filter those objects to only include plugins that want to be shown 
	NSEnumerator*			objectIter		= [objects objectEnumerator]; 
	VTPluginInstance*		object			= nil; 
	NSMutableArray*			filteredObjects	= [[NSMutableArray alloc] init]; 
	
	while (object = [objectIter nextObject]) {
		if ([object pluginIsHidden]) 
			continue; 
		
		[filteredObjects addObject: object]; 
	}
	
	return [filteredObjects autorelease]; 
}

@end 

#pragma mark -
@implementation VTPluginPreferencesController

- (void) mainViewDidLoad {
	[mPluginsController setContent: [[VTPluginCollection sharedInstance] plugins]]; 
}

#pragma mark -
#pragma mark NSTableView delegate 

- (void) tableViewSelectionDidChange: (NSNotification*) aNotification {
}

@end

#pragma mark -
#pragma mark VTPluginInstance
@interface VTPluginInstance (VTPreferencesDisplay) 
- (NSData*) pluginDescriptionHelper; 
@end

@implementation VTPluginInstance (VTPreferencesDisplay) 

- (NSData*) pluginDescriptionHelper {
	if ([self pluginDescriptionPath] != nil) {
		NSDictionary*				attr; 
		NSURL*						path = [NSURL fileURLWithPath: [mBundle pathForResource: [self pluginDescriptionPath] ofType: @"rtfd"]]; 
		NSMutableAttributedString*	text = [[[NSMutableAttributedString alloc] init] autorelease];
		[text readFromURL: path options: nil documentAttributes: &attr]; 
		NSData*				data = [text RTFDFromRange: NSMakeRange(0, [text length]) documentAttributes: attr]; 
		
		return data; 
	}
	
	return [NSData dataWithData:[[self pluginDescription] dataUsingEncoding:NSISOLatin1StringEncoding]];
}

@end 