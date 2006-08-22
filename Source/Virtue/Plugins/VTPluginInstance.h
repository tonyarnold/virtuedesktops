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

@interface VTPluginInstance : NSObject {
	NSBundle*	mBundle;
	id        mPluginInstance;
	BOOL      mEnabled;
}

#pragma mark -
#pragma mark Lifetime 
- (id) initWithBundle: (NSBundle*) bundle; 

#pragma mark -
#pragma mark Operations 
- (void) load;

#pragma mark -
#pragma mark Attributes 
- (void) setEnabled: (BOOL) flag; 
- (BOOL) enabled; 

#pragma mark -
- (id) instance; 

#pragma mark -
#pragma mark Plugin property access
- (NSString*) pluginIdentifier; 
- (NSString*) pluginIconPath; 
- (NSString*) pluginName; 
- (BOOL) pluginIsHidden; 
- (NSString*) pluginAuthor; 
- (NSString*) pluginDescription; 
- (NSString*) pluginDescriptionPath; 

- (NSDictionary*) pluginInfoDictionary; 

#pragma mark NSObject overrides 
- (BOOL) respondsToSelector: (SEL) selector; 
- (BOOL) conformsToProtocol: (Protocol*) protocol; 

@end
