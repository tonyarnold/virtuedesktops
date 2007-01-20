//
//  NSStringWithModifiers.m
//  Zen framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import <Carbon/Carbon.h> 
#import "NSString+Modifiers.h" 

@implementation NSString(ZNKeyModifiers)

+ (NSString*) unicodeToString: (unichar) character {
	return [NSString stringWithCharacters: &character length: 1]; 
}

+ (NSString*) stringWithModifiers: (int) keyModifiers {
	NSMutableString* stringValue = [NSMutableString string];
	
	// handle modifiers and append them to the resulting string representation
	if (keyModifiers & NSControlKeyMask) 
		[stringValue appendString: [NSString unicodeToString: kControlUnicode]]; 
	if (keyModifiers & NSShiftKeyMask) 
		[stringValue appendString: [NSString unicodeToString: kShiftUnicode]]; 			
	if (keyModifiers & NSAlternateKeyMask) 
		[stringValue appendString: [NSString unicodeToString: kOptionUnicode]]; 			
	if (keyModifiers & NSCommandKeyMask) 
		[stringValue appendString: [NSString unicodeToString: kCommandUnicode]]; 			
	
	return [NSString stringWithString: stringValue]; 
}

@end
