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

#import "VTPluginInstance.h"
#import "VTScriptPlugin.h" 
#import "NSBundlePlugin.h"
#import <Zen/Zen.h> 

#pragma mark -
@implementation VTPluginInstance

- (id) initWithBundle: (NSBundle*) bundle {
	if (self = [super init]) {
		ZEN_ASSIGN(mBundle, bundle);
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mBundle); 
	ZEN_RELEASE(mPluginInstance); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Operations 
- (void) load {
	// if we are dealing with an applescript package, we load the script found inside
	if ([[[mBundle pluginInfoDictionary] objectForKey: VTPluginInfoType] isEqualToString: VTPluginInfoTypeApplescript]) {
		// read out names of applescripts 
		NSString* script = [[mBundle pluginInfoDictionary] objectForKey: VTPluginInfoApplescript]; 
		NSString* fullScriptPath = [mBundle pathForResource: script ofType: @"scpt" inDirectory: @"Scripts"]; 
		// ignore if not found 
		if (fullScriptPath == nil) 
			return; 
			
		// create the instance 
		VTScriptPlugin* pluginInstance = [[[VTScriptPlugin alloc] initWithScript: fullScriptPath] autorelease];
		if (pluginInstance == nil) 
			return; 
			
		ZEN_ASSIGN(mPluginInstance, pluginInstance); 
		return; 
	}
	if ([[[mBundle pluginInfoDictionary] objectForKey: VTPluginInfoType] isEqualToString: VTPluginInfoTypeClass]) {
		// load the class 
		Class pluginClass = [mBundle principalClass]; 
		if (pluginClass == nil)
			return; 
		
		// instantiate 
		id pluginInstance = [[[pluginClass alloc] init] autorelease]; 
		if (pluginInstance == nil)
			return; 
		
		ZEN_ASSIGN(mPluginInstance, pluginInstance); 
		return; 
	}
}

#pragma mark -
#pragma mark Attributes 
- (void) setEnabled: (BOOL) flag {
	mEnabled = flag;
}

- (BOOL) enabled {
	return mEnabled; 
}

#pragma mark -
- (id) instance {
	return mPluginInstance; 
}

#pragma mark -
#pragma mark Information
- (NSString*) pluginIdentifier {
	return [mBundle bundleIdentifier]; 
}

- (NSString*) pluginIconPath {
	return [mBundle objectForInfoDictionaryKey: @"CFBundleIconFile"]; 
}

- (NSString*) pluginName {
	return [[mBundle pluginInfoDictionary] objectForKey: VTPluginInfoName]; 
}

- (BOOL) pluginIsHidden {
	if ([[[mBundle pluginInfoDictionary] objectForKey: VTPluginInfoIsHidden] isKindOfClass: [NSString class]]) 
		return ([[[mBundle pluginInfoDictionary] objectForKey: VTPluginInfoIsHidden] intValue] == 1); 
	else 
		return [[[mBundle pluginInfoDictionary] objectForKey: VTPluginInfoIsHidden] boolValue]; 

	return NO; 
}

- (NSString*) pluginAuthor {
	return [[mBundle pluginInfoDictionary] objectForKey: VTPluginInfoAuthor]; 
}

- (NSString*) pluginDescription {
	return [[mBundle pluginInfoDictionary] objectForKey: VTPluginInfoDescription]; 
}

- (NSString*) pluginDescriptionPath {
	return [[mBundle pluginInfoDictionary] objectForKey: VTPluginInfoDescriptionPath]; 
}

- (NSDictionary*) pluginInfoDictionary {
	return [mBundle pluginInfoDictionary];
}

#pragma mark -
#pragma mark NSObject overrides 
- (BOOL) respondsToSelector: (SEL) selector {
	return [mPluginInstance respondsToSelector: selector]; 
}

- (BOOL) conformsToProtocol: (Protocol*) protocol {
	return [mPluginInstance conformsToProtocol: protocol]; 
}

@end
