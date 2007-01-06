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

#pragma mark -
#pragma mark Internal 

// Notification that a hotkey was pressed 
#define kVtNotificationOnKeyPress       @"VT_NOTIFICATION_KEY_PRESS"

// Notification that a hotkey was registered 
#define kVtNotificationWasRegistered    @"VT_NOTIFICATION_REGISTERED" 
// Notification that a hotkey was unregistered 
#define kVtNotificationWasUnregistered	@"VT_NOTIFICATION_UNREGISTERED"


#pragma mark -
#pragma mark Mouse Watcher notifications 

// Notification that one or many tracking rectangle was entered 
#define kVtNotificationOnMouseEntered	@"VT_NOTIFICATION_MOUSE_ENTERED"
#define kVtNotificationOnMouseEnteredParam	@"VT_TRACKING_RECTS"

#pragma mark -
#pragma mark Desktop Requests 

// Request a change of desktop
#define VTRequestChangeDesktopName          @"VTRequestChangeDesktop"
#define VTRequestChangeDesktopParamName     @"VTRequestChangeDesktopTarget"
// Request to snap back to snap back target desktop 
#define VTRequestChangeDesktopToSnapbackName	@"VTRequestChangeDesktopToSnapback"
// Request to set current desktop as snapback desktop
#define VTRequestSetSnapbackDesktopName		@"VTRequestSetSnapbackDesktop"
// REquest to change to last active desktop 
#define VTRequestChangeDesktopToLastName	@"VTRequestChangeDesktopToLast"
// Request to change to the next desktop
#define VTRequestChangeDesktopToEastName	@"VTRequestChangeDesktopToEast"
// Request to change to the previous desktop 
#define VTRequestChangeDesktopToWestName	@"VTRequestChangeDesktopToWest"
// Request to change to the desktop above 
#define VTRequestChangeDesktopToNorthName	@"VTRequestChangeDesktopToNorth"
// Request to change to the desktop below 
#define VTRequestChangeDesktopToSouthName	@"VTRequestChangeDesktopToSouth"

#define VTRequestChangeDesktopToNortheastName	@"VTRequestChangeDesktopToNortheast"
#define VTRequestChangeDesktopToNorthwestName	@"VTRequestChangeDesktopToNorthwest"

#define VTRequestChangeDesktopToSoutheastName	@"VTRequestChangeDesktopToSoutheast"
#define VTRequestChangeDesktopToSouthwestName	@"VTRequestChangeDesktopToSouthwest"

// Request to display the overlay window 
#define VTRequestDisplayOverlayName			@"VTRequestDisplayOverlay"

// Request deletion of the current desktop 
#define VTRequestDeleteDesktopName			@"VTRequestDeleteDesktop"

// Request selection of the new show desktop via the overlay pager 
#define VTRequestShowPagerName            @"VTRequestShowPager"
// request a sticky overlay pager 
#define VTRequestShowPagerAndStickName		@"VTRequestShowPagerAndStick"

//
#define VTRequestApplicationMoveToEast			@"VTRequestApplicationMoveToEast"
//
#define VTRequestApplicationMoveToWest			@"VTRequestApplicationMoveToWest"
//
#define VTRequestApplicationMoveToSouth			@"VTRequestApplicationMoveToSouth"
//
#define VTRequestApplicationMoveToNorth			@"VTRequestApplicationMoveToNorth"

// Request to send window behind other windows
#define VTRequestSendWindowBackName         @"VTRequestSendWindowBack"

// Move windows to desktops
#define VTRequestMoveWindowLeft             @"VTRequestMoveWindowLeft"
#define VTRequestMoveWindowRight            @"VTRequestMoveWindowRight"
#define VTRequestMoveWindowUp               @"VTRequestMoveWindowUp"
#define VTRequestMoveWindowDown             @"VTRequestMoveWindowDown"

#pragma mark -
#pragma mark Window open Requests 

// Request to show the desktops inspector 
#define VTRequestInspectDesktopsName		@"VTRequestInspectDesktops"
// Request to show the desktop inspector 
#define VTRequestInspectDesktopName			@"VTRequestInspectDesktop"
// Request to show the application inspector 
#define VTRequestInspectApplicationsName	@"VTRequestInspectApplications"
// Request to show the preferences window 
#define VTRequestInspectPreferencesName		@"VTRequestInspectPreferences"
// Request to toggle the statusbar menu on/off
#define VTRequestToggleStatusbarMenuName	@"VTRequestToggleStatusbarMenu"

#pragma mark -
#pragma mark Desktop events 

#define VTDesktopWillAddNotification	@"VTDesktopWillAddNotification"
#define VTDesktopDidAddNotification		@"VTDesktopDidAddNotification"
#pragma mark -
#define VTDesktopWillRemoveNotification	@"VTDesktopWillRemoveNotification"
#define VTDesktopDidRemoveNotification	@"VTDesktopDidRemoveNotification"

#pragma mark -
#pragma mark Application Wrapper Events
#define kVtNotificationApplicationWrapperOptionsChanged @"kVtNotificationApplicationWrapperOptionsChanged"

