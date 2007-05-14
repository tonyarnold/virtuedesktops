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

#import "VTAppearancePreferencesController.h"
#import <Growl/Growl.h>

#pragma mark -
@implementation VTAppearancePreferencesController

#pragma mark -
#pragma mark NSPreferencePane Delegate 

- (void) mainViewDidLoad {
}

- (void) willUnselect {
}

- (BOOL)growlIsUsable
{
  return YES;
  // This was crashing
  // return (Growl_IsInstalled() == YES && Growl_IsRunning() == YES);
}

@end 

