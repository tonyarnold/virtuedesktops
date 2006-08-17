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

#import "NSColorString.h"


@implementation NSColor (VTString)

+ (NSColor*) colorWithString: (NSString*) string {
	if (string == nil)
		return nil; 
	
	NSScanner* colorScanner = [NSScanner scannerWithString: string]; 
	[colorScanner setCharactersToBeSkipped: [NSCharacterSet characterSetWithCharactersInString: @"{} ,"]]; 
	
	float r; 
	float g; 
	float b; 
	float a; 
	
	BOOL success = NO; 
	
	if ([colorScanner scanFloat: &r] == NO)
		return nil; 
	if ([colorScanner scanFloat: &g] == NO)
		return nil; 
	if ([colorScanner scanFloat: &b] == NO)
		return nil; 
	if ([colorScanner scanFloat: &a] == NO)
		return nil; 
	
	return [NSColor colorWithCalibratedRed: r
									 green: g
									  blue: b
									 alpha: a]; 
}

- (NSString*) stringValue {
	// ensure we are in the rgb colorspace 
	NSColor* color = [self colorUsingColorSpaceName: NSCalibratedRGBColorSpace]; 
	// translate to a string 
	return [NSString stringWithFormat: @"{%.2f, %.2f, %.2f, %.2f}", 
				[color redComponent], 
				[color greenComponent],  
				[color blueComponent],
				[color alphaComponent]]; 
}

@end
