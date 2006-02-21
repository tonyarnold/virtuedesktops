//
//  SUUpdater.m
//  Sparkle
//
//  Created by Andy Matuschak on 1/4/06.
//  Copyright 2006 Andy Matuschak. All rights reserved.
//

#import "SUUpdater.h"
#import "RSS.h"
#import <stdio.h>

NSString *SUCheckAtStartupKey = @"SUCheckAtStartup";
NSString *SUFeedURLKey = @"SUFeedURL";
NSString *SUShowReleaseNotesKey = @"SUShowReleaseNotes";
NSString *SUSkippedVersionKey = @"SUSkippedVersion";
NSString *SUScheduledCheckIntervalKey = @"SUScheduledCheckInterval";
NSString *SULastCheckTimeKey = @"SULastCheckTime";

@interface SUUpdater (Private)
- (void)checkForUpdatesAndNotify:(BOOL)verbosity;
- (BOOL)promptUserForStartupPreference;
- (void)fetchFeedAndNotify:(NSNumber *)verbosity;
- (NSURL *)updateFeedURL;
- (void)feedFetchDidFailWithException:(NSException *)exception;
- (void)setStatusText:(NSString *)statusText;
- (void)setActionButtonTitle:(NSString *)title;
- (void)createStatusWindow;
- (void)showReleaseNotes;
- (IBAction)stopReleaseNotes:sender;
- (NSButton *)_buttonWithTitle:(NSString *)title inPanel:(NSPanel *)panel;
- (void)alertPanelDownloadClicked:(id)sender;
- (void)alertPanelCancelClicked:(id)sender;
- (void)alertPanelViewReleaseNotesClicked:(id)sender;
- (void)showUpdatePanel;
- (void)showUpdateAlertWithInfo:(NSString *)info;
- (void)didFetchFeedWithInfo:(NSDictionary *)info;
- (IBAction)installAndRestart:sender;
- (IBAction)cancelDownload:sender;
- (NSString *)applicationName;
- (void)setFeed:(RSS *)feed;
- (RSS *)feed;
- (void)setAlertPanel:(NSPanel *)alertPanel;
- (NSPanel *)alertPanel;
+ (NSTimeInterval)storedCheckInterval;
@end

// This massive hack makes compiler warnings about WebKit objects go away.
// You see, we don't include the WebKit header here because Sparkle smartly degrades
// to an NSTextView when WebKit framework isn't compiled into the project. So...
@interface NSObject (SUWebKitHacks)
- parentFrame;
- mainFrame;
- (void)ignore;
- (void)use;
- (void)setFrameLoadDelegate:delegate;
- (void)setPolicyDelegate:delegate;
+ standardPreferences;
- (void)setDefaultFontSize:(int)fontSize;
- (void)setStandardFontFamily:family;
- (void)setPreferences:preferences;
- (void)loadRequest:request;
- (void)loadHTMLString:html baseURL:url;
@end

// If running make localizable-strings for genstrings, ignore the error on this line.
#define SULocalizedString(key, comment) NSLocalizedStringFromTable(key, @"Sparkle", comment)

@implementation SUUpdater

- (NSString *)applicationName
{
    return [[NSFileManager defaultManager] displayNameAtPath:[[NSBundle mainBundle] bundlePath]];
}

- (void)scheduleCheckWithInterval:(NSTimeInterval)interval
{
	if (checkTimer)
		[checkTimer release];
	
	checkInterval = interval;
	if (interval)
		checkTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(checkForUpdatesInBackground) userInfo:nil repeats:YES];
}

- (void)awakeFromNib
{
	// If there's a scheduled interval, we see if it's been longer than that interval since the last
	// check. If so, we perform a startup check; if not, we don't.
	if ([[self class] storedCheckInterval])
	{
		NSTimeInterval interval = [[self class] storedCheckInterval];
		NSDate *lastCheck = [[NSUserDefaults standardUserDefaults] objectForKey:SULastCheckTimeKey];
		if (!lastCheck) { lastCheck = [NSDate distantPast]; }
		NSTimeInterval intervalSinceCheck = [[NSDate date] timeIntervalSinceDate:lastCheck];
		if (intervalSinceCheck < interval)
		{
			// Hasn't been long enough; schedule a check for the future.
			[self performSelector:@selector(checkForUpdatesInBackground) withObject:nil afterDelay:intervalSinceCheck];
			[self performSelector:@selector(scheduleCheckWithInterval:) withObject:[NSNumber numberWithLong:interval] afterDelay:intervalSinceCheck];
		}
		else
		{
			[self scheduleCheckWithInterval:interval];
			[self checkForUpdatesInBackground];
		}
	}
	else
	{
		// There's no scheduled check, so let's see if we're supposed to check on startup.
		NSNumber *shouldCheckAtStartup = [[NSUserDefaults standardUserDefaults] objectForKey:SUCheckAtStartupKey];
		if (!shouldCheckAtStartup) // hasn't been set yet; ask the user
		{
			// Let's see if there's a key in Info.plist for a default, though. We'll let that override the dialog if it's there.
			NSNumber *infoStartupValue = [[[NSBundle mainBundle] infoDictionary] objectForKey:SUCheckAtStartupKey];
			if (infoStartupValue)
			{
				shouldCheckAtStartup = infoStartupValue;
			}
			else
			{
				shouldCheckAtStartup = [NSNumber numberWithBool:NSRunAlertPanel(SULocalizedString(@"Check for updates on startup?", nil), [NSString stringWithFormat:SULocalizedString(@"Would you like %@ to check for updates on startup? If not, you can initiate the check manually from the application menu.", nil), [self applicationName]], NSLocalizedString(@"Yes", nil), NSLocalizedString(@"No", nil), nil) == NSAlertDefaultReturn];
			}
			[[NSUserDefaults standardUserDefaults] setObject:shouldCheckAtStartup forKey:SUCheckAtStartupKey];
		}
			
		if ([shouldCheckAtStartup boolValue])
			[self checkForUpdatesInBackground];
	}
}

