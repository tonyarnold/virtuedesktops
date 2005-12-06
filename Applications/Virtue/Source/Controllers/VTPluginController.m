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

#import "VTPluginController.h"
#import <Virtue/VTPluginInstance.h>
#import <Virtue/VTPluginCollection.h> 
#import <Zen/Zen.h> 
#import <Zen/NSNumberBytes.h> 

@interface VTPluginController (PluginLoading)
- (NSArray*) pluginSearchPaths; 
- (void) ensurePluginSearchPaths; 

- (void) loadPlugin: (NSString*) path; 
@end 

#pragma mark -
@implementation VTPluginController

#pragma mark -
#pragma mark Instance 

- (id) init {
	if (self = [super init]) {
		[self ensurePluginSearchPaths]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	[super dealloc]; 
}

#pragma mark -
#pragma mark operations 
- (void) loadPlugins {
	NSArray*		searchPaths			= [self pluginSearchPaths]; 
	NSEnumerator*	searchPathIter		= [searchPaths objectEnumerator]; 
	NSString*		searchPath			= nil; 
	NSEnumerator*	bundlePathIter		= nil;
	NSString*		currentBundlePath	= nil;
	
	while (searchPath = [searchPathIter nextObject]) {
		bundlePathIter = [[[NSFileManager defaultManager] directoryContentsAtPath: searchPath] objectEnumerator]; 
		
		while (currentBundlePath = [bundlePathIter nextObject]) {
			if ([[currentBundlePath pathExtension] isEqualTo: @"plugin"] ||
				[[currentBundlePath pathExtension] isEqualTo: @"scptd"]) 
			[self loadPlugin: [searchPath stringByAppendingPathComponent: currentBundlePath]]; 
		}
	}
}

- (void) unloadPlugins {
	// TODO: Implement 
}

@end

#pragma mark -
@implementation VTPluginController(PluginLoading) 

- (NSArray*) pluginSearchPaths {
	return [NSArray arrayWithObjects: 
		[[NSBundle mainBundle] builtInPlugInsPath], 
		[[NSString stringWithFormat: @"~/Library/Application Support/%@/PlugIns", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"]] stringByExpandingTildeInPath], 
		[NSString stringWithFormat: @"/Library/Application Support/%@/PlugIns", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"]], 
		nil]; 
}

- (void) ensurePluginSearchPaths {
	// we will only handle the user specific paths here
	NSString* rootPath	= [[NSString stringWithFormat: @"~/Library/Application Support/%@", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"]] stringByExpandingTildeInPath]; 
	NSString* path		= [[NSString stringWithFormat: @"~/Library/Application Support/%@/PlugIns", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"]] stringByExpandingTildeInPath]; 
	
	// check if it exists and create it if necessary 
	BOOL isDirectory = NO; 
	
	if (([[NSFileManager defaultManager] fileExistsAtPath: rootPath isDirectory: &isDirectory] == NO) ||
		(isDirectory == NO))
		[[NSFileManager defaultManager] createDirectoryAtPath: rootPath attributes: nil]; 
		
	
	if (([[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory] == NO) ||
		(isDirectory == NO))
		[[NSFileManager defaultManager] createDirectoryAtPath: path attributes: nil]; 
}

- (void) loadPlugin: (NSString*) path {
	// load the bundle 
	NSBundle* bundle = [NSBundle bundleWithPath: path];

	// create the wrapper instance 
	VTPluginInstance* plugin = [[[VTPluginInstance alloc] initWithBundle: bundle] autorelease]; 
	if (plugin == nil) 
		return; 
	
	[plugin load]; 

	// and attach 
	[[VTPluginCollection sharedInstance] attachPlugin: plugin]; 
}

@end 