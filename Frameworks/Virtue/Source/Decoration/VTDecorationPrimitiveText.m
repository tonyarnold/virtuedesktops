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

#import "VTDecorationPrimitiveText.h"
#import "NSColorString.h" 
#import <Zen/Zen.h>

#define kVtDefaultIntensity		1.0
#define kVtDefaultTextSize		10
#define kVtDefaultTextFont		@""
#define kVtDefaultText			@""

#define kVtCodingText			@"text"
#define kVtCodingFont			@"font"
#define kVtCodingColor			@"color"
#define kVtCodingShadow			@"hasShadow"

@interface VTDecorationPrimitiveText (Private) 
- (void) setAttributes; 
@end 

@implementation VTDecorationPrimitiveText

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		// attributes 
		mName = @"Text Primitive"; 
		
		// attributes 
		mText			= nil; 
		mFont			= [[NSFont boldSystemFontOfSize: 10] retain]; 
		mColor			= [[NSColor whiteColor] retain]; 
		mDisplaysShadow	= YES; 
		
		[self setAttributes]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mText); 
	ZEN_RELEASE(mFont); 
	ZEN_RELEASE(mColor); 
	ZEN_RELEASE(mTextAttributes); 
	
	[super dealloc]; 
}

#pragma mark NSCopying 
- (id) copyWithZone: (NSZone*) zone {
	VTDecorationPrimitiveText* newInstance = (VTDecorationPrimitiveText*)[super copyWithZone: zone]; 
	// and initialize 
	newInstance->mText				= [mText copyWithZone: zone]; 
	newInstance->mFont				= [mFont copyWithZone: zone]; 
	newInstance->mColor				= [mColor copyWithZone: zone]; 
	newInstance->mTextAttributes	= [mTextAttributes copyWithZone: zone]; 
	newInstance->mDisplaysShadow	= mDisplaysShadow; 
	
	return newInstance; 
}

#pragma mark -
#pragma mark Coding 

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super initWithCoder: coder]) {
		// and decode 
		mText	= [[coder decodeObjectForKey: kVtCodingText] retain]; 
		mFont	= [[coder decodeObjectForKey: kVtCodingFont] retain]; 
		mColor	= [[coder decodeObjectForKey: kVtCodingColor] retain];  
		
		[self setAttributes]; 
		
		return self; 
	}
	
	return nil; 
}

- (void) encodeWithCoder: (NSCoder*) coder {
	[super encodeWithCoder: coder]; 
	
	[coder encodeObject: mText forKey: kVtCodingText]; 
	[coder encodeObject: mFont forKey: kVtCodingFont]; 
	[coder encodeObject: mColor forKey: kVtCodingColor]; 
}

#pragma mark -

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	[super encodeToDictionary: dictionary]; 
	
	if (mText != nil)
		[dictionary setObject: mText forKey: kVtCodingText];
	else
		[dictionary setObject: @"" forKey: kVtCodingText]; 
	
	[dictionary setObject: [mColor stringValue] forKey: kVtCodingColor]; 
	[dictionary setObject: [[mFont fontDescriptor] fontAttributes] forKey: kVtCodingFont]; 
	[dictionary setObject: [NSNumber numberWithBool: mDisplaysShadow] forKey: kVtCodingShadow]; 
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	if (self = [super decodeFromDictionary: dictionary]) {
		[self setText: [dictionary objectForKey: kVtCodingText]]; 
		[self setColor: [NSColor colorWithString: [dictionary objectForKey: kVtCodingColor]]]; 
		[self setDisplaysShadow: [[dictionary objectForKey: kVtCodingShadow] boolValue]]; 
		
		NSDictionary* fontDescription = [dictionary objectForKey: kVtCodingFont]; 
		if (fontDescription)
			// now construct our font object 
			[self setFont: [NSFont fontWithName: [fontDescription objectForKey: NSFontNameAttribute] size: [[fontDescription objectForKey: NSFontSizeAttribute] intValue]]]; 
	
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

#pragma mark -
- (NSString*) fontName {
	return [mFont displayName]; 
}

- (NSFont*) font {
	return mFont; 
}

- (void) setFont: (NSFont*) font {
	[self willChangeValueForKey: @"fontName"]; 
	
	ZEN_ASSIGN(mFont, font); 

	[self setAttributes]; 
	[self setNeedsDisplay]; 
	
	[self didChangeValueForKey: @"fontName"]; 
}

#pragma mark -
- (float) fontSize {
	return [mFont pointSize]; 
}


#pragma mark -
- (NSColor*) color {
	return mColor; 
}

- (void) setColor: (NSColor*) color {
	if (color == nil)
		return; 
	
	ZEN_ASSIGN(mColor, color); 
	
	[self setAttributes]; 
	[self setNeedsDisplay]; 
}

#pragma mark -
- (BOOL) displaysShadow {
	return mDisplaysShadow; 
}

- (void) setDisplaysShadow: (BOOL) flag {
	mDisplaysShadow = flag; 
	
	[self setAttributes]; 
	[self setNeedsDisplay]; 
}

#pragma mark -
- (NSRect) bounds {
	if (mText == nil)
		return NSMakeRect(0, 0, 0, 0); 
	
	NSRect	screenFrame = [[NSScreen mainScreen] visibleFrame]; 	
	NSRect	bounds; 
	
	bounds.size = [mText sizeWithAttributes: mTextAttributes]; 
	
	// TODO: Move into its own method 
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
	NSPoint location;
	NSSize	textSize	= [mText sizeWithAttributes: mTextAttributes];

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
	}
	
	// draw desktopname 
	[mText drawAtPoint: location withAttributes: mTextAttributes];	
}

@end

#pragma mark -
@implementation VTDecorationPrimitiveText (Private) 

- (void) setAttributes {
	ZEN_RELEASE(mTextAttributes); 
	
	NSShadow*	shadow = nil;
	NSSize		offset = NSMakeSize(0, -2); 
	
	if (mDisplaysShadow) {
		shadow = [[[NSShadow alloc] init] autorelease];
		//[shadow setShadowColor: [NSColor blackColor]];
		[shadow setShadowColor: [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.36]];
		[shadow setShadowOffset: offset];
		[shadow setShadowBlurRadius: 3];
	}
	
	// create our text attributes 
	mTextAttributes = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
		mColor, NSForegroundColorAttributeName,	// color
		mFont, NSFontAttributeName,				// font and size
		shadow, NSShadowAttributeName,			// shadow 
		nil] retain];	
}

@end 