- (void)dealloc
{
	[self setFeed:nil];
    [self setAlertPanel:nil];

	[downloadPath release];
	if (checkTimer)
		[checkTimer invalidate];
	[super dealloc];
}

- (void)checkForUpdatesInBackground
{
	[self checkForUpdatesAndNotify:NO];
}

// If the notify flag is YES, Sparkle will say when it can't reach the server and when there's no new update.
// This is generally useful for a menu item--when the check is explicitly invoked.
- (void)checkForUpdatesAndNotify:(BOOL)verbosity
{
	// Make sure one isn't already going...
	if ([statusWindow isVisible] || [alertPanel isVisible] || updateInProgress)
	{
		[statusWindow makeKeyAndOrderFront:self];
		return;
	}
	
	if ([NSApp modalWindow])
	{
		return;
	}
		
	verbose = verbosity;
	updateInProgress = YES;
	// This method name is a little misleading; we're going to split the actual task at hand off into another thread to avoid blocking.
	[NSThread detachNewThreadSelector:@selector(fetchFeed) toTarget:self withObject:nil];
}

- (IBAction)checkForUpdates:sender
{
	// If we're coming from IB, then we want to be more verbose.
	[self checkForUpdatesAndNotify:YES];
}

- (void)showUpdateErrorAlertWithInfo:(NSString *)info
{
	NSRunAlertPanel(SULocalizedString(@"Update Error!", nil), info, NSLocalizedString(@"Cancel", nil), nil, nil);
}

+ (NSTimeInterval)storedCheckInterval
{
	// Returns the scheduled check interval stored in the user defaults / info.plist.
	// User defaults override Info.plist.
	if ([[NSUserDefaults standardUserDefaults] objectForKey:SUScheduledCheckIntervalKey])
		return [[[NSUserDefaults standardUserDefaults] objectForKey:SUScheduledCheckIntervalKey] longValue];
	if ([[[NSBundle mainBundle] infoDictionary] objectForKey:SUScheduledCheckIntervalKey])
		return [[[[NSBundle mainBundle] infoDictionary] objectForKey:SUScheduledCheckIntervalKey] longValue];
	return 0;
}

- (NSString *)newestRemoteVersion
{
	// Finding the new version number from the RSS feed is a little bit hacky. There are two ways:
	// 1. A "sparkle:version" attribute on the enclosure tag, an extension from the RSS spec.
	// 2. If there isn't a version attribute, Sparkle will parse the path in the enclosure, expecting
	//    that it will look like this: http://something.com/YourApp_0.5.zip It'll read whatever's between the last
	//    underscore and the last period as the version number. So name your packages like this: APPNAME_VERSION.extension.
	//    The big caveat with this is that you can't have underscores in your version strings, as that'll confuse Sparkle.
	//    Feel free to change the separator string to a hyphen or something more suited to your needs if you like.
	NSString *newVersion = [[[[self feed] newestItem] objectForKey:@"enclosure"] objectForKey:@"sparkle:version"];
	if (!newVersion) // no sparkle:version attribute
	{
		// Separate the url by underscores and take the last component, as that'll be closest to the end.
		NSString *updatePath = [[[[self feed] newestItem] objectForKey:@"enclosure"] objectForKey:@"url"];
		NSString *versionAndExtension = [[updatePath componentsSeparatedByString:@"_"] lastObject];
		// Now we remove the extension. Hopefully, this will be the version.
		newVersion = [versionAndExtension stringByDeletingPathExtension];
	}
	if (!newVersion) // crap!
	{
		[self showUpdateErrorAlertWithInfo:SULocalizedString(@"Can't extract a version string from the appcast feed. The filenames should look like YourApp_1.5.tgz, where 1.5 is the version number. The underscore is crucial.\n\nIf you're a user reading this, try again later and the developer may have fixed it.", nil)];
	}
	
	return newVersion;
}

