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

#import <Cocoa/Cocoa.h>
#import "VTPluginInstance.h" 

@interface VTPluginCollection : NSObject {
	// Loaded plugin instances indexed by their bundle identifier 
	NSMutableDictionary*	mLoadedPlugins;
}

#pragma mark -
#pragma mark Instance 

+ (VTPluginCollection*) sharedInstance; 

#pragma mark -
#pragma mark Attributes 

- (NSArray*) plugins; 
- (NSArray*) pluginsOfType: (Protocol*) type; 

- (void) attachPlugin: (VTPluginInstance*) plugin; 
- (void) detachPlugin: (VTPluginInstance*) plugin;

#pragma mark -
#pragma mark Actions 
- (NSArray*) makePluginsOfType: (Protocol*) type performInvocation: (NSInvocation*) invocation; 


@end
