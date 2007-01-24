//
//  VTScalingImageCell.h
//  VirtueDesktops
//
//  Created by Tony on 30/11/06.
//  Copyright 2007 boomBalada! Productions. All rights reserved.
//
//  Inspired by AIScaledImageCell from the Adium Project (http://adiumx.com/)

#import <Cocoa/Cocoa.h>


@interface VTScalingImageCell : NSImageCell {
	BOOL	isHighlighted;
	NSSize	maxSize;
}

/*
 * @brief Set the maximum image size
 *
 * A 0 width or height indicates no maximum. The default is NSZeroSize, no maximum besides the cell bounds.
 */
- (void)setMaxSize:(NSSize)inMaxSize;

@end