- (NSString *)currentVersion
{
	return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

- (void)fetchFeed
{
//#warning TODO: Handle caching / HTTP headers to see if the request is really necessary.
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	RSS *threadFeed;
	NS_DURING
		threadFeed = [[RSS alloc] initWithURL:[self updateFeedURL] normalize:YES];
		[self performSelectorOnMainThread:@selector(didFetchFeed:) withObject:threadFeed waitUntilDone:NO];
	NS_HANDLER
		if (verbose && ([[localException name] isEqualToString:@"RSSDownloadFailed"] || [[localException name] isEqualToString:@"RSSNoData"]))
		{
			// We have to make the main thread do this instead of doing it ourselves because secondary
			// threads can't do GUI stuff (like popping alert dialogs).
			[self performSelectorOnMainThread:@selector(feedFetchDidFailWithException:) withObject:localException waitUntilDone:NO];
		}
	NS_ENDHANDLER
	
	[pool release];
}

- (NSURL *)updateFeedURL
{
	// A value in the user defaults overrides one in the Info.plist (so preferences panels can be
	// created wherein users choose between beta / release feeds).
	NSString *urlString = [[NSUserDefaults standardUserDefaults] objectForKey:SUFeedURLKey];
	if (!urlString)
		urlString = [[[NSBundle mainBundle] infoDictionary] objectForKey:SUFeedURLKey];
	if (!urlString) { [NSException raise:@"SUNoFeedURL" format:@"No feed URL is specified in the Info.plist or the user defaults!"]; }
    return [NSURL URLWithString:urlString];
}

- (void)feedFetchDidFailWithException:(NSException *)exception
{
	[self showUpdateErrorAlertWithInfo:[NSString stringWithFormat:SULocalizedString(@"An error occurred while fetching or parsing the appcast:\n\n%@", nil), [exception reason]]];
	updateInProgress = NO;
}

- (void)setStatusText:(NSString *)statusText
{
	[statusField setAttributedStringValue:[[[NSAttributedString alloc] initWithString:statusText attributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]] forKey:NSFontAttributeName]] autorelease]];
}

- (void)setActionButtonTitle:(NSString *)title
{
	[actionButton setTitle:title];
	[actionButton sizeToFit];
	// Except we're going to add 15 px for padding.
	[actionButton setFrameSize:NSMakeSize([actionButton frame].size.width + 15, [actionButton frame].size.height)];
	// Now we have to move it over so that it's always 15px from the side of the window.
	[actionButton setFrameOrigin:NSMakePoint([[statusWindow contentView] bounds].size.width - 15 - [actionButton frame].size.width, [actionButton frame].origin.y)];
}

- (void)createStatusWindow
{
	// Yeah, it's really hacky that we're programmatically making this window,
	// but this project is made so that you can just drop it in any project, and
	// adding .nibs would complicate things. You'd better appreciate it.
	
	// Numeric literals abound! Run for the hills! But they're mostly taken from the HIG dialog reference layout.
	
	statusWindow = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 384, 106) styleMask:NSTitledWindowMask | NSMiniaturizableWindowMask backing:NSBackingStoreBuffered defer:NO];
	[statusWindow center];
	[statusWindow setTitle:[NSString stringWithFormat:SULocalizedString(@"Updating %@", nil), [self applicationName]]];
	
	id contentView = [statusWindow contentView];
	NSSize windowSize = [contentView bounds].size;
	
	// Place the app icon.
	NSImageView *appIconView = [[[NSImageView alloc] initWithFrame:NSMakeRect(24, windowSize.height - 15 - 64, 64, 64)] autorelease];
	[appIconView setImageFrameStyle:NSImageFrameNone];
	[appIconView setImage:[NSApp applicationIconImage]];
	[contentView addSubview:appIconView];
	
	// Place the status field.
	statusField = [[[NSTextField alloc] initWithFrame:NSMakeRect(24 + 64 + 15, windowSize.height - 15 - 17, 260, 17)] autorelease];
	[self setStatusText:SULocalizedString(@"Downloading update...", nil)];
	[statusField setBezeled:NO];
	[statusField setEditable:NO];
	[statusField setDrawsBackground:NO];
	[contentView addSubview:statusField];
	
	// Place the download completion field.
	downloadProgressField = [[[NSTextField alloc] initWithFrame:NSMakeRect(24 + 64 + 15, 22, 150, 17)] autorelease];
	[downloadProgressField setBezeled:NO];
	[downloadProgressField setEditable:NO];
	[downloadProgressField setDrawsBackground:NO];
	[contentView addSubview:downloadProgressField];
	
	// Place the progress bar.
	progressBar = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(24 + 64 + 16, windowSize.height - 15 - 17 - 8 - 20, 260, 20)] autorelease];
	[progressBar setIndeterminate:YES];
	[progressBar setUsesThreadedAnimation:YES];
	[progressBar startAnimation:self];
	[progressBar setControlSize:NSRegularControlSize];
	[contentView addSubview:progressBar];
	
	// Place the action button.
	actionButton = [[[NSButton alloc] initWithFrame:NSMakeRect(windowSize.width - 15 - 82, 12, 82, 32)] autorelease];
	[actionButton setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSRegularControlSize]]];
	[actionButton setBezelStyle:NSRoundedBezelStyle];
	[self setActionButtonTitle:NSLocalizedString(@"Cancel", nil)];
	[actionButton setTarget:self];
	[actionButton setAction:@selector(cancelDownload:)];
	[contentView addSubview:actionButton];
}

