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

#import "VTTransformerDesktopNameDescriptor.h"
#import "VTDesktop.h" 


@implementation VTTransformerDesktopNameDescriptor

#pragma mark -
#pragma mark Class methods 

+ (Class) transformedValueClass
{
    return [VTDesktop class];
}

+ (BOOL) allowsReverseTransformation
{
    return NO;
}

#pragma mark Lifetime 

- (id) init {
	if (self = [super init]) {
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	[super dealloc]; 
}

#pragma mark -
#pragma mark NSValueTransformer implementation

- (id) transformedValue: (id) aDesktop {
	// we transform the desktop by extracting the name and applications and return a nicely 
	// formatted attributed string to display 
	NSDictionary* desktopDescriptorAttr = nil; 
	if ([aDesktop visible]) {
		desktopDescriptorAttr = [NSDictionary dictionaryWithObjectsAndKeys: 
			[NSFont boldSystemFontOfSize: [NSFont systemFontSize]], NSFontAttributeName, 
			nil]; 
	}
	
	NSMutableAttributedString* desktopDescriptor = [[[NSMutableAttributedString alloc] initWithString: [aDesktop name] attributes: desktopDescriptorAttr] autorelease]; 

	NSNumber* applicationCount			= [NSNumber numberWithInt: [[aDesktop applications] count]]; 
	NSString* applicationCountString	= [applicationCount intValue] == 0 ? @"no" : [applicationCount stringValue]; 
	NSString* applicationString			= [applicationCount intValue] == 1 ? @"application" : @"applications"; 
	
	NSString* applicationDescr			= [NSMutableString stringWithFormat: @"\nShowing %@ %@", applicationCountString, applicationString]; 
	
	// assemble attributed string describing applications open 
	NSDictionary* applicationDescriptorAttr		= [NSDictionary dictionaryWithObjectsAndKeys: 
		[NSFont labelFontOfSize: [NSFont labelFontSize]], NSFontAttributeName,
		[NSColor lightGrayColor], NSForegroundColorAttributeName, 
		nil]; 
	NSAttributedString* applicationDescriptor	= [[[NSMutableAttributedString alloc] initWithString: applicationDescr attributes: applicationDescriptorAttr] autorelease]; 

	// assemble compound string 
	[desktopDescriptor appendAttributedString: applicationDescriptor]; 

	return desktopDescriptor; 
}



@end
