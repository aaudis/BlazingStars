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

- (void)finishedLaunching:(NSNotification *)notification
{
	NSLog(@"BlazingStars finished launching.");
	
	// Is the PokerStars client the key window?  Then we have to activate the hotkeys.  Note that we can't
	// just look for the active application - because we *are* the active application.
	NSString *appTitle;
    AXUIElementRef frontMostApp;

    /* Here we go. Find out which process is front-most */
    frontMostApp = [lowLevel getFrontMostApp];
    /* Get the title of the window */
    AXUIElementCopyAttributeValue(frontMostApp, kAXTitleAttribute, (CFTypeRef *)&appTitle);

	if ([appTitle isEqual:@"PokerStars"]) {
		if ([windowManager activated] == NO) {
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

-(void)setPFRAmount:(float)amount
{
	[dispatchController setPFRAmount:amount];
}

-(void)setRoundingAmount:(float)amount
{
	[dispatchController setRoundingAmount:amount];
}

-(void)setRoundingType:(int)type
{
	[dispatchController setRoundingType:type];
}

@end
