/******************************************************************************
* 
* Virtue 
*
* A desktop extension for MacOS X
*
* Copyright 2004, Thomas Staller 
* playback@users.sourceforge.net
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
