//
//  AppController.m
//  PokerHK
//
//  Created by Steven Hamblin on 29/05/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import "AppController.h"
#import "HKDefines.h"

extern NSString *appName;
extern AXUIElementRef appRef;
extern pid_t pokerstarsPID;

//@class PrefsWindowController;
@implementation AppController

-(id)init
{
	if ((self = [super init])) {
		
		if (!AXAPIEnabled()) {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:@"Accessibility API must be activated in the Universal Access Preferences Pane."];
			[alert setInformativeText:@"Make sure that the \"Enable access for assistive devices\" check box is selected at the bottom of the preference pane.  BlazingStars will now quit to allow you to modify the settings."];
			[alert runModal];
			[[NSApplication sharedApplication] terminate: nil];
		}
		
		NSWorkspace * ws = [NSWorkspace sharedWorkspace];
		NSArray * apps = [ws valueForKeyPath:@"launchedApplications.NSApplicationName"];
		if (![apps containsObject:@"PokerStars"] && ![apps containsObject:@"PokerStarsIT"]) {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:@"PokerStars client not found!"];
			[alert setInformativeText:@"The PokerStars client must be running for this program to operate.  Please start the client and then re-open BlazingStars."];
			[NSApp activateIgnoringOtherApps:YES];
			[alert runModal];
			[[NSApplication sharedApplication] terminate: nil];
		}
		
		if ([apps containsObject:@"PokerStarsIT"]) {
			appName = [NSString stringWithFormat:@"PokerStarsIT"];
			NSLog(@"appName is: %@",appName);
		} else {
			appName = [NSString stringWithFormat:@"PokerStars"];
			NSLog(@"appName is: %@",appName);			
		}
	
		NSArray *pids = [[NSWorkspace sharedWorkspace] launchedApplications];
		
		for (id app in pids) {
			if ([[app objectForKey:@"NSApplicationName"] isEqualToString: appName]) {
				pokerstarsPID =(pid_t) [[app objectForKey:@"NSApplicationProcessIdentifier"] intValue];
			}		
		}
		
		appRef = AXUIElementCreateApplication(pokerstarsPID);
		
		if (!appRef) {
			NSLog(@"Could not get application ref.");
			NSException* apiException = [NSException
										 exceptionWithName:@"PokerStarsNotFoundException"
										 reason:@"Cannot get accessibility API reference to the PokerStars application."									
										 userInfo:nil];
			@throw apiException;
		}
	}
	return self;
}

-(void)awakeFromNib
{
	[[PrefsWindowController sharedPrefsWindowController] setAppController:self];
	[[PrefsWindowController sharedPrefsWindowController] window];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(finishedLaunching:)
	 name:NSApplicationDidFinishLaunchingNotification object:nil];
}

-(AXUIElementRef)getFrontMostApp
{
    pid_t pid;
    ProcessSerialNumber psn;
	
    GetFrontProcess(&psn);
    GetProcessPID(&psn, &pid);
    return AXUIElementCreateApplication(pid);
}


- (void)finishedLaunching:(NSNotification *)notification
{
	NSLog(@"BlazingStars finished launching.");
	
	// Is the PokerStars client the key window?  Then we have to activate the hotkeys.  Note that we can't
	// just look for the active application - because we *are* the active application.
	NSString *appTitle;
    AXUIElementRef frontMostApp;

    /* Here we go. Find out which process is front-most */
    frontMostApp = [self getFrontMostApp];
    /* Get the title of the window */
    AXUIElementCopyAttributeValue(frontMostApp, kAXTitleAttribute, (CFTypeRef *)&appTitle);

	if ([appTitle isEqual:@"PokerStars"]) {
		NSLog(@"PokerStars is frontmost!  Activating hotkeys.");
		if ([windowManager activated] == NO) {
			NSLog(@"Sending didActivate.");
			[windowManager applicationDidActivate];
		}
	}
	
	// Is this the first time that the user has run the program?  If so, display the help screen.
	NSUserDefaults *sdc = [NSUserDefaults standardUserDefaults];
	if ([sdc boolForKey:@"FirstRunCompletedKey"] == NO) {
		
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert addButtonWithTitle:@"Open Prefs..."];
		[alert addButtonWithTitle:@"Help"];
		[alert setMessageText:@"Welcome to BlazingStars!"];
		[alert setInformativeText:@"Press \"Open Prefs...\" to configure, or press \"Help!\" to view the BlazingStars help files."];
		[NSApp activateIgnoringOtherApps:YES];
		int retVal = [alert runModal];
		
		switch (retVal) {
			case NSAlertFirstButtonReturn:
				break;
			case NSAlertSecondButtonReturn:
				[self openPreferences:self];
				break;
			case NSAlertThirdButtonReturn:
				[[NSApplication sharedApplication] showHelp:self];
				break;
		}
		
		[sdc setBool:YES forKey:@"FirstRunCompletedKey"];
	}
	
}

-(IBAction)openPreferences:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[[PrefsWindowController sharedPrefsWindowController] showWindow:sender];
	[[[PrefsWindowController sharedPrefsWindowController] window] makeKeyAndOrderFront:sender];	
}

-(IBAction)openAboutPanel:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp orderFrontStandardAboutPanel:sender];
}

- (IBAction)displayDonate:(id)sender
{
    [[NSHelpManager sharedHelpManager] openHelpAnchor:@"DONATIONS"
                                               inBook:@"BlazingStars Help"];
}

-(IBAction)setWindowFrameColor:(id)sender
{
	
}

-(void)hkChangedFor:(SRRecorderControl *)control withTag:(int)tag
{
	[dispatchController registerHotKeyForControl:control withTag:tag];
}

-(void)voiceCommandsChangedState
{
	[dispatchController voiceCommandsChangedState];
}

-(void)setPotBetAmount:(float)amount forTag:(int)tag
{
	[dispatchController setPotBetAmount:amount forTag:tag];
}

-(void)turnOnRounding:(BOOL)round
{
	[dispatchController turnOnRounding:round];
}

-(void)setRoundingAmount:(float)amount
{
	[dispatchController setRoundingAmount:amount];
}

-(void)setRoundingType:(int)type
{
	[dispatchController setRoundingType:type];
}

-(void)autoBetRounding:(BOOL)aBool
{
	[dispatchController autoBetRounding:aBool];
}

-(void)autoBetAllIn:(BOOL)aBool
{
	[dispatchController autoBetAllIn:aBool];
}

@end
