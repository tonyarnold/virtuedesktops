//
//  NSBezierPathPlate.h
//  VirtueDesktops
//
//  Created by Tony on 2/10/06.
//  Copyright 2006 boomBalada! Productions. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
* @brief	Plate bezier path extension 
 *
 * @note	NSBezierPathPlate is based on an implementation found at 
 *			http://www.harmless.de/cocoa.html 
 *			by Andreas. 
 */ 
@interface NSBezierPath (VTUIPlate)
+ (NSBezierPath*) bezierPathWithPlateInRect: (NSRect) aRect; 
+ (NSBezierPath*) bezierPathForRoundedRect: (NSRect) aRect withRadius: (int) radius; 
+ (NSBezierPath*) bezierPathForRoundedRect: (NSRect) aRect withRadius: (int) radius roundTop: (BOOL) roundingTop roundBottom: (BOOL) roundingBottom; 
@end

