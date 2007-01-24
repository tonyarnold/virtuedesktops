//
//  TAUIColorLabelButtonCell.m
//  TAUserInterfaceElements.framework
//
//  Created by Tony on 2/10/06.
//  Copyright 2007 boomBalada! Productions.
//  Some rights reserved: <http://creativecommons.org/licenses/by/2.5/>
//

#import "TAUIColorLabelButtonCell.h"
#import "../Zen/Macros/ZNMemoryManagementMacros.h"
#import "NSBezierPath+Plate.h"

@implementation TAUIColorLabelButtonCell

- (id) init {
	if (self = [super initImageCell: nil]) {
		mColor			= [[NSColor clearColor] retain]; 
		mMouseInside	= NO; 
		
		[self setType: TAUIColorLabelType];  
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mColor); 
	ZEN_RELEASE(mImage); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Coders 

- (id)initWithCoder:(NSCoder *)coder
{
  if (self = [super initWithCoder:coder]) {
    if ([coder respondsToSelector:@selector(allowsKeyedCoding)]
        && [coder allowsKeyedCoding]) {
      [self setColor:     [coder decodeObjectForKey: @"color"]];
      [self setSelected:  [coder decodeBoolForKey: @"selected"]];
    } else {
      [self setColor: [coder decodeObject]];
      BOOL mTmpSelected = NO;
      [coder decodeValueOfObjCType: @encode(BOOL) at: &mTmpSelected];
      [self setSelected: mTmpSelected];
    }
    TAUIColorLabelButtonType mTmpType;
    [coder decodeValueOfObjCType: @encode(TAUIColorLabelButtonType) at: &mTmpType];
    [self setLabelType: mTmpType];
    return self;
  }
  return nil;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  if ([coder allowsKeyedCoding]){
    [coder encodeObject:  [self color] forKey: @"color"];
    [coder encodeBool:    [self selected] forKey: @"selected"];
  } else {
    [coder encodeObject: [self color]];
    [coder encodeValueOfObjCType: @encode(BOOL) at: &mSelected];
  }
  
  [coder encodeValueOfObjCType: @encode(TAUIColorLabelButtonType) at: &mType];
  
}

- (id)copyWithZone:(NSZone *)zone
{
  TAUIColorLabelButtonCell *copy;
  
  copy = [[TAUIColorLabelButtonCell allocWithZone:zone] init];
  
  [copy setColor: [self color]];
  [copy setSelected: [self selected]];
  [copy setLabelType: [self labelType]];
  return copy;
}

#pragma mark -
#pragma mark Attributes 
- (void) setColor: (NSColor*) color {
	ZEN_ASSIGN(mColor, color); 
}

- (NSColor*) color {
	return [[mColor copy] autorelease]; 
}

#pragma mark -
- (void) setSelected: (BOOL) flag {
	mSelected = flag; 
	[[self controlView] setNeedsDisplay: YES]; 
}

- (BOOL) selected {
	return mSelected; 
}

#pragma mark -
- (void) setLabelType: (TAUIColorLabelButtonType) type {
	mType = type;
  NSString *bundleResourcePath = [[NSBundle bundleForClass: [TAUIColorLabelButtonCell class]] resourcePath];
	
	// set image to display
	ZEN_RELEASE(mImage);
	if (mType == TAUIClearLabelType)
    mImage = [[NSImage alloc] initByReferencingFile: [NSBundle pathForResource:@"imageColorLabelClear" ofType:@"png" inDirectory: bundleResourcePath]];
	else
    mImage = [[NSImage alloc] initByReferencingFile: [NSBundle pathForResource:@"imageColorLabelMaskComposite" ofType:@"png" inDirectory: bundleResourcePath]];
	
	[[self controlView] setNeedsDisplay: YES]; 
}

- (TAUIColorLabelButtonType) labelType {
	return mType; 
}


#pragma mark -
#pragma mark NSCell 
- (void) mouseEntered: (NSEvent*) event {
	mMouseInside = YES; 
	
	[[self controlView] setNeedsDisplay: YES]; 
}

- (void) mouseExited: (NSEvent*) event {
	mMouseInside = NO; 
	
	[[self controlView] setNeedsDisplay: YES]; 
}

#pragma mark -
- (NSSize) cellSize {
	return NSMakeSize(16, 16); 
}

#pragma mark -
#pragma mark Drawing 

- (void) drawWithFrame: (NSRect) cellFrame inView: (NSView*) controlView {
	if (([self state] == NSOffState) && (mMouseInside == NO)) {
		[[NSColor clearColor] set]; 
		[NSBezierPath fillRect: cellFrame]; 
		
		// and continue with innards
		[super drawWithFrame: cellFrame inView: controlView]; 	
    
		return; 
	}
	
	NSRect frame = cellFrame; 	
	frame.origin.x += 0.5; 
	frame.origin.y += 0.5; 
	frame.size.width -= 0.5; 
	frame.size.height -= 0.5; 
	NSBezierPath* backgroundPath = [NSBezierPath bezierPathForRoundedRect: frame withRadius: 3]; 
  
	// draw background 
	if (([self isHighlighted]) || ([self state] == NSOnState)) {
		if (mType == TAUIColorLabelType) 
			[[NSColor colorWithCalibratedWhite: 1.0 alpha: 1.0] set]; 
		else
			[[NSColor clearColor] set]; 
	}
	else
		[[NSColor colorWithCalibratedWhite: 0.8 alpha: 1.0] set];
  
	[backgroundPath fill]; 
	
	// draw border 
	if (([self isHighlighted]) || ([self state] == NSOnState)) {
		if (mType == TAUIColorLabelType) 
			[[NSColor colorWithCalibratedWhite: 0.8 alpha: 1.0] set]; 
		else
			[[NSColor clearColor] set]; 
	}
	else
		[[NSColor colorWithCalibratedWhite: 0.7 alpha: 1.0] set]; 
	
	[backgroundPath setLineWidth: 1.0]; 
	[backgroundPath stroke];
	
	// and continue with innards
	[super drawWithFrame: cellFrame inView: controlView]; 	
}

- (void) drawInteriorWithFrame: (NSRect) cellFrame inView: (NSView*) controlView {
  // Don't draw a background for the clear button
	if (mType == TAUIClearLabelType) {
		NSPoint imagePosition = cellFrame.origin; 
		imagePosition.x += 3; 
		imagePosition.y += 2.5 + [mImage size].height;     
		
		[mImage compositeToPoint: imagePosition operation: NSCompositeSourceOver fraction: 1.0]; 
		
		return; 
	}
	
	NSRect			blobPathRect; 
	NSPoint			blobImagePosition; 
	blobPathRect.origin = NSMakePoint(cellFrame.origin.x + 3, cellFrame.origin.y + 3); 
	blobPathRect.size   = NSMakeSize(9,9);
	blobImagePosition   = NSMakePoint(blobPathRect.origin.x, blobPathRect.origin.y + [mImage size].height); 
  
	NSBezierPath* blobPath = [NSBezierPath bezierPathWithOvalInRect: blobPathRect]; 
		
	NSShadow* shadow = [[[NSShadow alloc] init] autorelease];
  
	[shadow setShadowColor: [[NSColor shadowColor] colorWithAlphaComponent: 0.2]];
	[shadow setShadowBlurRadius: 1];
	[shadow setShadowOffset:NSMakeSize(0,-1.2)];
	
	[NSGraphicsContext saveGraphicsState]; 	
	[shadow set]; 
	// draw the blob
	[mColor set];
	[blobPath fill];
  [[[NSColor whiteColor] colorWithAlphaComponent: 0.1] set];
  [blobPath fill];
  [[[NSColor shadowColor] colorWithAlphaComponent: 0.2] set];
  [blobPath setLineWidth: 0.5];
  [blobPath stroke];
	[NSGraphicsContext restoreGraphicsState]; 
  
  // draw our specular highlight and border with shadow 
  [mImage dissolveToPoint: blobImagePosition fraction: 0.55];
}
@end
