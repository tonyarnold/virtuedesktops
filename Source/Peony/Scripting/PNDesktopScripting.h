//
//  PNDesktopScripting.h
//  Peony framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

#import <Cocoa/Cocoa.h>
#import "../PNDesktop.h"

@interface PNDesktop(PNScripting)
#pragma mark -
#pragma mark Enumeration Translation 

- (PNTransitionType) typeToNative: (unsigned int) scriptingType; 
- (PNTransitionOption) optionToNative: (unsigned int) scriptingOption; 

@end
