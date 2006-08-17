/******************************************************************************
* 
* Peony.Virtue 
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
#import "../PNDesktop.h" 


@interface PNDesktop(PNScripting)
#pragma mark -
#pragma mark Enumeration Translation 

- (PNTransitionType) typeToNative: (unsigned int) scriptingType; 
- (PNTransitionOption) optionToNative: (unsigned int) scriptingOption; 

@end