- (void)webView:sender didFinishLoadForFrame:frame
{
    if ([frame parentFrame] == nil) {
        webViewFinishedLoading = YES;
		[releaseNotesSpinner setHidden:YES];
		[sender display]; // necessary to prevent weird scroll bar artifacting
    }
}

- (void)webView:sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:frame decisionListener:listener
{
    if (webViewFinishedLoading == YES) {
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];

        [listener ignore];
    }    
    else {
        [listener use];
    }
}

- (NSButton *)_buttonWithTitle:(NSString *)title inPanel:(NSPanel *)panel
{
    NSArray *subviews = [[panel contentView] subviews];
    
	unsigned i;
    for (i = 0; i < [subviews count]; ++i) {
        NSButton *button = [subviews objectAtIndex:i];
        
        if ([button isKindOfClass:[NSButton class]]) {
            if ([[button title] isEqualToString:title]) {
                return button;
            }
        }
    }
    
    return nil;
}

- (void)alertPanelDownloadClicked:(id)sender
{
    [alertPanel orderOut:nil];
    [alertPanel release];
    alertPanel = nil; 
    
	// Clear out the skipped version so the dialog will come back if the download fails.
	[[NSUserDefaults standardUserDefaults] setObject:nil forKey:SUSkippedVersionKey];
	
    [self createStatusWindow];
    [statusWindow makeKeyAndOrderFront:self];
    
    NSString *urlString = [[[[self feed] newestItem] objectForKey:@"enclosure"] objectForKey:@"url"];
    
    downloader = [[NSURLDownload alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]] delegate:self];
}

- (void)alertPanelRemindMeLaterClicked:(id)sender
{
    [alertPanel orderOut:nil];
    [self setAlertPanel:nil];
	updateInProgress = NO;

	// Clear out the skipped version so the dialog will actually come back if it was already skipped.
	[[NSUserDefaults standardUserDefaults] setObject:nil forKey:SUSkippedVersionKey];
	
	if (checkInterval)
		[self scheduleCheckWithInterval:checkInterval];
	else
	{
		// If the host hasn't provided a check interval, we'll use 30 minutes.
		[self scheduleCheckWithInterval:30 * 60];
	}
}

- (void)alertPanelSkipVersionClicked:sender
{
	[alertPanel orderOut:nil];
    [self setAlertPanel:nil];
	updateInProgress = NO;

	[[NSUserDefaults standardUserDefaults] setObject:[self newestRemoteVersion] forKey:SUSkippedVersionKey];
}

- (NSRect)releaseNotesFrame
{
	return NSMakeRect(20 + 64 + 22, 54, [[self alertPanel] frame].size.width - 20 - 64 - 22 - 20, 200);
}

- (void)setupWebKitReleaseNotes
{
	// We make a box to border the web view.
	NSBox *box = [[[NSBox alloc] initWithFrame:[self releaseNotesFrame]] autorelease];
    [box setBoxType:NSBoxOldStyle];
    [box setBorderType:NSLineBorder];
    [box setTitlePosition:NSNoTitle];
    [box setAutoresizingMask:NSViewHeightSizable];
    [box setContentViewMargins:NSMakeSize(1, 1)];
    
    NSRect frame = NSInsetRect([box frame], 1, 1);
    frame.origin = NSMakePoint(0, 0);
    
	id webView = [[[NSClassFromString(@"WebView") alloc] initWithFrame:frame] autorelease];
    [webView setFrameLoadDelegate:self];
    [webView setPolicyDelegate:self];
    [webView setAutoresizingMask:NSViewHeightSizable];
    
    [box setFrameSize:NSMakeSize([webView frame].size.width, [box frame].size.height)];
    [box setContentView:webView];
	
    [[[self alertPanel] contentView] addSubview:box];
	
	// Stick a nice big spinner in the middle of the web view until the page is loaded.
	frame = [box frame];
	releaseNotesSpinner = [[[NSProgressIndicator alloc] initWithFrame:NSMakeRect(NSMidX(frame)-16, NSMidY(frame)-16, 32, 32)] autorelease];
	[releaseNotesSpinner setStyle:NSProgressIndicatorSpinningStyle];
	[releaseNotesSpinner startAnimation:self];
    webViewFinishedLoading = NO;
	[[[self alertPanel] contentView] addSubview:releaseNotesSpinner];

	// Set up some defaults to make things a little prettier
	id preferences = [[[NSClassFromString(@"WebPreferences") alloc] initWithIdentifier:[@"SU" stringByAppendingString:[self applicationName]]] autorelease];
	[preferences setDefaultFontSize:11];
	[preferences setStandardFontFamily:@"Lucida Grande"];
	[webView setPreferences:preferences];
	
	// If there's a sparkle:releaseNotesLink, load that first.
	if ([[[self feed] newestItem] objectForKey:@"sparkle:releaseNotesLink"])
	{
		[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[[self feed] newestItem] objectForKey:@"sparkle:releaseNotesLink"]]]];
	}
	else
	{
		// If the description starts with http://, use the description.
		if ([[[[self feed] newestItem] objectForKey:@"description"] rangeOfString:@"http://"].location == 0)
		{
			[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[[self feed] newestItem] objectForKey:@"description"]]]];
		}
		else
		{
			// Otherwise, stick the contents of the description into the web view.
			[[webView mainFrame] loadHTMLString:[[[self feed] newestItem] objectForKey:@"description"] baseURL:nil];
		}
	}	
}

