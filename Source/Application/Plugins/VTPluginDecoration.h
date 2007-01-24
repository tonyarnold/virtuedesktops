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
#import "VTInspector.h" 

/**
 * VTPluginDecoration 
 *
 * Plugin interface for plugins providing new kinds of decoration primitives 
 * for desktop decorations. There is only one provided interface methods that
 * needs implementation, decorationPrimitiveClass, that should return the 
 * class type information of the decoration primitive provided by this plugin. 
 *
 */ 
@protocol VTPluginDecoration

#pragma mark -
#pragma mark Type information

/**
 * Decoration primitive type information
 *
 * Simple as that. Just return the class type of the decoration primitive 
 * provided by this plugin. VirtueDesktops will then instantiate objects of the
 * returned class and call the designated initializer initWithName:inContainer:. 
 *
 */
- (Class) decorationPrimitiveClass; 

/**
 * Decoration primitive inspector instance 
 *
 * Returns an instance of a decoration primitive inspector; if your implementation
 * does not support inspectors, you can safely return nil here. 
 * 
 */ 
- (VTInspector*) decorationPrimitiveInspector; 

@end
