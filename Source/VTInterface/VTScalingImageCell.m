//
//  VTScalingImageCell.m
//  VirtueDesktops
//
//  Created by Tony on 30/11/06.
//  Copyright 2007 boomBalada! Productions. All rights reserved.
//

#import "VTScalingImageCell.h"

/*
 Used for displaying a potentially large image
 */
@interface VTScalingImageCell (Private)
- (BOOL)isHighlighted;
@end

@implementation VTScalingImageCell
- (id)init
{
	if ((self = [super init])) {
		maxSize = NSZeroSize;
	}
	
	return self;
}

- (void)setMaxSize:(NSSize)inMaxSize
{
	maxSize = inMaxSize;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSImage	*img = [self image];
  
  // Enable high quality interpolation, so our scaled icons don't look like teh poo.
  [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
	
	if (img) {
		//Handle flipped axis
		[img setFlipped:![img isFlipped]];
		
		//Size and location
		//Get image metrics
		NSSize	imgSize = [img size];
		NSRect	imgRect = NSMakeRect(0, 0, imgSize.width, imgSize.height);
		
		//Scaling
		NSRect	targetRect = cellFrame;
		
		//Determine the correct maximum size, taking into account maxSize and our cellFrame.
		NSSize	ourMaxSize = cellFrame.size;
		if ((maxSize.width != 0) && (ourMaxSize.width > maxSize.width)) {
			ourMaxSize.width = maxSize.width;
		}
		if ((maxSize.height != 0) && (ourMaxSize.height > maxSize.height)) {
			ourMaxSize.height = maxSize.height;
		}
		
		if ((imgSize.height > ourMaxSize.height) ||
        (imgSize.width  >  ourMaxSize.width)) {
			
			if (imgSize.width > imgSize.height) {
				//Give width priority: Make the height change by the same proportion as the width will change
				targetRect.size.width = ourMaxSize.width;
				targetRect.size.height = imgSize.height * (targetRect.size.width / imgSize.width);
			} else {
				//Give height priority: Make the width change by the same proportion as the height will change
				targetRect.size.height = ourMaxSize.height;
				targetRect.size.width = imgSize.width * (targetRect.size.height / imgSize.height);
			}
		} else {
			targetRect.size.width = imgSize.width;
			targetRect.size.height = imgSize.height;
		}
    		
		//Centering
		targetRect = NSOffsetRect(targetRect, round((cellFrame.size.width - targetRect.size.width) / 2), round((cellFrame.size.height - targetRect.size.height) / 2));
		
		//Draw Image
		[img drawInRect:targetRect
           fromRect:imgRect
          operation:NSCompositeSourceOver 
           fraction:([self isEnabled] ? 1.0 : 0.5)];
		
		//Clean-up
		[img setFlipped:![img isFlipped]];
	}
}

//Super doesn't appear to handle the isHighlighted flag correctly, so we handle it to be safe.
- (void)setHighlighted:(BOOL)flag
{
	[self setState:(flag ? NSOnState : NSOffState)];
	isHighlighted = flag;
}
- (BOOL)isHighlighted
{
	return isHighlighted;
}
@end
