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

#import "VTDesktopScripting.h"
#import "VTDesktopController.h"
#import "VTScriptPlugin.h" 


@implementation VTDesktop(VTScripting)

- (NSNumber*) uniqueIdentifier {
	return [NSNumber numberWithUnsignedInt: (unsigned int)self]; 
}

- (NSScriptObjectSpecifier*) objectSpecifier {
	NSScriptObjectSpecifier* containerRef = [[VTDesktopController sharedInstance] objectSpecifier]; 
  return [[[NSUniqueIDSpecifier alloc] initWithContainerClassDescription:[containerRef keyClassDescription] containerSpecifier: containerRef key:@"desktops" uniqueID:[self uuid]] autorelease];
}

#pragma mark -
#pragma mark Scripting Commands 

- (void) activateDesktopCommand: (NSScriptCommand*) command {
	// trigger activation via the desktop controller, that will take care of checks 
	[[VTDesktopController sharedInstance] activateDesktop: self]; 
}


#pragma mark -
#pragma mark Scripting Compatible Initializers

- (id) init {
	if (self = [self initWithName: nil identifier: [[VTDesktopController sharedInstance] freeId]]) {
		[self setName: [NSString stringWithFormat: @"Desktop %i", [self identifier]]]; 
		
		return self; 
	}
	
	return nil; 
}

@end

@interface VTScriptPlugin (VTChangeDesktop)
@end 

@implementation VTScriptPlugin(VTChangeDesktop) 

- (void) onDesktopWillActivateNotification: (VTDesktop*) desktop {
	NSDictionary* args = [NSDictionary dictionaryWithObjectsAndKeys: desktop, @"----", nil];
	[self callScriptHandler: FOUR_CHAR_CODE('Vowa') withArguments: args forSelector: _cmd];
}

- (void) onDesktopDidActivateNotification: (VTDesktop*) desktop {
	NSDictionary* args = [NSDictionary dictionaryWithObjectsAndKeys: desktop, @"----", nil];
	[self callScriptHandler: FOUR_CHAR_CODE('Voda') withArguments: args forSelector: _cmd];
}

- (void) onDesktopDidCreateNotification: (VTDesktop*) desktop {
	NSDictionary* args = [NSDictionary dictionaryWithObjectsAndKeys: desktop, @"----", nil];
	[self callScriptHandler: FOUR_CHAR_CODE('Vodc') withArguments: args forSelector: _cmd];
}

- (void) onDesktopWillDeleteNotification: (VTDesktop*) desktop {
	NSDictionary* args = [NSDictionary dictionaryWithObjectsAndKeys: desktop, @"----", nil];
	[self callScriptHandler: FOUR_CHAR_CODE('Vowd') withArguments: args forSelector: _cmd];
}

@end 
