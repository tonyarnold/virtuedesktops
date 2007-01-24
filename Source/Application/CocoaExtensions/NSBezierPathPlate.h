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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

/**
 * @brief	Plate bezier path extension 
 *
 * @note	NSBezierPathPlate is based on an implementation found at 
 *			http://www.harmless.de/cocoa.html 
 *			by Andreas. 
 */ 
@interface NSBezierPath (VTPlate)
	+ (NSBezierPath*) bezierPathWithPlateInRect: (NSRect) aRect; 
	+ (NSBezierPath*) bezierPathForRoundedRect: (NSRect) aRect withRadius: (int) radius; 
	+ (NSBezierPath*) bezierPathForRoundedRect: (NSRect) aRect withRadius: (int) radius roundTop: (BOOL) roundingTop roundBottom: (BOOL) roundingBottom; 
@end
