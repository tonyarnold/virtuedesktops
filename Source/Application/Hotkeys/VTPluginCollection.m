/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTPluginCollection.h"
#import <Zen/Zen.h> 

@implementation VTPluginCollection

- (id) init {
	if (self = [super init]) {
		// attributes 
		mLoadedPlugins			= [[NSMutableDictionary alloc] init];
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mLoadedPlugins); 
	[super dealloc];
}


#pragma mark -
+ (VTPluginCollection*) sharedInstance {
	static VTPluginCollection* ms_INSTANCE = nil; 
	
	if (ms_INSTANCE == nil) 
		ms_INSTANCE = [[VTPluginCollection alloc] init]; 
	
	return ms_INSTANCE; 
}

#pragma mark -
#pragma mark Attributes 

- (NSArray*) plugins {
	// return everything we got 
	return [mLoadedPlugins allValues]; 
}

- (NSArray*) pluginsOfType: (Protocol*) type {
	// return plugins filtered by type 
	NSMutableArray*		plugins		= [[[NSMutableArray alloc] init] autorelease]; 
	NSEnumerator*		pluginIter	= [mLoadedPlugins objectEnumerator]; 
	VTPluginInstance*	plugin		= nil; 
	
	while (plugin = [pluginIter nextObject]) {
		// check type 
		if ([plugin conformsToProtocol: type]) {
			[plugins addObject: plugin]; 
		}
	}
	
	return plugins; 
}

#pragma mark -
- (void) attachPlugin: (VTPluginInstance*) plugin {
	// Fetch our plugin's UID 
	NSString* pluginIdentifier = [plugin pluginIdentifier];
	// and add it overwriting any other plugin we know by that name 
	[mLoadedPlugins setObject: plugin forKey: pluginIdentifier]; 
}

- (void) detachPlugin: (VTPluginInstance*) plugin {
  // Fetch our plugin's UID
  NSString* pluginIdentifier = [plugin pluginIdentifier];
  // Now remove the plugin from out loaded plugin list
  [mLoadedPlugins removeObjectForKey: pluginIdentifier];
}

#pragma mark -
#pragma mark Operations 
- (NSArray*) makePluginsOfType: (Protocol*) type performInvocation: (NSInvocation*) invocation {
	NSEnumerator*		pluginIter	= [[self pluginsOfType: type] objectEnumerator];
	VTPluginInstance*	plugin		= nil;
	
	NSMutableArray*		results		= [NSMutableArray array];
	NSMethodSignature*	signature	= [invocation methodSignature];
	
	while ((plugin = [pluginIter nextObject])) {
		// if this plugin is disabled, skip to next 
		if ([plugin enabled] == NO)
			continue; 
		
		if ([plugin respondsToSelector: [invocation selector]]) 
			[invocation invokeWithTarget: [plugin instance]];
		else
			continue;
		
		if(!strcmp([signature methodReturnType], @encode(id))) {
			id ret = nil;
			
			[invocation getReturnValue: &ret];
			if (ret) 
				[results addObject: ret];
			else 
				[results addObject: [NSNull null]];			
		} 
		else {
			void* ret = ([signature methodReturnLength] ? malloc([signature methodReturnLength]) : NULL);
			
			if (ret) {
				[invocation getReturnValue: ret];
				id res = [NSNumber numberWithBytes: ret objCType: [signature methodReturnType]];
				
				if (!res) 
					res = [NSValue valueWithBytes:ret objCType: [signature methodReturnType]];
				free(ret);
				
				[results addObject: res];
			} 
			else if ([results count]) 
				[results addObject: [NSNull null]];
		}
	}
	
	return results;
}

@end
