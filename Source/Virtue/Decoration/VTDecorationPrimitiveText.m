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

#import "VTDecorationPrimitiveText.h"
#import "NSColorString.h"
#import <Zen/Zen.h>

#define kVtDefaultIntensity		1.0
#define kVtDefaultTextSize		10
#define kVtDefaultTextFont		@""
#define kVtDefaultText        @""
#define kVtCodingText                   @"text"
#define kVtCodingFont                   @"font"
#define kVtCodingFontShadowOffset       @"shadowOffset"
#define kVtCodingFontShadowBlurRadius   @"shadowBlurRadius"
#define kVtCodingFontShadowColor        @"shadowColor"
#define kVtCodingFontColor              @"color"

@interface VTDecorationPrimitiveText (Private)
- (void) setAttributes;
@end

@implementation VTDecorationPrimitiveText

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		// attributes 
		mName                 = @"Text Primitive"; 
		mText                 = nil; 
		mFont                 = [[NSFont boldSystemFontOfSize: 12] autorelease];
    mFontShadow           = [[[NSShadow alloc] init] autorelease];
    mFontAttributes       = nil;
    
    [mFontShadow setShadowOffset: NSMakeSize(0, -2)];
    [mFontShadow setShadowBlurRadius: 3];
    [mFontShadow setShadowColor: [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.36]];
    
    mFontColor      = [NSColor whiteColor];
    
    [self setAttributes];
    
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mText); 
	ZEN_RELEASE(mFont); 
  ZEN_RELEASE(mFontColor);
  ZEN_RELEASE(mFontShadow);
  ZEN_RELEASE(mFontAttributes);
	
	[super dealloc]; 
}

#pragma mark NSCopying 
- (id) copyWithZone: (NSZone*) zone {
	VTDecorationPrimitiveText* newInstance = (VTDecorationPrimitiveText*)[super copyWithZone: zone]; 
	// and initialize 
	newInstance->mText                  = [mText copyWithZone: zone]; 
	newInstance->mFont                  = [mFont copyWithZone: zone]; 
  newInstance->mFontAttributes        = [mFontAttributes copyWithZone: zone];
  newInstance->mFontColor             = [mFontColor copyWithZone: zone];
  newInstance->mFontShadow            = [mFontShadow copyWithZone: zone];
	
	return newInstance; 
}

#pragma mark -
#pragma mark Coding 

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super initWithCoder: coder]) {
		mText	= [[coder decodeObjectForKey: kVtCodingText] retain]; 
		mFont	= [[coder decodeObjectForKey: kVtCodingFont] retain];
    mFontColor = [[coder decodeObjectForKey: kVtCodingFontColor] retain];
    mFontShadow = [[NSShadow alloc] init];
    [mFontShadow setShadowOffset: [coder decodeSizeForKey: kVtCodingFontShadowOffset]];
    [mFontShadow setShadowBlurRadius: [coder decodeFloatForKey: kVtCodingFontShadowBlurRadius]];
    [mFontShadow setShadowColor: [coder decodeObjectForKey: kVtCodingFontShadowColor]];
  
    [self setAttributes];
    
    return self; 
	}
	
	return nil; 
}

- (void) encodeWithCoder: (NSCoder*) coder {
	[super encodeWithCoder: coder]; 
	[coder encodeObject: mText forKey: kVtCodingText];
	[coder encodeObject: mFont forKey: kVtCodingFont];
  [coder encodeObject: mFontColor forKey: kVtCodingFontColor];
  [coder encodeSize: [mFontShadow shadowOffset] forKey: kVtCodingFontShadowOffset];
  [coder encodeFloat: [mFontShadow shadowBlurRadius] forKey: kVtCodingFontShadowBlurRadius];
  [coder encodeObject: [mFontShadow shadowColor] forKey: kVtCodingFontShadowColor];
}

#pragma mark -

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	[super encodeToDictionary: dictionary]; 
        
	if (mText != nil)
		[dictionary setObject: mText forKey: kVtCodingText];
	else
		[dictionary setObject: @"" forKey: kVtCodingText]; 
	
	[dictionary setObject: [mFontColor stringValue] forKey: kVtCodingFontColor];
  [dictionary setObject: [[mFont fontDescriptor] fontAttributes] forKey: kVtCodingFont];
  [dictionary setObject: [NSString stringWithFormat: @"{%f, %f}", [mFontShadow shadowOffset].width, [mFontShadow shadowOffset].height] forKey: kVtCodingFontShadowOffset];  // Special case - for some reason, encoding NSSize directly to an NSString was corrupting. This seems to work fine for little overhead.
  [dictionary setObject: [NSNumber numberWithFloat: [mFontShadow shadowBlurRadius]] forKey: kVtCodingFontShadowBlurRadius];
  [dictionary setObject: [[mFontShadow shadowColor] stringValue] forKey: kVtCodingFontShadowColor];
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
  if (self = [super decodeFromDictionary: dictionary]) {
		[self setText: [dictionary objectForKey: kVtCodingText]]; 
		
    NSFontDescriptor* fontDescriptor = [NSFontDescriptor fontDescriptorWithFontAttributes: [dictionary objectForKey: kVtCodingFont]];
		if (fontDescriptor != nil)
      [self setFont: [NSFont fontWithDescriptor: fontDescriptor size: [[fontDescriptor objectForKey: NSFontSizeAttribute] doubleValue]]]; 

    NSColor* fontColor = [NSColor colorWithString: [dictionary objectForKey: kVtCodingFontColor]];
    if (fontColor != nil)
      [self setFontColor: fontColor];
    
    [mFontShadow setShadowOffset: NSSizeFromString([dictionary objectForKey: kVtCodingFontShadowOffset])];
    [mFontShadow setShadowBlurRadius: [[dictionary objectForKey: kVtCodingFontShadowBlurRadius] floatValue]];
    NSColor* shadowColor = [NSColor colorWithString: [dictionary objectForKey: kVtCodingFontShadowColor]];
    
    if (shadowColor == nil)
      shadowColor = [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.36];
    
    [mFontShadow setShadowColor: shadowColor];
    
    return self; 
	}
	
	return nil; 
}