- (void)setupCocoaReleaseNotes
{
	NSScrollView *scrollView = [[[NSScrollView alloc] initWithFrame:[self releaseNotesFrame]] autorelease];
	[scrollView setHasVerticalScroller:YES];
	[scrollView setBorderType:NSBezelBorder];
	[[[self alertPanel] contentView] addSubview:scrollView];
	
	NSTextView *textView = [[NSTextView alloc] initWithFrame:[[scrollView contentView] bounds]];
	NSAttributedString *attributedString = [[[NSMutableAttributedString alloc] initWithHTML:[NSData dataWithBytes:[[[feed newestItem] objectForKey:@"description"] cString] length:[(NSString *)[[feed newestItem] objectForKey:@"description"] length]] options:nil documentAttributes:nil] autorelease];
	[[textView textStorage] setAttributedString:attributedString];
	[textView setEditable:NO];
	[textView setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
	[scrollView setDocumentView:textView];
}

- (void)showUpdatePanel
{
	// This method is called when there's an update to determine if the user wants it.
    [self setAlertPanel:NSGetAlertPanel([NSString stringWithFormat:SULocalizedString(@"A new version of %@ is available!", nil), [self applicationName]], [NSString stringWithFormat:SULocalizedString(@"%@ %@ is now available (you have %@). Would you like to download it now?", nil), [self applicationName], [self newestRemoteVersion], [self currentVersion]], SULocalizedString(@"Download New Version", nil), SULocalizedString(@"Skip This Version", nil), SULocalizedString(@"Remind Me Later", nil))];

	// Set up button actions
    NSButton *button = [self _buttonWithTitle:SULocalizedString(@"Download New Version", nil) inPanel:[self alertPanel]];
    [button setTarget:self];
    [button setAction:@selector(alertPanelDownloadClicked:)];

    button = [self _buttonWithTitle:SULocalizedString(@"Remind Me Later", nil) inPanel:[self alertPanel]];
    [button setTarget:self];
    [button setAction:@selector(alertPanelRemindMeLaterClicked:)];

    button = [self _buttonWithTitle:SULocalizedString(@"Skip This Version", nil) inPanel:[self alertPanel]];
    [button setTarget:self];
    [button setAction:@selector(alertPanelSkipVersionClicked:)];
	
	// Get the release notes option from Info.plist.
    NSNumber *showNotesObj = [[[NSBundle mainBundle] infoDictionary] objectForKey:SUShowReleaseNotesKey];
    BOOL showNotes;
    if (!showNotesObj)
        showNotes = YES;
    else
        showNotes = [showNotesObj boolValue];
	
	if (showNotes)
	{
		// Make way, make way for the great and powerful... I mean for the release notes view.
		[[self alertPanel] setFrame:NSMakeRect(0, 0, [[self alertPanel] frame].size.width, [[self alertPanel] frame].size.height + 200 + 8) display:NO];
		
		NSTextField *releaseNotesLabel = [[[NSTextField alloc] initWithFrame:NSMakeRect(64 + 20 + 20, 258, 150, 17)] autorelease];
		[releaseNotesLabel setBordered:NO];
		[releaseNotesLabel setDrawsBackground:NO];
		[releaseNotesLabel setEditable:NO];
		[releaseNotesLabel setAttributedStringValue:[[[NSAttributedString alloc] initWithString:[SULocalizedString(@"Release Notes", nil) stringByAppendingString:@":"] attributes:[NSDictionary dictionaryWithObject:[NSFont boldSystemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]] forKey:NSFontAttributeName]] autorelease]];
		[[[self alertPanel] contentView] addSubview:releaseNotesLabel];
		
		// Alright, does the host app include WebKit? If so, we'll use a fancy WebView; otherwise, a plain old NSTextView.
		if (NSClassFromString(@"WebView"))
			[self setupWebKitReleaseNotes];
		else
			[self setupCocoaReleaseNotes];
	}
	
	[[self alertPanel] center];
    [[self alertPanel] makeKeyAndOrderFront:nil];        
}

- (RSS *)feed 
{
    return [[feed retain] autorelease];
}

- (void)setFeed:(RSS *)value 
{
    if (feed != value) {
        [feed release];
        feed = [value retain];
    }
}

- (NSPanel *)alertPanel 
{
    return [[alertPanel retain] autorelease];
}

