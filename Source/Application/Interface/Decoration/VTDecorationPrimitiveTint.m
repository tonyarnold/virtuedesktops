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

#import "VTDecorationPrimitiveTint.h"
#import "NSColorString.h" 
#import <Zen/Zen.h> 

#pragma mark Coding Keys 
#define kVtCodingColor			@"color"
#define kVtCodingType				@"tintType"
#define kVtCodingSize				@"size"
#define kVtCodingIntensity	@"intensity"

#pragma mark -
@implementation VTDecorationPrimitiveTint

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		// attributes 
		mIntensity		= 0.15; 
		mSize					= 20; 
		mColor				= [[[NSColor greenColor] colorWithAlphaComponent: mIntensity] retain];
		mType					= VTPrimitiveTintWholeScreen; 
		mName					= @"Tint Primitive";  
		mPositionType = kVtDecorationPositionBottom; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mColor); 
	
	[super dealloc]; 
}

#pragma mark NSCopying 
- (id) copyWithZone: (NSZone*) zone {
	VTDecorationPrimitiveTint* newInstance = (VTDecorationPrimitiveTint*)[super copyWithZone: zone]; 
	// and initialize 
	newInstance->mIntensity			= mIntensity; 
	newInstance->mSize					= mSize; 
	newInstance->mColor					= [mColor copyWithZone: zone]; 
	newInstance->mType					= mType; 
	newInstance->mPositionType	= mPositionType; 
	
	return newInstance; 
}

#pragma mark -
#pragma mark Coding 

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super initWithCoder: coder]) {
		// attributes 
		[self setColor: [coder decodeObjectForKey: kVtCodingColor]]; 
		return self; 
	}
	
	return nil; 
}

- (void) encodeWithCoder: (NSCoder*) coder {
	[super encodeWithCoder: coder];
	if ([self color] != nil)
		[coder encodeObject: [[self color] stringValue] forKey: kVtCodingColor];
	
}

#pragma mark -

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	[super encodeToDictionary: dictionary]; 
	
	[dictionary setObject: [NSNumber numberWithInt: [self type]] 
								 forKey: kVtCodingType]; 
	[dictionary setObject: [NSNumber numberWithFloat: [self size]] 
								 forKey: kVtCodingSize]; 
	if ([self color] != nil)
		[dictionary setObject: [[self color] stringValue] forKey: kVtCodingColor];
	 
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	if (self = [super decodeFromDictionary: dictionary]) { 
		[self setSize: [[dictionary objectForKey: kVtCodingSize] floatValue]]; 
		[self setType: [[dictionary objectForKey: kVtCodingType] intValue]]; 
		[self setColor: [NSColor colorWithString: [dictionary objectForKey: kVtCodingColor]]];
		[self setIntensity: [[self color] alphaComponent]];
		return self; 
	}
	
	return nil; 
}

#pragma mark -
#pragma mark Attributes 
- (void) setColor: (NSColor*) color {
	if (color == nil)
		color = [NSColor clearColor];
	
		
	// copy the color over and fetch its alpha component to remember 
	ZEN_ASSIGN_COPY(mColor, color);
	
	[self setIntensity: [mColor alphaComponent]];
	
	[self setNeedsDisplay];
}

- (NSColor*) color {
	return mColor; 
}

#pragma mark -
- (float) intensity {
	return mIntensity; 
}

- (void) setIntensity: (float) intensity {
	// modify alpha component of our color 
	NSColor* color = [mColor colorWithAlphaComponent: intensity];

	ZEN_ASSIGN(mColor, color);
	mIntensity = intensity;

	[self setNeedsDisplay];
}

#pragma mark -
- (void) setType: (VTTintType) type {
	mType = type; 
	
	[self setNeedsDisplay]; 
}

- (VTTintType) type {
	return mType; 
}

#pragma mark -
- (void) setSize: (float) size {
	mSize = size; 
	
	[self setNeedsDisplay]; 
}

- (float) size {
	return mSize; 
}

#pragma mark -
- (NSArray*) supportedPositionTypes {
	return [NSArray arrayWithObjects: 
		[NSNumber numberWithInt: kVtDecorationPositionTop], 
		[NSNumber numberWithInt: kVtDecorationPositionLeft],
		[NSNumber numberWithInt: kVtDecorationPositionRight], 
		[NSNumber numberWithInt: kVtDecorationPositionBottom],
    [NSNumber numberWithInt: kVtDecorationPositionCenter],
		nil]; 
}

#pragma mark -
#pragma mark Drawing 

- (void) drawInView: (NSView*) view withRect: (NSRect) rect {
	if (mColor == nil)
		return;
	
	NSRect barFrame = NSZeroRect;
	if (mType == VTPrimitiveTintWholeScreen) {
		barFrame = rect; 
	}
	else 
	{	
		if (mPositionType == kVtDecorationPositionLeft) {
			barFrame.origin.x = 0; 
			barFrame.origin.y = 0; 
			barFrame.size.height = rect.size.height; 
			barFrame.size.width = mSize; 
		}
		else if (mPositionType == kVtDecorationPositionRight) {
			barFrame.origin.x = rect.size.width - mSize; 
			barFrame.origin.y = 0; 
			barFrame.size.height = rect.size.height; 
			barFrame.size.width = mSize; 
		}
		else if (mPositionType == kVtDecorationPositionTop) {
			barFrame.origin.x = 0; 
			barFrame.origin.y = rect.size.height - mSize; 
			barFrame.size.width = rect.size.width; 
			barFrame.size.height = mSize;
		}
		else if (mPositionType == kVtDecorationPositionBottom) {
			barFrame.origin.x = 0; 
			barFrame.origin.y = 0; 
			barFrame.size.width = rect.size.width; 
			barFrame.size.height = mSize; 
		}
		else {
			barFrame = rect; 
		}
	}
	
	// now we are ready to draw 
	[mColor set]; 
	[NSBezierPath fillRect: barFrame]; 
}

@end
