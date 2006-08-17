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
#import "VTDecorationPrimitive.h" 

@interface VTDecorationPrimitiveWatermark : VTDecorationPrimitive {
	NSString*	mImagePath; 
	float		mIntensity; 
	
	NSImage*	mImage; 
}

#pragma mark -
#pragma mark Lifetime 

- (id) init; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (void) setImagePath: (NSString*) path; 
- (NSString*) imagePath; 

#pragma mark -
- (void) setIntensity: (float) intensity; 
- (float) intensity; 

@end
