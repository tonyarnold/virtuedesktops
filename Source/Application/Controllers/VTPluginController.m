/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2006, Tony Arnold tony@tonyarnold.com
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
	NSArray*			searchPaths				= [self pluginSearchPaths]; 
	NSEnumerator*	searchPathIter		= [searchPaths objectEnumerator]; 
	NSString*			searchPath				= nil; 
	NSEnumerator*	bundlePathIter		= nil;
	NSString*			currentBundlePath	= nil;
	
	while (searchPath = [searchPathIter nextObject]) {
		bundlePathIter = [[[NSFileManager defaultManager] directoryContentsAtPath: searchPath] objectEnumerator]; 
		
		while (currentBundlePath = [bundlePathIter nextObject]) {
			if ([[currentBundlePath pathExtension] isEqualTo: @"plugin"] || [[currentBundlePath pathExtension] isEqualTo: @"scptd"]) {
				[self loadPlugin: [searchPath stringByAppendingPathComponent: currentBundlePath]]; 
			}
		}
	}
}

- (void) unloadPlugins {
	// TODO: Implement 
}

@end

#pragma mark -
@implementation VTPluginController(PluginLoading) 

/* Change this path/code to point to your App's data store. */
- (NSString *)applicationSupportFolder {
	NSString *applicationSupportFolder = nil;
	FSRef foundRef;
	OSErr err = FSFindFolder(kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, &foundRef);
	if (err != noErr) {
		NSRunAlertPanel(@"Alert", @"Can't find application support folder", @"Quit", nil, nil);
		[[NSApplication sharedApplication] terminate:self];
	} else {
		unsigned char path[1024];
		FSRefMakePath(&foundRef, path, sizeof(path));
		applicationSupportFolder = [NSString stringWithUTF8String:(char *)path];
		applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:[NSString stringWithFormat: @"%@/PlugIns", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"]]];
	}
	return applicationSupportFolder;
}

- (NSString *)globalApplicationSupportFolder {
	NSString *applicationSupportFolder = nil;
	FSRef foundRef;
	OSErr err = FSFindFolder(kLocalDomain, kApplicationSupportFolderType, kDontCreateFolder, &foundRef);
	if (err != noErr) {
		NSRunAlertPanel(@"Alert", @"Can't find application support folder", @"Quit", nil, nil);
		[[NSApplication sharedApplication] terminate:self];
	} else {
		unsigned char path[1024];
		FSRefMakePath(&foundRef, path, sizeof(path));
		applicationSupportFolder = [NSString stringWithUTF8String:(char *)path];
		applicationSupportFolder = [applicationSupportFolder stringByAppendingPathComponent:[NSString stringWithFormat: @"%@/PlugIns", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"]]];
	}
	return applicationSupportFolder;
}

- (NSArray*) pluginSearchPaths {
	return [NSArray arrayWithObjects:
			[[NSBundle mainBundle] builtInPlugInsPath], 
			[self applicationSupportFolder], 
			[self globalApplicationSupportFolder],
			nil
		]; 
}

- (void) ensurePluginSearchPaths {
	// we will only handle the user specific paths here
	NSString* rootPath	= [self applicationSupportFolder]; 
	NSString* path			= [NSString stringWithFormat: @"%@", rootPath]; 
	
	// check if it exists and create it if necessary 
	BOOL isDirectory = NO; 
	
	if (([[NSFileManager defaultManager] fileExistsAtPath: rootPath isDirectory: &isDirectory] == NO) ||
		(isDirectory == NO))
	{
		[[NSFileManager defaultManager] createDirectoryAtPath: rootPath 
																							 attributes: nil]; 
	}
	
	if (([[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDirectory] == NO) ||
		(isDirectory == NO))
	{
		[[NSFileManager defaultManager] createDirectoryAtPath: path 
																							 attributes: nil]; 
	}
}

- (void) loadPlugin: (NSString*) path {
	// load the bundle 
	NSBundle* bundle = [[NSBundle alloc] initWithPath: path];
	
	// create the wrapper instance 
	VTPluginInstance* plugin = [[[VTPluginInstance alloc] initWithBundle: bundle] autorelease]; 
	if (plugin == nil) 
		return; 
	
	[plugin load]; 

	// Éand attach 
	[[VTPluginCollection sharedInstance] attachPlugin: plugin]; 
}

@end 
