/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2007, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTDesktopColorLabelPrimitive.h"
#import "VTDesktopDecoration.h"
#import "VTDesktop.h"
#import <Zen/Zen.h> 

#define kVtCodingIntensity	@"intensity"

@implementation VTDesktopColorLabelPrimitive

#pragma mark -
#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		mName = @"Desktop Color Label Primitive"; 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	// bindings 
	[self unbind: @"color"]; 
	// super... 
	[super dealloc]; 
}

#pragma mark -
#pragma mark Coding 

- (id) initWithCoder: (NSCoder*) coder {
	if (self = [super initWithCoder: coder]) {
		// set up binding 
		if (([self container]) && ([[self container] desktop]))
			[self bind: @"color" toObject: [[self container] desktop] withKeyPath: @"colorLabel" options: nil]; 	
		
		return self; 
	}
	
	return nil; 
}

- (void) encodeWithCoder: (NSCoder*) coder {
	[super encodeWithCoder: coder]; 
}

#pragma mark -
#pragma makr Coding 
- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
	[super encodeToDictionary: dictionary]; 
	
	[dictionary setObject: [NSNumber numberWithFloat: mIntensity] forKey: kVtCodingIntensity]; 
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	if (self = [super decodeFromDictionary: dictionary]) { 
		if ([dictionary objectForKey: kVtCodingIntensity] == nil)
			mIntensity = 1.0; 
		else
			mIntensity = [[dictionary objectForKey: kVtCodingIntensity] floatValue]; 
		
		return self; 
	}
	
	return nil; 
}

#pragma mark -
#pragma mark VTDecorationPrimitiveTint overrides
- (void) setColor: (NSColor*) color {
	// we are hijacking the transparency setting to use our own 
	ZEN_ASSIGN(mColor, [color colorWithAlphaComponent: mIntensity]);
	[self setNeedsDisplay]; 
}

#pragma mark -
#pragma mark VTDecorationPrimitive overrides 

- (void) setContainer: (VTDesktopDecoration*) container {
	// first remove any existing binding
	[self unbind: @"color"]; 
	// trigger call to super 
	[super setContainer: container]; 
	
	// and attach to the desktop inside the container 
	if ((container != nil) && ([container desktop] != nil))
		[self bind: @"color" toObject: [[self container] desktop] withKeyPath: @"colorLabel" options: nil]; 	
	else
		[self setColor: [NSColor clearColor]]; 
}

@end
