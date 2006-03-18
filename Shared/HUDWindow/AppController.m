//
//  AppController.m
//  HUDWindow
//
//  Created by Matt Gemmell on 11/03/2006.
//  Copyright 2006 Magic Aubergine. All rights reserved.
//

#import "AppController.h"


@implementation AppController

- (void)awakeFromNib
{
    // Make a rect to position the window at the top-right of the screen.
    NSSize windowSize = NSMakeSize(325.0, 393.0);
    NSSize screenSize = [[NSScreen mainScreen] frame].size;
    NSRect windowFrame = NSMakeRect(screenSize.width - windowSize.width - 10.0, 
                                    screenSize.height - windowSize.height - [NSMenuView menuBarHeight] - 10.0, 
                                    windowSize.width, windowSize.height);
    
    // Create a HUDWindow.
    // Note: the styleMask is ignored; NSBorderlessWindowMask is always used.
    window = [[HUDWindow alloc] initWithContentRect:windowFrame 
                                          styleMask:NSBorderlessWindowMask 
                                            backing:NSBackingStoreBuffered 
                                              defer:NO];
		[window setShowsResizeIndicator: YES];
    
    // Add some text to the window.
    float textHeight = 20.0;
    NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(0.0, (windowSize.height / 2.0) - (textHeight / 2.0), 
                                                                       windowSize.width, textHeight)];
    [[window contentView] addSubview:textField];
    [textField setEditable:NO];
    [textField setTextColor:[NSColor whiteColor]];
    [textField setDrawsBackground:NO];
    [textField setBordered:NO];
    [textField setAlignment:NSCenterTextAlignment];
    [textField setStringValue:@"Some sample text"];
    [textField release];
    
    // Set the window's title and display it.
    [window setTitle:@"Adjust"];
    [window orderFront:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app
{
    return YES;
}

@end
