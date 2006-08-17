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

/**
 * The formal VirtueDesktops Plugin protocol, that plugins need to implement to be loaded
 * by Virtues plugin loader. 
 *
 */ 
@protocol VTPluginProtocol

/**
 * Called by VirtueDesktops to signal the plugin that it should set its enabled state to 
 * the passed boolean value. VirtueDesktops expects its plugins to behave and carry out 
 * the requested operation.
 *
 */ 
- (void) setEnabled: (BOOL) flag; 

/**
 * This message needs to return a unique identifier for the plugin; e.g. the bundle
 * identifier is the most useful and suggested return value. 
 * 
 */ 
- (NSString*) pluginIdentifier; 

/**
 * This message returns the image resource representing the plugin in the user 
 * interface. If your plugin does not provide a custom image, return nil and Virtue
 * will display the default plugin image for you. 
 *
 */ 
- (NSImage*) pluginIcon; 

/**
 * This message returns the display name of the plugin that can be localized. This
 * is the plugin identifier that is presented in the User Interface. 
 *
 */ 
- (NSString*) pluginDisplayName; 

/**
 * If this message returns YES, the plugin will not be displayed to the user, you should
 * rarely need to return YES here. 
 *
 */ 
- (BOOL) pluginIsHidden; 

@end


/**
 * Optional protocol that can be implemented by plugins but they are not required
 * to do so
 *
 */ 
@protocol VTPluginNotificationProtocol 

/**
 * Called by VirtueDesktops at the time VirtueDesktops loads the plugin bundle. You can expect all
 * VirtueDesktops functionality to be initialized at the time this message is sent. 
 *
 */ 
- (void) pluginDidLoad; 

/**
 * Message sent to a plugin just before VirtueDesktops is sending setEnabled: to the plugin. 
 *
 */ 
- (void) pluginWillEnable: (BOOL) flag; 

/**
 * Message sent to a plugin just after VirtueDesktops sent setEnabled: to the plugin 
 *
 */ 
- (void) pluginDidEnable: (BOOL) flag; 

@end 

/**
 * Optional information messages for a plugin 
 *
 */ 
@protocol VTPluginInformationProtocol 

/**
 * Message sent to a plugin to retrieve information about the author 
 *
 */ 
- (NSString*) pluginAuthor; 

/**
 * Message sent to a plugin to retrieve information about the plugin 
 *
 */ 
- (NSData*) pluginDescription; 

@end
