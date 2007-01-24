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
#import "VTCoding.h" 

@class VTDesktopDecoration; 

// types 
typedef enum {
	kVtDecorationPositionAbsolute	= FOUR_CHAR_CODE('PTab'), 
	kVtDecorationPositionLL			= FOUR_CHAR_CODE('PTll'), 
	kVtDecorationPositionLR			= FOUR_CHAR_CODE('PTlr'),
	kVtDecorationPositionTL			= FOUR_CHAR_CODE('PTtl'),
	kVtDecorationPositionTR			= FOUR_CHAR_CODE('PTtr'),
	kVtDecorationPositionLeft		= FOUR_CHAR_CODE('PTl '),
	kVtDecorationPositionRight	= FOUR_CHAR_CODE('PTr '), 
	kVtDecorationPositionTop		= FOUR_CHAR_CODE('PTt '),
	kVtDecorationPositionBottom	= FOUR_CHAR_CODE('PTb '), 
  kVtDecorationPositionCenter = FOUR_CHAR_CODE('PTc '),
} VTDecorationPosition; 

@interface VTDecorationPrimitive : NSObject<NSCoding, NSCopying, VTCoding> {
	NSString*				mName; 
	VTDesktopDecoration*	mContainer; 
	BOOL					mEnabled; 
	// positional attributes 
	VTDecorationPosition	mPositionType; 
	NSPoint					mPosition; 
	// drawing 
	NSView*					mControlView; 
}

#pragma mark -
#pragma mark Lifetime 

- (id) init; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (void) setName: (NSString*) name; 
- (NSString*) name; 
#pragma mark -
- (void) setContainer: (VTDesktopDecoration*) container; 
- (VTDesktopDecoration*) container; 
#pragma mark -
- (NSView*) controlView; 
- (void) setControlView: (NSView*) view; 
#pragma mark -
- (NSRect) bounds; 
#pragma mark -
- (void) setPosition: (NSPoint) position; 
- (NSPoint) position; 
#pragma mark -
- (void) setPositionType: (VTDecorationPosition) positionType; 
- (VTDecorationPosition) positionType; 
- (NSArray*) supportedPositionTypes; 
#pragma mark -
- (BOOL) shouldDraw; 
- (BOOL) isEnabled; 
- (void) setEnabled: (BOOL) flag; 

#pragma mark -
#pragma mark Drawing 

- (void) setNeedsDisplay; 
- (void) drawInView: (NSView*) view withRect: (NSRect) rect; 

@end
