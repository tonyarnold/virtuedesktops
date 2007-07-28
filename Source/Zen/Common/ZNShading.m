//
//  ZNShading.m
//  Zen framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import <Cocoa/Cocoa.h>
#import "ZNShading.h" 

@interface ZNAxialShading (CGSPreparation)
- (void) createShaderInfo: (NSColor*) startColor endColor: (NSColor*) endColor; 
- (CGFunctionRef) createShaderFunction; 
- (CGShadingRef) createShaderForRect: (NSRect) frame startEdge: (ZNEdge) startEdge; 
@end 

static void ZNAxialShaderFunction(void* infoIn, const float* in, float* out) {
	// fetch the info 
	ZNAxialShaderInfo* info = (ZNAxialShaderInfo*)infoIn;

    float v = *in; 
	out[0] = info->startColor[0] + (info->endColor[0] - info->startColor[0]) * v; 
	out[1] = info->startColor[1] + (info->endColor[1] - info->startColor[1]) * v; 
	out[2] = info->startColor[2] + (info->endColor[2] - info->startColor[2]) * v; 
	out[3] = info->startColor[3] + (info->endColor[3] - info->startColor[3]) * v; 
}


#pragma mark -
@implementation ZNAxialShading

#pragma mark -
#pragma mark Lifetime 
+ (ZNAxialShading*) shadingInRect: (NSRect) frame startColor: (NSColor*) color endColor: (NSColor*) endColor startEdge: (ZNEdge) edge {
	return [[[ZNAxialShading alloc] initInRect: frame startColor: color endColor: endColor startEdge: edge] autorelease]; 
}

- (id) initInRect: (NSRect) frame startColor: (NSColor*) color endColor: (NSColor*) endColor startEdge: (ZNEdge) edge {
	if (self = [super init]) {
		// create the info structure 
		[self createShaderInfo: color endColor: endColor]; 
		// create the shader 
		mShaderFunction = [self createShaderFunction]; 
		mShader			= [self createShaderForRect: frame startEdge: edge]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	CGShadingRelease(mShader);
	CGFunctionRelease(mShaderFunction);
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Operations 
- (void) fill {
	CGContextDrawShading([[NSGraphicsContext currentContext] graphicsPort], mShader);
}

@end


#pragma mark -
@implementation ZNAxialShading (CGSPreparation)
- (void) createShaderInfo: (NSColor*) startColor endColor: (NSColor*) endColor {
	// fill info structure 
	mInfo.startColor[0] = [startColor redComponent]; 
	mInfo.startColor[1] = [startColor greenComponent]; 
	mInfo.startColor[2] = [startColor blueComponent]; 
	mInfo.startColor[3] = [startColor alphaComponent]; 

	mInfo.endColor[0] = [endColor redComponent]; 
	mInfo.endColor[1] = [endColor greenComponent]; 
	mInfo.endColor[2] = [endColor blueComponent]; 
	mInfo.endColor[3] = [endColor alphaComponent]; 
}

- (CGFunctionRef) createShaderFunction {
    const float input_value_range [2]	= { 0, 1 }; 
	const float output_value_ranges [8] = { 0, 1, 0, 1, 0, 1, 0, 1 };
	const CGFunctionCallbacks callbacks = { 0, &ZNAxialShaderFunction, NULL };

    return CGFunctionCreate((void*)&mInfo,
							 1,
							 input_value_range,
							 4,
							 output_value_ranges,
							 &callbacks);
}

- (CGShadingRef) createShaderForRect: (NSRect) frame startEdge: (ZNEdge) startEdge {
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB(); 
	CGPoint			startPoint; 
	CGPoint			endPoint; 
	
	// calculate start and end point 
	switch (startEdge) {
		case ZNEdgeLeft: 
			startPoint  = CGPointMake(frame.origin.x, frame.origin.y); 
			endPoint    = CGPointMake(frame.size.width, frame.origin.y); 
			break; 
		case ZNEdgeRight: 
			startPoint  = CGPointMake(frame.size.width, frame.origin.y); 
			endPoint    = CGPointMake(frame.origin.x, frame.origin.y); 
			break; 
		case ZNEdgeBottom: 
			startPoint  = CGPointMake(frame.origin.x, frame.origin.y); 
			endPoint    = CGPointMake(frame.origin.x, frame.size.height); 
			break; 
		case ZNEdgeTop: 
			startPoint  = CGPointMake(frame.origin.x, frame.size.height); 
			endPoint    = CGPointMake(frame.origin.x, frame.origin.y); 
			break; 
		// Diagonals 
		case ZNEdgeTopLeft: 
			startPoint  = CGPointMake(frame.origin.x, frame.size.height); 
			endPoint    = CGPointMake(frame.size.width, frame.origin.y); 
			break; 
		case ZNEdgeTopRight: 
			startPoint  = CGPointMake(frame.size.width, frame.size.height); 
			endPoint    = CGPointMake(frame.origin.x, frame.origin.y); 
			break; 
		case ZNEdgeBottomLeft: 
			startPoint  = CGPointMake(frame.origin.x, frame.origin.y); 
			endPoint    = CGPointMake(frame.size.width, frame.size.height); 
			break; 
		case ZNEdgeBottomRight: 
			startPoint  = CGPointMake(frame.size.width, frame.origin.y); 
			endPoint    = CGPointMake(frame.origin.x, frame.size.height); 
			break; 
        default:
            endPoint = startPoint = CGPointMake(0.,0.);
	}
	
	// create the shader 
	CGShadingRef shader = CGShadingCreateAxial(colorspace, startPoint, endPoint, mShaderFunction, false, false);

	// release the colorspace 
	CGColorSpaceRelease(colorspace); 
	
	// and we are done 
	return shader; 
}

@end 

