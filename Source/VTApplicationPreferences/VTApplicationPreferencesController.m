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

#import "VTApplicationPreferencesController.h"
#import "VTPreferences.h"

@interface VTApplicationPreferencesController(LoginItem)
- (BOOL) _isLoginItem; 
- (void) _addLoginItem;
- (void) _removeLoginItem; 
- (NSMutableArray*) _loginItemsList; 
- (void) _writeLoginItemsList: (NSMutableArray*) list;
@end 

#pragma mark -
@implementation VTApplicationPreferencesController

- (IBAction) toggleModifier: (id) sender {
	int state			= [sender state]; 
	int modifiers	= [[NSUserDefaults standardUserDefaults] integerForKey: VTDesktopFollowsApplicationFocusModifier]; 
	int modifier	= 0; 
		
	// handle different buttons 
	if ([sender isEqual: mShiftButton])
		modifier = NSShiftKeyMask; 
	else if ([sender isEqual: mControlButton]) 
		modifier = NSControlKeyMask; 
	else if ([sender isEqual: mAlternateButton]) 
		modifier = NSAlternateKeyMask; 
	else if ([sender isEqual: mCommandButton])
		modifier = NSCommandKeyMask; 
	
	if (state == NSOnState) 
		modifiers |= modifier; 
	else
		modifiers ^= modifier; 
	
	[[NSUserDefaults standardUserDefaults] setInteger: modifiers forKey: VTDesktopFollowsApplicationFocusModifier]; 
}

- (void) mainViewDidLoad {
	int modifiers = [[NSUserDefaults standardUserDefaults] integerForKey: VTDesktopFollowsApplicationFocusModifier]; 	
	
	// set up buttons 
	[mCommandButton setState: (modifiers & NSCommandKeyMask) ? NSOnState : NSOffState]; 
	[mAlternateButton setState: (modifiers & NSAlternateKeyMask) ? NSOnState : NSOffState]; 
	[mShiftButton setState: (modifiers & NSShiftKeyMask) ? NSOnState : NSOffState]; 
	[mControlButton setState: (modifiers & NSControlKeyMask) ? NSOnState : NSOffState]; 
}

#pragma mark -
#pragma mark Attributes 
- (BOOL) isLoginItem {
	return [self _isLoginItem]; 
}

- (void) setLoginItem: (BOOL) flag {
	if (flag) 
		[self _addLoginItem]; 
	else
		[self _removeLoginItem]; 
}

@end

@implementation VTApplicationPreferencesController(LoginItem)
- (BOOL) _isLoginItem {
	// fetch the loginwindow item list and remove our entry if found 
	NSMutableArray* loginItemsList	= [self _loginItemsList]; 
	
	NSEnumerator*	loginItemsIter	= [loginItemsList objectEnumerator]; 
	NSDictionary*	loginItem		= nil; 
	NSString*		path			= [[NSBundle mainBundle] bundlePath]; 
	
	while (loginItem = [loginItemsIter nextObject]) {
		if ([[loginItem objectForKey: @"Path"] isEqualToString: path])
			return YES; 
	}	
	
	return NO; 
}

- (void) _addLoginItem {
	// create our descriptor containing mandatory keys 
	NSDictionary* loginItemDictionary = [NSDictionary dictionaryWithObjectsAndKeys: 
		[NSNumber numberWithBool: YES], @"Hide", 
		[[NSBundle mainBundle] bundlePath], @"Path", 
		// Done 
		nil]; 
	
	// now fetch the loginwindow dictionary and add our new entry if it is not in
	// there yet, in which case we do not do anything 
	NSMutableArray* loginItemsList	= [self _loginItemsList];
	// try to find our item in there 
	NSEnumerator*	loginItemsIter	= [loginItemsList objectEnumerator]; 
	NSDictionary*	loginItem		= nil; 
	NSString*		path			= [[NSBundle mainBundle] bundlePath]; 
	
	while (loginItem = [loginItemsIter nextObject]) {
		if ([[loginItem objectForKey: @"Path"] isEqualToString: path])
			return; 
	}
	
	// add the item
	[loginItemsList addObject: loginItemDictionary]; 
	// and save it back 
	[self _writeLoginItemsList: loginItemsList]; 
}

- (void) _removeLoginItem {
	// fetch the loginwindow item list and remove our entry if found 
	NSMutableArray* loginItemsList	= [self _loginItemsList]; 
	
	NSEnumerator*	loginItemsIter	= [loginItemsList objectEnumerator]; 
	NSDictionary*	loginItem		= nil; 
	NSString*		path			= [[NSBundle mainBundle] bundlePath]; 
	
	while (loginItem = [loginItemsIter nextObject]) {
		if ([[loginItem objectForKey: @"Path"] isEqualToString: path])
			break; 
	}
	
	// no login item, nothing to remove 
	if (loginItem == nil)
		return; 
	
	// remove and persist
	[loginItemsList removeObject: loginItem]; 
	[self _writeLoginItemsList: loginItemsList]; 
}

- (NSMutableArray*) _loginItemsList {
	NSMutableArray* loginItems; 
	
	loginItems = (NSMutableArray*)CFPreferencesCopyValue((CFStringRef)@"AutoLaunchedApplicationDictionary", (CFStringRef)@"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	return [[[loginItems autorelease] mutableCopy] autorelease];
}

- (void) _writeLoginItemsList: (NSMutableArray*) list {
	CFPreferencesSetValue((CFStringRef)@"AutoLaunchedApplicationDictionary", list, (CFStringRef)@"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	CFPreferencesSynchronize((CFStringRef)@"loginwindow", kCFPreferencesCurrentUser, kCFPreferencesAnyHost); 	
}

@end 
