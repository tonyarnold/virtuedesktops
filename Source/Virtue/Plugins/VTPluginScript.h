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
#import "VTPluginProtocol.h" 

@protocol VTPluginScript  

/**
 * Used to initialize the plugin
 *
 * The passed apple script was already compiled and error checked by the plugin 
 * manager and can be used to execute incocations via callScriptHandler:withArguments:forSelector
 *
 */ 
- (id) initWithScript: (NSString*) scriptSource; 

/*
 * Script accessor
 *
 * Returns the applescript loaded for this script plugin 
 *
 */ 
- (NSAppleScript*) script; 

/**
 * Selectors requested for ignoring 
 *
 * Returns a list of selectors that are known to fail if called. The plugin 
 * manager will request this list prior to calling callScriptHandler:withArguments:forSelector
 * to make sure the call will succeed. 
 *
 */ 
- (NSArray*) selectorsRequestedForIgnoring; 

/**
 * Calls the script handler 
 *
 */ 
- (id) callScriptHandler: (unsigned long) handler withArguments: (NSDictionary*) arguments forSelector: (SEL) selector;


@end 