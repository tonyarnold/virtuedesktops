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
* Partially based on the Colloquy project
* http://www.colloquy.info
* 
*****************************************************************************/ 

#import "VTScriptPlugin.h"
#import <Zen/Zen.h> 

#pragma mark -
#pragma mark Private Cocoa interfaces 

@interface NSScriptObjectSpecifier (NSScriptObjectSpecifierPrivate)
+ (id) _objectSpecifierFromDescriptor:(NSAppleEventDescriptor *) descriptor inCommandConstructionContext:(id) context;
- (NSAppleEventDescriptor *) _asDescriptor;
@end

#pragma mark -
@interface NSAEDescriptorTranslator : NSObject
+ (id) sharedAEDescriptorTranslator;
- (NSAppleEventDescriptor *) descriptorByTranslatingObject:(id) object ofType:(id) type inSuite:(id) suite;
- (id) objectByTranslatingDescriptor:(NSAppleEventDescriptor *) descriptor toType:(id) type inSuite:(id) suite;
- (void) registerTranslator:(id) translator selector:(SEL) selector toTranslateFromClass:(Class) class;
- (void) registerTranslator:(id) translator selector:(SEL) selector toTranslateFromDescriptorType:(unsigned int) type;
@end

#pragma mark -
@interface NSString (VTFourCharCode)
- (unsigned long) fourCharCode;
@end

#pragma mark -
@interface VTScriptPlugin(Loading) 
- (void) loadScript: (NSString*) scriptSource; 
@end 

#pragma mark -
@implementation VTScriptPlugin

#pragma mark -
#pragma mark Lifetime 
- (id) initWithScript: (NSString*) scriptSource {
	if (self = [super init]) {
		[self loadScript: scriptSource]; 
		
		if (mScript == nil) {
			[self autorelease]; 
			return nil; 
		}
		
		// create array of ignored selectors 
		mIgnoredSelectors = [[NSMutableArray alloc] init]; 		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mScript); 
	ZEN_RELEASE(mIgnoredSelectors); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attributes 
- (NSAppleScript*) script {
	return mScript; 
}

- (NSArray*) selectorsRequestedForIgnoring {
	return mIgnoredSelectors; 
}

#pragma mark -
#pragma mark Handlers 
- (id) callScriptHandler: (unsigned long) handler withArguments: (NSDictionary*) arguments forSelector: (SEL) selector {
	if (mScript == nil) 
		return nil;
	
	int ourPid = [[NSProcessInfo processInfo] processIdentifier];
	
	NSAppleEventDescriptor* target	= [NSAppleEventDescriptor descriptorWithDescriptorType: typeKernelProcessID bytes: &ourPid length: sizeof(ourPid)];
	NSAppleEventDescriptor* event	= [NSAppleEventDescriptor appleEventWithEventClass: 'VTSS' eventID: handler targetDescriptor: target returnID: kAutoGenerateReturnID transactionID: kAnyTransactionID];
	
	NSEnumerator* argumentIter	= [arguments objectEnumerator];
	NSEnumerator* keyIter		= [arguments keyEnumerator];
	
	NSAppleEventDescriptor*	descriptor	= nil;
	NSString*				argumentKey	= nil;
	id						argument	= nil;
	
	while ((argumentKey = [keyIter nextObject]) && (argument = [argumentIter nextObject])) {
		NSScriptObjectSpecifier* specifier = nil;
		
		if ([argument isKindOfClass: [NSScriptObjectSpecifier class]]) 
			specifier = argument; 
		else 
			specifier = [argument objectSpecifier];
		
		if (specifier) 
			descriptor = [[argument objectSpecifier] _asDescriptor];
		else 
			descriptor = [[NSAEDescriptorTranslator sharedAEDescriptorTranslator] descriptorByTranslatingObject: argument ofType: nil inSuite: nil];
		
		if (descriptor == nil) 
			descriptor = [NSAppleEventDescriptor nullDescriptor];
		
		[event setDescriptor: descriptor forKeyword: [argumentKey fourCharCode]];
	}
	
	NSDictionary*			errorDictionary = nil;
	NSAppleEventDescriptor*	result = [mScript executeAppleEvent: event error: &errorDictionary];

	if ((errorDictionary) && (result == nil)) {
		int errorCode = [[errorDictionary objectForKey: NSAppleScriptErrorNumber] intValue];
		
		// if there was an error because the selector is not handled by the 
		// script, we mark the selector as ignored for future calls 
		if ((errorCode == errAEEventNotHandled) || (errorCode == errAEHandlerNotFound))
			[mIgnoredSelectors addObject: NSStringFromSelector(selector)];
		
		return [NSError errorWithDomain: NSOSStatusErrorDomain code: errorCode userInfo: errorDictionary];
	}
	
	if ([result descriptorType] == 'obj ' ) {
		NSScriptObjectSpecifier* specifier = [NSScriptObjectSpecifier _objectSpecifierFromDescriptor: result inCommandConstructionContext: nil];
		return [specifier objectsByEvaluatingSpecifier];
	}
	
	return [[NSAEDescriptorTranslator sharedAEDescriptorTranslator] objectByTranslatingDescriptor: result toType: nil inSuite: nil];
}

@end

#pragma mark -
@implementation NSString (VTFourCharCode)

- (unsigned long) fourCharCode {
	unsigned long result	= 0; 
	unsigned long length	= [self length];
	
	if (length >= 1) 
		result |= ([self characterAtIndex: 0] & 0x00ff) << 24;
	else 
		result |= ' ' << 24;
	
	if (length >= 2) 
		result |= ([self characterAtIndex: 1] & 0x00ff) << 16;
	else 
		result |= ' ' << 16;
	
	if (length >= 3) 
		result |= ([self characterAtIndex: 2] & 0x00ff) << 8;
	else 
		result |= ' ' << 8;
	
	if (length >= 4) 
		result |= ([self characterAtIndex: 3] & 0x00ff);
	else 
		result |= ' ';
	
	return result;
}
@end

#pragma mark -
@implementation VTScriptPlugin(Loading) 

- (void) loadScript: (NSString*) scriptSource {
	NSAppleScript* appleScript = [[[NSAppleScript alloc] initWithContentsOfURL: [NSURL fileURLWithPath: scriptSource] error: NULL] autorelease];

	// if we fail, we return 
	if (![appleScript compileAndReturnError: nil]) {
		ZNLog( @"failed compiling apple script from %@", scriptSource); 
		return; 
	}
				
	ZEN_ASSIGN(mScript, appleScript); 
}

@end 


