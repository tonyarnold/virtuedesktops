/******************************************************************************
* 
* Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTDecorationPrimitiveWatermark.h"
#import <Zen/Zen.h> 

#pragma mark Coding keys 
#define kVtCodingImagePath		@"imagePath"
#define kVtCodingIntensity		@"intensity"

#pragma mark -
@implementation VTDecorationPrimitiveWatermark

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		mImagePath = nil; 
		mIntensity = 1.0; 
		mImage = nil; 
		
		mName = @"Watermark Primitive"; 
		
		return self; 
	}

	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mImagePath); 
	ZEN_RELEASE(mImage); 
	
	[super dealloc]; 
}

#pragma mark NSCopying 
- (id) copyWithZone: (NSZone*) zone {
	VTDecorationPrimitiveWatermark* newInstance = (VTDecorationPrimitiveWatermark*)[super copyWithZone: zone]; 
	// and initialize 
	newInstance->mImagePath = [mImagePath copyWithZone: zone]; 
	newInstance->mImage		= [mImage copyWithZone: zone]; 
	newInstance->mIntensity	= mIntensity; 
	
	return newInstance; 
}

#pragma mark -
#pragma mark Coding 

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super initWithCoder: coder]) {
		// attributes 
		[self setImagePath: [coder decodeObjectForKey: kVtCodingImagePath]]; 
		[self setIntensity: [coder decodeFloatForKey: kVtCodingIntensity]]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) encodeWithCoder: (NSCoder*) coder {
	[super encodeWithCoder: coder]; 
	
	[coder encodeObject: mImagePath forKey: kVtCodingImagePath]; 
	[coder encodeFloat: mIntensity forKey: kVtCodingIntensity]; 
}

#pragma mark -

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	[super encodeToDictionary: dictionary]; 
	
	if (mImagePath)
		[dictionary setObject: mImagePath forKey: kVtCodingImagePath]; 
	[dictionary setObject: [NSNumber numberWithFloat: mIntensity] forKey: kVtCodingIntensity]; 
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	if (self = [super decodeFromDictionary: dictionary]) { 
		[self setImagePath: [dictionary objectForKey: kVtCodingImagePath]]; 
		[self setIntensity: [[dictionary objectForKey: kVtCodingIntensity] floatValue]]; 
		
		return self; 
	}
	
	return nil; 
}

#pragma mark -
#pragma mark Attributes 
- (void) setImagePath: (NSString*) path {
	ZEN_ASSIGN_COPY(mImagePath, path); 
	ZEN_RELEASE(mImage); 
	
	if ((path) && ([path length] > 0))
		mImage = [[NSImage alloc] initByReferencingFile: mImagePath]; 
	
	[self setNeedsDisplay]; 
}

- (NSString*) imagePath {
	return mImagePath; 
}

#pragma mark -
- (void) setIntensity: (float) intensity {
	mIntensity = intensity; 
	[self setNeedsDisplay]; 
}

- (float) intensity {
	return mIntensity; 
}

#pragma mark -
- (NSArray*) supportedPositionTypes {
	return [NSArray arrayWithObjects: 
		[NSNumber numberWithInt: kVtDecorationPositionAbsolute],
		[NSNumber numberWithInt: kVtDecorationPositionTL], 
		[NSNumber numberWithInt: kVtDecorationPositionTR],
		[NSNumber numberWithInt: kVtDecorationPositionLL], 
		[NSNumber numberWithInt: kVtDecorationPositionLR],
		nil]; 
}

#pragma mark -
#pragma mark Drawing 

- (void) drawInView: (NSView*) view withRect: (NSRect) rect {
	// if there is no image, return 
	if (mImage == nil)
		return; 
	
	// draw the desktop name 
	NSPoint location;
	NSSize	imageSize = [mImage size];
	
	if (mPositionType == kVtDecorationPositionAbsolute)
		location = mPosition; 
	else {
		if (mPositionType == kVtDecorationPositionLL || mPositionType == kVtDecorationPositionTL) 
			location.x = 10 + rect.origin.x; 
		else 
			location.x = rect.size.width - 10 - imageSize.width - rect.origin.x;
		
		if (mPositionType == kVtDecorationPositionTR || mPositionType == kVtDecorationPositionTL) 
			location.y = rect.size.height + rect.origin.y - imageSize.height - 10; 
		else 
			location.y = 10 + rect.origin.y; 
	}
	
	// draw desktopname 
	[mImage dissolveToPoint: location fraction: mIntensity];
}

@end
