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

#import <Cocoa/Cocoa.h>
#import "VTDecorationPrimitive.h" 


@interface VTDecorationPrimitiveText : VTDecorationPrimitive {
	NSString*	mText; 
	// primitives 
	NSFont*		mFont; 
	NSColor*	mColor;
	BOOL		mDisplaysShadow; 
	// text attributes 
	NSMutableDictionary* mTextAttributes; 
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
- (float) fontSize; 

#pragma mark -
- (NSColor*) color; 
- (void) setColor: (NSColor*) color; 

#pragma mark -
- (BOOL) displaysShadow; 
- (void) setDisplaysShadow: (BOOL) flag; 

@end