#pragma mark -
#pragma mark Attributes 

- (NSString*) text {
	return mText; 
}

- (void) setText: (NSString*) text {
	ZEN_ASSIGN_COPY(mText, text); 
	[self setNeedsDisplay]; 
}

- (NSString*) fontName {
	return [mFont displayName]; 
}

- (NSFont*) font {
	return mFont; 
}

- (void) setFont: (NSFont*) font {
  if (font == nil)
    return;
  
	[self willChangeValueForKey: @"fontName"]; 
	
	ZEN_ASSIGN(mFont, font);
  [self setAttributes];
  [self setNeedsDisplay];
	
	[self didChangeValueForKey: @"fontName"]; 
}

- (NSDictionary*) fontAttributes {
  return mFontAttributes;
}

- (float) fontSize {
	return [mFont pointSize]; 
}

- (NSShadow*) fontShadow {
  return mFontShadow;
}

- (void) setFontShadow: (NSShadow*) fontShadow {
  ZEN_ASSIGN(mFontShadow, fontShadow);
  [self setAttributes];
  [self setNeedsDisplay];
}

- (NSColor*) fontColor {
  return mFontColor;
}

- (void) setFontColor: (NSColor*) fontColor {
  if (fontColor == nil)
    return;
  
  ZEN_ASSIGN(mFontColor, fontColor);
  [self setAttributes];
  [self setNeedsDisplay];
}

#pragma mark -
- (NSRect) bounds {
	if (mText == nil)
		return NSMakeRect(0, 0, 0, 0); 
	
	NSRect	screenFrame = [[NSScreen mainScreen] visibleFrame]; 	
	NSRect	bounds; 
  bounds.size = [mText sizeWithAttributes: mFontAttributes]; 
	
	// @TODO: Move into its own method 
	if (mPositionType == kVtDecorationPositionAbsolute)
		bounds.origin = mPosition; 
	else {
		if (mPositionType == kVtDecorationPositionLL || mPositionType == kVtDecorationPositionTL) 
			bounds.origin.x = 10 + screenFrame.origin.x; 
		else 
			bounds.origin.x = screenFrame.size.width - 10 - bounds.size.width - screenFrame.origin.x;
		
		if (mPositionType == kVtDecorationPositionTR || mPositionType == kVtDecorationPositionTL) 
			bounds.origin.y = screenFrame.size.height + screenFrame.origin.y - bounds.size.height - 10; 
		else 
			bounds.origin.y = 10 + screenFrame.origin.y; 
	}
	
	return bounds; 
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
  // if there is no name, return
	if (mText == nil)
		return; 
  
  
	
	// draw the desktop name 
	NSRect	screenFrame = [[NSScreen mainScreen] visibleFrame]; 
	NSSize	textSize    = [mText sizeWithAttributes: mFontAttributes];
  NSPoint location;
  
	if (mPositionType == kVtDecorationPositionAbsolute)
		location = mPosition; 
	else {
		if (mPositionType == kVtDecorationPositionLL || mPositionType == kVtDecorationPositionTL) 
			location.x = 10 + screenFrame.origin.x; 
		else 
			location.x = screenFrame.size.width - 10 - textSize.width - screenFrame.origin.x;
    
		if (mPositionType == kVtDecorationPositionTR || mPositionType == kVtDecorationPositionTL) 
			location.y = screenFrame.size.height + screenFrame.origin.y - textSize.height - 10; 
		else 
			location.y = 10 + screenFrame.origin.y; 
    
    if (mPositionType == kVtDecorationPositionCenter) {
      location.x = (screenFrame.size.width/2) - (textSize.width/2);
      location.y = (screenFrame.size.height/2) - (textSize.height/2);
    }
	}
	
  
	// Draw desktopname
	[mText drawAtPoint: location withAttributes: mFontAttributes];	
}

@end

#pragma mark -
@implementation VTDecorationPrimitiveText (Private)

- (void) setAttributes {
  // Create our text attributes
  ZEN_RELEASE(mFontAttributes);
  mFontAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
      mFontColor, NSForegroundColorAttributeName,
      mFont, NSFontAttributeName,
      mFontShadow, NSShadowAttributeName,
      nil] retain];
      
}

@end
