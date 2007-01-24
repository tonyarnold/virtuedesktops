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

#import "VTDecorationPrimitive.h" 
#import <Cocoa/Cocoa.h>

typedef enum {
	VTPrimitiveTintWholeScreen	= 0,
	VTPrimitiveTintBar			= 1,
} VTTintType; 

@interface VTDecorationPrimitiveTint : VTDecorationPrimitive {
	NSColor*	mColor; 
	float		mIntensity; 
	float		mSize; 
	VTTintType	mType; 
}

#pragma mark -
#pragma mark Lifetime 

- (id) init; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (void) setColor: (NSColor*) color; 
- (NSColor*) color; 

#pragma mark -
- (float) intensity; 
- (void) setIntensity: (float) intensity; 

#pragma mark -
- (void) setType: (VTTintType) type; 
- (VTTintType) type; 

#pragma mark -
- (void) setSize: (float) size; 
- (float) size; 

@end
