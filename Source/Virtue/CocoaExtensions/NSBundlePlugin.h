/******************************************************************************
 * 
 * VirtueDesktops 
 *
 * A desktop extension for MacOS X
 *
 * Copyright 2004, Thomas Staller <playback@users.sourceforge.net>
 *
 * See COPYING for licensing details
 * 
 *****************************************************************************/ 

#import <Cocoa/Cocoa.h>

#pragma mark -
#pragma mark Accessor keys
#define VTPluginInfoAuthor					@"author"
#define VTPluginInfoName				@"name"
#define VTPluginInfoDescription			@"description"
#define VTPluginInfoDescriptionPath	@"descriptionFile"
#define VTPluginInfoIsHidden				@"hidden"
#define VTPluginInfoType						@"type"

#define VTPluginInfoTypeApplescript	@"VTApplescript"
#define VTPluginInfoApplescript			@"source"

#define VTPluginInfoTypeClass				@"VTObjectiveC"

@interface NSBundle(VTPlugin)
- (NSDictionary*) pluginInfoDictionary; 
@end
