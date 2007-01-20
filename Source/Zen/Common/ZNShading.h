//
//  ZNShading.h
//  Zen framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import <Cocoa/Cocoa.h>
#import "ZNEdge.h" 

typedef struct {
	float startColor[4]; 
	float endColor[4]; 
} ZNAxialShaderInfo; 

#pragma mark -
@interface ZNAxialShading : NSObject {
	CGFunctionRef		mShaderFunction; 
	CGShadingRef		mShader; 
	ZNAxialShaderInfo	mInfo; 
}

#pragma mark -
#pragma mark Lifetime 
+ (ZNAxialShading*) shadingInRect: (NSRect) frame startColor: (NSColor*) color endColor: (NSColor*) endColor startEdge: (ZNEdge) edge;  
- (id) initInRect: (NSRect) frame startColor: (NSColor*) color endColor: (NSColor*) endColor startEdge: (ZNEdge) edge; 

#pragma mark -
- (void) fill;

@end
