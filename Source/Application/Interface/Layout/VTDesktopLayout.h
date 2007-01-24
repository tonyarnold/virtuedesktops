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
#import "VTPager.h" 
#import "VTDesktop.h" 
#import "VTCoding.h" 
#import <Peony/Peony.h> 

// types 
typedef enum {
	kVtDirectionNone		= FOUR_CHAR_CODE('DRno'),
	kVtDirectionNorth		= FOUR_CHAR_CODE('DRn '), 
	kVtDirectionEast		= FOUR_CHAR_CODE('DRe '), 
	kVtDirectionSouth		= FOUR_CHAR_CODE('RDs '),
	kVtDirectionWest		= FOUR_CHAR_CODE('RDw '), 
	kVtDirectionNortheast	= FOUR_CHAR_CODE('RDne'),
	kVtDirectionSoutheast	= FOUR_CHAR_CODE('RDse'),
	kVtDirectionSouthwest	= FOUR_CHAR_CODE('RDsw'),
	kVtDirectionNorthwest	= FOUR_CHAR_CODE('RDnw'), 
} VTDirection; 

#pragma mark -
@interface VTDesktopLayout : NSObject<VTCoding> {
	NSString* mName; 
}

#pragma mark -
#pragma mark Lifetime 
- (id) initWithName: (NSString*) name; 
- (void) dealloc; 

#pragma mark -
#pragma mark Attributes 
- (NSString*) name; 
#pragma mark -
- (NSObject<VTPager>*) pager; 
- (NSArray*) availablePagers;
- (NSArray*) desktops; 
- (NSArray*) orderedDesktops; 
- (unsigned int) maximumNumberOfDesktops;

#pragma mark -
#pragma mark Queries 
- (VTDesktop*) desktopInDirection: (VTDirection) direction ofDesktop: (VTDesktop*) desktop; 
- (VTDirection) directionFromDesktop: (VTDesktop*) referenceDesktop toDesktop: (VTDesktop*) desktop; 


@end
