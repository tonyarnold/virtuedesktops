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

typedef enum  {
	kVtImageScalingFillScreen = 0,
	kVtImageScalingStretch,
  kVtImageScalingCenter,
  kVtImageScalingTile,
} kVtImageScalingType;

@interface VTDecorationPrimitiveWatermark : VTDecorationPrimitive {
	NSString* mImagePath; 
	float     mIntensity;
  NSImage*  mImage;
  NSImage*  mDisplayImage;
  
  kVtImageScalingType  mImageScaling;
}

#pragma mark -
#pragma mark Lifetime 

- (id) init; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (void) setImagePath: (NSString*) path; 
- (NSString*) imagePath; 
- (NSString*) imageName;

#pragma mark -
- (void) setIntensity: (float) intensity; 
- (float) intensity; 

#pragma mark -
- (void) setScalingType: (kVtImageScalingType) scalingType;
- (kVtImageScalingType) scalingType;

@end
