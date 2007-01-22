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

#import "VTImageViewFileDropper.h"
#import <Zen/Zen.h> 


@implementation VTImageViewFileDropper

+ (void) initialize {
	[VTImageViewFileDropper exposeBinding: @"imagePath"];
}

#pragma mark -
#pragma mark Lifetime 
- (id) init {
	if (self = [super init]) {
		// attributes 
		mPath = nil; 
		// set up drag target by registering 
		[self registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
		
		return self; 
	}
	
	return nil; 
}

- (void) dealloc {
	// attributes 
	ZEN_RELEASE(mPath); 
	
	[super dealloc]; 
}

#pragma mark -
#pragma mark Attribute
- (void) setImagePath: (NSString*) path {
	// setting attribute 
	ZEN_ASSIGN_COPY(mPath, path); 
	
	// setting the image
	[super setImage: [[[NSImage alloc] initByReferencingFile: mPath] autorelease]];
}

- (NSString*) imagePath {
	return mPath; 
}

#pragma mark -
#pragma mark NSDraggingDestination 

- (NSDragOperation) draggingEntered:(id<NSDraggingInfo>) sender {	
	return NSDragOperationLink; 
}

- (void) concludeDragOperation: (id<NSDraggingInfo>) sender { 
	NSString* path = [[[sender draggingPasteboard] propertyListForType: NSFilenamesPboardType] objectAtIndex: 0]; 
	
	// set the path 
	[self willChangeValueForKey: @"imagePath"]; 
	[self setImagePath: path]; 
	[self didChangeValueForKey: @"imagePath"]; 
}

@end
