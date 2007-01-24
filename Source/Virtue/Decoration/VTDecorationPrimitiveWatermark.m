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

#import "VTDecorationPrimitiveWatermark.h"
#import "NSScreenOverallScreen.h"
#import <Zen/Zen.h> 

#pragma mark Coding keys 
#define kVtCodingImagePath		@"path"
#define kVtCodingIntensity		@"intensity"
#define kVtCodingScaling      @"scaling"

#pragma mark -
@implementation VTDecorationPrimitiveWatermark

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		mImagePath = nil; 
		mIntensity = 1.0; 
		mImage = nil;
    mImageScaling = kVtImageScalingFillScreen;
		mName = @"Watermark Primitive"; 
		
		return self; 
	}

	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mImagePath); 
	ZEN_RELEASE(mImage); 
  ZEN_RELEASE(mDisplayImage);
	
	[super dealloc]; 
}

#pragma mark NSCopying 
- (id) copyWithZone: (NSZone*) zone {
	VTDecorationPrimitiveWatermark* newInstance = (VTDecorationPrimitiveWatermark*)[super copyWithZone: zone]; 
	// and initialize 
	newInstance->mImagePath     = [mImagePath copyWithZone: zone]; 
	newInstance->mImage         = [mImage copyWithZone: zone]; 
	newInstance->mIntensity     = mIntensity;
  newInstance->mImageScaling  = mImageScaling;
	
	return newInstance; 
}

#pragma mark -
#pragma mark Coding 

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super initWithCoder: coder]) {
		// attributes 
		[self setImagePath: [coder decodeObjectForKey: kVtCodingImagePath]]; 
		[self setIntensity: [coder decodeFloatForKey: kVtCodingIntensity]];
    [self setScalingType: [coder decodeIntForKey: kVtCodingScaling]];
		
		return self; 
	}
	
	return nil; 
}

- (void) encodeWithCoder: (NSCoder*) coder {
	[super encodeWithCoder: coder]; 
	
	[coder encodeObject: mImagePath forKey: kVtCodingImagePath]; 
	[coder encodeFloat: mIntensity forKey: kVtCodingIntensity];
  [coder encodeInt: mImageScaling forKey: kVtCodingScaling];
}

#pragma mark -

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	[super encodeToDictionary: dictionary]; 
	
	if (mImagePath)
		[dictionary setObject: [self imagePath] forKey: kVtCodingImagePath];
  
  if (mImageScaling)
    [dictionary setObject: [NSNumber numberWithInt: [self scalingType]] forKey: kVtCodingScaling];
  
  if (mIntensity)
    [dictionary setObject: [NSNumber numberWithFloat: [self intensity]] forKey: kVtCodingIntensity];
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	if (self = [super decodeFromDictionary: dictionary]) { 
		[self setImagePath: [dictionary objectForKey: kVtCodingImagePath]]; 
		[self setIntensity: [[dictionary objectForKey: kVtCodingIntensity] floatValue]];
    [self setScalingType: [[dictionary objectForKey: kVtCodingScaling] intValue]];
		
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
  
  [mImage setScalesWhenResized: YES];
	[self setNeedsDisplay]; 
}

- (NSString*) imagePath {
	return mImagePath; 
}

- (NSString*) imageName {
  return [[self imagePath] lastPathComponent];
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
- (void) setScalingType: (kVtImageScalingType) scalingType
{
  mImageScaling = scalingType;
  [self setNeedsDisplay];
}

- (kVtImageScalingType) scalingType
{
  return mImageScaling;
}

#pragma mark -
- (NSArray*) supportedPositionTypes {
	return [NSArray arrayWithObjects: 
		[NSNumber numberWithInt: kVtDecorationPositionAbsolute],
		[NSNumber numberWithInt: kVtDecorationPositionTL], 
		[NSNumber numberWithInt: kVtDecorationPositionTR],
		[NSNumber numberWithInt: kVtDecorationPositionLL], 
		[NSNumber numberWithInt: kVtDecorationPositionLR],
    [NSNumber numberWithInt: kVtDecorationPositionCenter],
		nil]; 
}

#pragma mark -
#pragma mark Drawing 

- (void) drawInView: (NSView*) view withRect: (NSRect) rect {
	// if there is no image, return 
	if (mImage == nil)
		return; 
  
  NSRect bounds = [view visibleRect];  
  
  // If we're tiling, just draw and bail
  if ([self scalingType] == kVtImageScalingTile)
  {
    [[NSColor colorWithPatternImage: mImage] set];
    NSRectFill(bounds);
    return;
  }
  
	// draw the desktop image 
	NSPoint   location;
  ZEN_ASSIGN_COPY(mDisplayImage, mImage);
	NSSize    size = [mDisplayImage size];
  float     scaleFactor;

  switch ([self scalingType]) {
    case kVtImageScalingCenter:
      break;
    case kVtImageScalingFillScreen: 
      // We need to calculate the longest side of the image, then scale up to the smaller side to the width/height of the screen
      scaleFactor = size.width > size.height ? (bounds.size.width / size.width) : (bounds.size.height / size.height);
      size.width  *= scaleFactor;
      size.height *= scaleFactor;
      break;
    case kVtImageScalingStretch:
      size = bounds.size;
      break;
    default:
      ;
  }
  
  [mDisplayImage setSize: size];

  
	if (mPositionType == kVtDecorationPositionAbsolute)
		location = mPosition; 
	else {
		if (mPositionType == kVtDecorationPositionLL || mPositionType == kVtDecorationPositionTL) 
			location.x = 10 + rect.origin.x; 
		else 
			location.x = rect.size.width - 10 - size.width - rect.origin.x;
		
		if (mPositionType == kVtDecorationPositionTR || mPositionType == kVtDecorationPositionTL) 
			location.y = rect.size.height + rect.origin.y - size.height - 10; 
		else 
			location.y = 10 + rect.origin.y; 
    
    if (mPositionType == kVtDecorationPositionCenter) {
      location.x = (rect.size.width - size.width)/2;
      location.y = (rect.size.height - size.height)/2;
    }
	}
  
  [mDisplayImage dissolveToPoint: location fraction: mIntensity];
}

@end
