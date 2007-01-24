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

#import "VTDesktopDecorationScripting.h"
#import "VTDesktop.h"

@implementation VTDesktopDecoration(VTScripting)

- (NSNumber*) uniqueIdentifier {
	return [NSNumber numberWithUnsignedInt: (unsigned int)self]; 
}

/**
 * VTDesktopDecoration Object Specifier
 *
 * VTDesktopDecoration are bound to a specific desktop as their container under the 
 * the key 'decoration'. 
 *
 */ 
- (NSScriptObjectSpecifier*) objectSpecifier {
	id							classDescription	= [NSClassDescription classDescriptionForClass: [VTDesktop class]]; 
	NSScriptObjectSpecifier*	container			= [[self desktop] objectSpecifier]; 
	
	return [[[NSPropertySpecifier alloc] initWithContainerClassDescription: classDescription containerSpecifier: container key: @"decoration"] autorelease];
}

- (VTDecorationPrimitive*) valueInDecorationPrimitivesWithName: (NSString*) name {
	// we have to iterate and find us the passed name inside our container 
	NSEnumerator*			primitiveIter	= [mDecorationPrimitives objectEnumerator]; 
	VTDecorationPrimitive*	primitive		= nil; 
	
	while (primitive = [primitiveIter nextObject]) {
		if ([[primitive name] isEqualToString: name]) 
			return primitive; 
	}
	
	return nil; 
}


@end