- (void)setAlertPanel:(NSPanel *)value 
{
    if (alertPanel != value) {
        [alertPanel release];
        alertPanel = [value retain];
    }
}

- (BOOL)webViewFinishedLoading 
{
    return webViewFinishedLoading;
}

- (void)setWebViewFinishedLoading:(BOOL)value 
{
    webViewFinishedLoading = value;
}

- (void)didFetchFeed:(RSS *)remoteFeed
{
	// Record the time of the check for host app use and for interval checks on startup.
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:SULastCheckTimeKey];

	[self setFeed:remoteFeed];
	if (![self newestRemoteVersion]) { updateInProgress = NO; return; }
	if (!verbose && [[[NSUserDefaults standardUserDefaults] objectForKey:SUSkippedVersionKey] isEqualToString:[self newestRemoteVersion]]) { updateInProgress = NO; return; }
	
	if ([[self currentVersion] isEqualToString:[self newestRemoteVersion]])
	{
		// We only notify on no new version when the notify flag is on.
		if (verbose)
		{
			NSRunAlertPanel(SULocalizedString(@"You're up to date!", nil), [NSString stringWithFormat:SULocalizedString(@"%@ %@ is currently the newest version available.", nil), [self applicationName], [self currentVersion]], NSLocalizedString(@"OK", nil), nil, nil);
		}
		updateInProgress = NO;
	}
	else
	{
		// There's a new version! Let's disable the automated checking timer unless the user cancels.
		if (checkTimer)
		{
			[checkTimer invalidate];
			checkTimer = nil;
		}
		
		[self showUpdatePanel];
	}
}

- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response
{
	[progressBar setIndeterminate:NO];
	[progressBar startAnimation:self];
	[progressBar setMaxValue:[response expectedContentLength]];
	[progressBar setDoubleValue:0];
}

- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)name
{
	// If name ends in .txt, the server probably has a stupid MIME configuration. We'll give
	// the developer the benefit of the doubt and chop that off.
	if ([[name pathExtension] isEqualToString:@"txt"])
		name = [name stringByDeletingPathExtension];
	
	// We create a temporary directory in /tmp and stick the file there.
	NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]];
	BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:tempDir attributes:nil];
	if (!success)
	{
		[NSException raise:@"SUFailTmpWrite" format:@"Couldn't create temporary directory in /tmp"];
		[download cancel];
		[download release];
	}
	
	downloadPath = [[tempDir stringByAppendingPathComponent:name] retain];
	[download setDestination:downloadPath allowOverwrite:YES];
}

- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(unsigned)length
{
	[progressBar setDoubleValue:[progressBar doubleValue] + length];
	[downloadProgressField setStringValue:[NSString stringWithFormat:SULocalizedString(@"%.0lfk of %.0lfk", nil), [progressBar doubleValue] / 1024.0, [progressBar maxValue] / 1024.0]];
}

// This method abstracts the three kinds of tar-based archives Sparkle supports.
- (BOOL)extractArchivePath:archivePath pipingDataToCommand:(NSString *)command
{
	// Get the file size.
	NSNumber *fs = [[[NSFileManager defaultManager] fileAttributesAtPath:archivePath traverseLink:NO] objectForKey:NSFileSize];
	if (fs == nil)
	{
		[self showUpdateErrorAlertWithInfo:SULocalizedString(@"Okay, where'd it go? I just downloaded the update, but it seems to have vanished! Please try again later.", nil)];
		[statusWindow orderOut:self];
		[statusWindow release];
		statusWindow = nil;
		updateInProgress = NO;
		return NO;
	}
	
	long fileSize = [fs longValue];
	
	// Thank you, Allan Odgaard!
	// (who wrote the following extraction alg.)
	[progressBar setIndeterminate:NO];
	[progressBar setDoubleValue:0.0];
	[progressBar setMaxValue:fileSize];
	[progressBar startAnimation:self];
	
	long current = 0;
	FILE *fp, *cmdFP;
	if (fp = fopen([archivePath UTF8String], "r"))
	{
		setenv("DESTINATION", [[archivePath stringByDeletingLastPathComponent] UTF8String], 1);
		if (cmdFP = popen([command cString], "w"))
		{
			char buf[32*1024];
			long len;
			while(len = fread(buf, 1, 32 * 1024, fp))
			{
				// It could be cancelled while this is happening; let's see if the status window is still around.
				if (!statusWindow)
				{
					pclose(cmdFP);
					fclose(fp);
					return YES;
				}
				
				current += len;
				[progressBar setDoubleValue:(double)current];
				[downloadProgressField setStringValue:[NSString stringWithFormat:SULocalizedString(@"%.0lfk of %.0lfk", nil), current / 1024.0, fileSize / 1024.0]];
				
				NSEvent *event;
				while(event = [NSApp nextEventMatchingMask:NSAnyEventMask untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES])
					[NSApp sendEvent:event];
				
				fwrite(buf, 1, len, cmdFP);
			}
			pclose(cmdFP);
		}
		fclose(fp);
	}	
	return YES;
}

