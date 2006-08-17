/******************************************************************************
* 
* VirtueDesktops 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller playback@users.sourceforge.net
* Copyright 2005-2006, Tony Arnold tony@tonyarnold.com
*
* See COPYING for licensing details
* 
*****************************************************************************/ 

#import "VTHotkeyTextField.h"
#import "VTHotkeyCell.h" 

@implementation VTHotkeyTextField

+ (Class) cellClass {
	return [VTHotkeyCell class]; 
}

@end
