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


@interface VTDecorationPrimitiveText : VTDecorationPrimitive {
	NSString*             mText;
	NSFont*               mFont; 
  NSMutableDictionary*  mFontAttributes;
  NSShadow*             mFontShadow;
  NSColor*              mFontColor;
}

#pragma mark -
#pragma mark Lifetime 

- (id) init; 

#pragma mark -
#pragma mark Attributes 

- (NSString*) text; 
- (void) setText: (NSString*) text; 

#pragma mark -
- (NSString*) fontName; 
- (NSFont*) font; 
- (void) setFont: (NSFont*) font; 

#pragma mark -
- (NSDictionary*) fontAttributes;

#pragma mark -
- (float) fontSize;

#pragma mark -
- (NSShadow*) fontShadow;
- (void) setFontShadow: (NSShadow*) fontShadow;

#pragma mark -
- (NSColor*) fontColor;
- (void) setFontColor: (NSColor*) fontColor;

@end
