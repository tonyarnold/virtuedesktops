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

#import "VTDesktopLayout.h"
#import <Zen/ZNMemoryManagementMacros.h> 

@implementation VTDesktopLayout

#pragma mark -
#pragma mark Lifetime 

- (id) initWithName: (NSString*) name {
	if (self = [super init]) {
		// attributes 
		ZEN_ASSIGN_COPY(mName, name); 
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	ZEN_RELEASE(mName); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Coding 

- (void) encodeToDictionary: (NSMutableDictionary*) dictionary {
}

- (id) decodeFromDictionary: (NSDictionary*) dictionary {
	return self; 
}

#pragma mark -
#pragma mark Attributes 

- (NSString*) name {
	return mName; 
}

#pragma mark -
- (NSObject<VTPager>*) pager {
	// please override me to return a pager instance 
	return nil; 
}

- (NSArray*) availablePagers {
  return nil;
}

- (NSArray*) desktops { 
	// please override me to return all desktops in the correct order
	return nil; 
}

- (NSArray*) orderedDesktops { 
	// please override me to return all desktops in the correct order
	return nil; 
}

- (unsigned int) maximumNumberOfDesktops {
	return [[self desktops] count];
}

#pragma mark -
#pragma mark Queries 

- (VTDesktop*) desktopInDirection: (VTDirection) direction ofDesktop: (VTDesktop*) desktop {
	return nil; 
}

- (VTDirection) directionFromDesktop: (VTDesktop*) referenceDesktop toDesktop: (VTDesktop*) desktop {
	return kVtDirectionNone; 
}

@end
