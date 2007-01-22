//
//  PNNotifications.h
//  Peony framework
//
//  Copyright 2004, Thomas Staller  <playback@users.sourceforge.net>
//  Copyright 2006-2007, Tony Arnold <tony@tonyarnold.com
//
//  See COPYING for licensing details
//  

// The desktop window list was updated 
#define kPnOnDesktopUpdated					@"PNDesktopWasUpdated"
#define PNDesktopWasUpdated					@"PNDesktopWasUpdated"

#pragma mark -
// The active desktop will change 
#define kPnOnDesktopWillActivate		@"PNDesktopWillActivate"
#define PNDesktopWillActivate				@"PNDesktopWillActivate"
// The active desktop changed 
#define kPnOnDesktopDidActivate			@"PNDesktopDidActivate"
#define PNDesktopDidActivate				@"PNDesktopDidActivate"
//The active application has changed
#define kPnApplicationDidActive			@"PNApplicationDid Activate"

#pragma mark -
// A new window was added 
#define kPnOnWindowAdded						@"PNWindowWasAdded"
#define PNWindowWasAdded						@"PNWindowWasAdded" 
// A window was removed 
#define kPnOnWindowRemoved					@"PNWindowWasRemoved"
#define PNWindowWasRemoved					@"PNWindowWasRemoved"
// PNWindowWas(Added|Removed) parameters 
#define PNWindowApplicationParam		@"PNWindowApplicationParam"

#pragma mark -
// An application was added 
#define PNApplicationWasAdded				@"PNApplicationWasAdded"
// An application was removed 
#define PNApplicationWasRemoved			@"PNApplicationWasRemoved"
// Parameters for PNApplicationWas(Added|Removed) notifications 
#define PNApplicationInstanceParam	@"PNApplicationInstanceParam"
#define PNApplicationDesktopParam		@"PNApplicationDesktopParam"

#pragma mark -
// A window was stickied 
#define kPnOnWindowStickied					@"PNWindowWasStickied"
#define PNWindowWasStickied					@"PNWindowWasStickied"
// A window was unstickied 
#define kPnOnWindowUnstickied				@"PNWindowWasUnstickied"
#define PNWindowWasUnstickied				@"PNWindowWasUnstickied"

// An application was stickied
#define kPnOnApplicationStickied		@"PNApplicationWasStickied"
#define kPnOnApplicationUnstickied	@"PNApplicationWasUnstickied"

#pragma mark -
// Parameters for PNWindow(Will|Did)ChangeDesktop notifications 
#define PNWindowChangeDesktopWindowParam	@"PNWindowChangeWindowParam"
#define PNWindowChangeDesktopSourceParam	@"PNWindowChangeSourceParam"
#define PNWindowChangeDesktopTargetParam	@"PNWindowChangeTargetParam"

// A window will be moved to another desktop 
#define PNWindowWillChangeDesktop	@"PNWindowWillChangeDesktop"
// A window was moved to another desktop 
#define PNWindowDidChangeDesktop	@"PNWindowDidChangeDesktop"

#define PNDesktopWillChangeName   @"PNDesktopWillChangeName"
#define PNDesktopDidChangeName    @"PNDesktopDidChangeName"