- (BOOL)extractTAR:(NSString *)archivePath
{
	return [self extractArchivePath:archivePath pipingDataToCommand:@"tar -xC \"$DESTINATION\""];
}

- (BOOL)extractTGZ:(NSString *)archivePath
{
	return [self extractArchivePath:archivePath pipingDataToCommand:@"tar -zxC \"$DESTINATION\""];
}

- (BOOL)extractTBZ:(NSString *)archivePath
{
	return [self extractArchivePath:archivePath pipingDataToCommand:@"tar -jxC \"$DESTINATION\""];
}

- (BOOL)extractZIP:(NSString *)archivePath
{
	return [self extractArchivePath:archivePath pipingDataToCommand:@"ditto -xk - \"$DESTINATION\""];
}

- (BOOL)extractDMG:(NSString *)archivePath
{
	[progressBar setIndeterminate:YES];
	[progressBar startAnimation:self];
	[downloadProgressField setHidden:YES];
	
	NSArray *preMountVolumes = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
	NSTask *hdiTask = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/env" arguments:[NSArray arrayWithObjects:@"hdiutil", @"mount", @"-noidme", @"-noverify", @"-noautoopen", @"-quiet", archivePath, nil]];
	[hdiTask waitUntilExit];
	if ([hdiTask terminationStatus] != 0) // an error occurred!
	{
		[self showUpdateErrorAlertWithInfo:SULocalizedString(@"Couldn't mount the update archive.", nil)];
		return NO;
	}

	// Determine which elements were added in the mount; sadly, multiple new volumes could have been mounted, so this is complicated.
	NSArray *postMountVolumes = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
	NSMutableArray *newVolumes = [NSMutableArray array];
	id enumerator = [postMountVolumes objectEnumerator], current;
	while (current = [enumerator nextObject])
	{
		if (![preMountVolumes containsObject:current])
			[newVolumes addObject:current];
	}
	
	if ([newVolumes count] == 0)
	{
		[self showUpdateErrorAlertWithInfo:SULocalizedString(@"Couldn't mount the update archive.", nil)];
		return NO;
	}
	
	NSString *mountPoint;
	if ([newVolumes count] == 1)
	{
		mountPoint = [newVolumes objectAtIndex:0];
	}
	else
	{
		// Okay, then we'll take the first one with the app name in its path.
		enumerator = [newVolumes objectEnumerator];
		while (current = [enumerator nextObject])
		{
			if ([current rangeOfString:[self applicationName]].location != NSNotFound)
				mountPoint = current;
		}
	}
	
	if (!mountPoint)
	{
		[self showUpdateErrorAlertWithInfo:SULocalizedString(@"Couldn't mount the update archive.", nil)];
		return NO;
	}
	
	// Got it! Move the app inside to the temp directory.
	NSString *newAppVolumePath = [mountPoint stringByAppendingPathComponent:[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"] stringByAppendingPathExtension:@"app"]];
	if (![[NSFileManager defaultManager] fileExistsAtPath:newAppVolumePath])
	{
		[self showUpdateErrorAlertWithInfo:[NSString stringWithFormat:SULocalizedString(@"The update archive didn't contain an application with the name I was expecting (%@). Remember, the updated app's file name must be identical to the running app's name as specified in the Info.plist! (with CFBundleName)\n\nIf you're a user reading this, try again later and the developer may have fixed it.", nil), [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"] stringByAppendingPathExtension:@"app"]]];
		return NO;
	}
	[[NSFileManager defaultManager] movePath:newAppVolumePath toPath:[[archivePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[newAppVolumePath lastPathComponent]] handler:NULL];
	
	// Unmount.
	[[NSTask launchedTaskWithLaunchPath:@"/usr/bin/env" arguments:[NSArray arrayWithObjects:@"hdiutil", @"unmount", @"-quiet", @"-force", mountPoint, nil]] waitUntilExit];
	return YES;
}

- (void)downloadDidFinish:(NSURLDownload *)download
{
	[download release];
	downloader = nil;
	
	// Now we have to extract the downloaded archive.
	[self setStatusText:SULocalizedString(@"Extracting update...", nil)];
	
	// This dictionary associates names of methods responsible for extraction with file extensions.
	// The methods take the path of the archive to extract. They return a BOOL indicating whether
	// we should continue with the update; returns NO if an error occurred.
	NSDictionary *commandDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"extractTBZ:", @"tbz",
        @"extractTGZ:", @"tgz",
        @"extractTAR:", @"tar", 
		@"extractZIP:", @"zip", 
		@"extractDMG:", @"dmg", nil];

	SEL command = NSSelectorFromString([commandDictionary objectForKey:[downloadPath pathExtension]]);
	if (!command)
	{
		[self showUpdateErrorAlertWithInfo:[NSString stringWithFormat:SULocalizedString(@"Can't extract archives of type %@; only %@ are supported.\n\nIf you're a user reading this, try again later and the developer may have fixed it.", nil), [downloadPath pathExtension], [commandDictionary allKeys]]];
		[statusWindow orderOut:self];
		[statusWindow release];
		statusWindow = nil;
		updateInProgress = NO;
		return;
	}
	
	if (![self performSelector:command withObject:downloadPath])
	{
		[statusWindow orderOut:self];
		[statusWindow release];
		statusWindow = nil;
		updateInProgress = NO;
		return;
	}
	
	[progressBar setIndeterminate:NO];
	[progressBar setDoubleValue:[progressBar maxValue]];
	[self setStatusText:SULocalizedString(@"Ready to install!", nil)];
	[self setActionButtonTitle:SULocalizedString(@"Install and Relaunch", nil)];
	
	[downloadProgressField setHidden:YES];
	[actionButton setAction:@selector(installAndRestart:)];
	
	[NSApp requestUserAttention:NSInformationalRequest];
	[actionButton setKeyEquivalent:@"\r"]; // Make the button active
}

- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error
{
	[statusWindow orderOut:self];
	[statusWindow release];
	statusWindow = nil;
	updateInProgress = NO;
	
	[self showUpdateErrorAlertWithInfo:[NSString stringWithFormat:SULocalizedString(@"An error occurred while trying to download the file:\n\n%@", nil), [error localizedDescription]]];
}

- (IBAction)installAndRestart:sender
{
	[progressBar setIndeterminate:YES];
	[progressBar startAnimation:self];
	[self setStatusText:SULocalizedString(@"Installing update...", nil)];
	[progressBar display];
	[statusField display];
	
	// We assume that the archive will contain a file named {CFBundleName}.app
	// (where, obviously, CFBundleName comes from Info.plist)
	NSString *currentAppPath = [[NSBundle mainBundle] bundlePath];
	NSString *newAppDownloadPath = [[downloadPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"] stringByAppendingPathExtension:@"app"]];
	if (![[NSFileManager defaultManager] fileExistsAtPath:newAppDownloadPath])
	{
		[self showUpdateErrorAlertWithInfo:[NSString stringWithFormat:SULocalizedString(@"The update archive didn't contain an application with the name I was expecting (%@). Remember, the updated app's file name must be identical to the running app's name as specified in the Info.plist! (with CFBundleName)\n\nIf you're a user reading this, try again later and the developer may have fixed it.", nil), newAppDownloadPath]];
		
		[statusWindow orderOut:self];
		[statusWindow release];
		statusWindow = nil;
		updateInProgress = NO;
		return;
	}
	
	// Generate a randomly-suffixed filename for the new app.
	NSString *newAppInstallPath = [[[currentAppPath stringByDeletingPathExtension] stringByAppendingString:[[NSProcessInfo processInfo] globallyUniqueString]] stringByAppendingPathExtension:[currentAppPath pathExtension]];
		
	// Move the app to its new home (in suffixed form).
	if (![[NSFileManager defaultManager] movePath:newAppDownloadPath toPath:newAppInstallPath handler:NULL])
	{
		[self showUpdateAlertWithInfo:SULocalizedString(@"Couldn't move the update to its new home. Are you running this application from a write-only directory?", nil)];
		
		[statusWindow orderOut:self];
		[statusWindow release];
		statusWindow = nil;
		updateInProgress = NO;
		return;
	}
	
	// Now we move the old one to the trash.
	int tag = 0;
	if (![[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[currentAppPath stringByDeletingLastPathComponent] destination:@"" files:[NSArray arrayWithObject:[currentAppPath lastPathComponent]] tag:&tag])
	{
		[self showUpdateAlertWithInfo:SULocalizedString(@"Couldn't delete the current application, which has to be done before the update can be installed. Is it in a write-only location (like on the disk image?). Move it to /Applications and try again.", nil)];
		
		[statusWindow orderOut:self];
		[statusWindow release];
		statusWindow = nil;
		updateInProgress = NO;
		return;
	}
	
	// Rename the new app to get rid of its random suffix.
	[[NSFileManager defaultManager] movePath:newAppInstallPath toPath:currentAppPath handler:NULL];
	
	// Delete the temp folder where the archive was downloaded and extracted.
	[[NSFileManager defaultManager] removeFileAtPath:[downloadPath stringByDeletingLastPathComponent] handler:nil];
	
	// Open the new app and kill the current one.
	if (![[NSWorkspace sharedWorkspace] launchApplication:currentAppPath])
	{
		[self showUpdateAlertWithInfo:[NSString stringWithFormat:SULocalizedString(@"%@ was unable to run the new version automatically. The program will now quit (giving you an opportunity to save); please reopen it to complete the update.", nil), [self applicationName]]];
	}
	[NSApp terminate:self];
}

- (IBAction)cancelDownload:sender
{
	if (downloader)
	{
		[downloader cancel];
		[downloader release];
	}
	[statusWindow orderOut:self];
	[statusWindow release];
	statusWindow = nil;
	updateInProgress = NO;
	
	if (checkInterval)
	{
		[self scheduleCheckWithInterval:checkInterval];
	}
}

@end
