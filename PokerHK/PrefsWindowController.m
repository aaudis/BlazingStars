//
//  PrefsWindowController.m
//  PokerHK
//
//  Created by Steven Hamblin on 29/05/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//
#import "AppController.h"
#import "PrefsWindowController.h"
#import "ShortcutRecorder.h"

@class ShortcutRecorder;

@implementation PrefsWindowController
@synthesize appController;
@synthesize themeController;
@synthesize radiobuttonMatrix;
@synthesize stepper;
@synthesize scrollWheelCheckBox;
@synthesize windowFrameColourWell;


+(void)initialize {
	// If this is the first run, set up sensible default hot keys.  
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *shortcutDefaults = [NSMutableDictionary dictionary];
	
	KeyCombo kc;

	kc.code = 3; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"FoldKey"];
	kc.code = 8; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"CallKey"];
	kc.code = 11; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"BetKey"];
	kc.code = 12; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"CheckFoldKey"];	
	kc.code = 13; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"FoldToAnyKey"];	
	kc.code = 45; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"FoldToAnyLeftKey"];		
	kc.code = 14; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"CheckCallKey"];	
	kc.code = 15; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"CheckCallAnyKey"];	
	kc.code = 17; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"BetRaiseKey"];	
	kc.code = 16; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"BetRaiseAnyKey"];	
	kc.code = 35; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"SitOutKey"];		
	kc.code = 33; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"AutoPostKey"];	
	kc.code = 30; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"SitOutAllTablesKey"];
	kc.code = 126; kc.flags = 10486016; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"IncrementKey"];	
	kc.code = 125; kc.flags = 10486016; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"DecrementKey"];	
	kc.code = 37; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"leaveTable"];	
	kc.code = 37; kc.flags = 1179914; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"leaveAllTables"];	
	kc.code = 0; kc.flags = 1179914; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"AllInKey"];		
	kc.code = 35; kc.flags = 1573160; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"ToggleAllKey"];	
	kc.code = 40; kc.flags = 1048840; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"DebugKey"];		

	kc.code = 19; kc.flags = 1048840; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"PotBetOneKey"];		
	kc.code = 20; kc.flags = 1048840; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"PotBetTwoKey"];	
	kc.code = 21; kc.flags = 1048840; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"PotBetThreeKey"];		
	kc.code = 23; kc.flags = 1048840; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"PotBetFourKey"];	
	kc.code = 49; kc.flags = 256;     [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"PFRKey"];
	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:25.0] forKey:@"potBetOneKey"];
	[shortcutDefaults setObject:[NSNumber numberWithFloat:50.0] forKey:@"potBetTwoKey"];
	[shortcutDefaults setObject:[NSNumber numberWithFloat:75.0] forKey:@"potBetThreeKey"];
	[shortcutDefaults setObject:[NSNumber numberWithFloat:100.0] forKey:@"potBetFourKey"];	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:125.0] forKey:@"potBetFiveKey"];	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:150.0] forKey:@"potBetSixKey"];	
	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:2.5] forKey:@"pfrOneKey"];	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:3.0] forKey:@"pfrTwoKey"];	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:4.0] forKey:@"pfrThreeKey"];	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:5.0] forKey:@"pfrFourKey"];	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:6.0] forKey:@"pfrFiveKey"];	

	NSColor *aColor = [NSColor yellowColor];
	NSData *theData=[NSArchiver archivedDataWithRootObject:aColor];
	[shortcutDefaults setObject:theData forKey:@"windowFrameColourKey"];
	
    [defaults registerDefaults:shortcutDefaults];
}

-(void)awakeFromNib
{
	logger = [SOLogger loggerForFacility:@"com.fullyfunctionalsoftware.blazingstars" options:ASL_OPT_STDERR];
	[logger info:@"Initializing prefsWindowController."];
	
    [self detectTheme];
    
	[self populateControls];
	
    NSURL* url = [NSURL fileURLWithPath:@"/System/Library/PreferencePanes/Speech.prefPane"];
	
	NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
	[string appendAttributedString: [[NSAttributedString alloc] initWithString:@"To change settings for voice commands, explore the preferences in the Speech panel of the System Preferences (click to open).  To get a list of commands, say the command \"Show me what to say\"."]];
	NSRange selectedRange = NSMakeRange(109, 15);
	[string beginEditing];
	[string addAttribute:NSLinkAttributeName
				   value:url
				   range:selectedRange];
	[string addAttribute:NSForegroundColorAttributeName	 
				   value:[NSColor blueColor]	 
				   range:selectedRange];	
	[string addAttribute:NSUnderlineStyleAttributeName	 
				   value:[NSNumber numberWithInt:NSSingleUnderlineStyle]
				   range:selectedRange];	
	[string endEditing];	
	
    // set the attributed string to the NSTextField
    [voiceComandsTextField setAttributedStringValue: string];

}

-(void)populateControls
{
	// Make the textfield take the initial value.
	[changeAmountField setFloatValue:[stepper floatValue]];
	
	// Set the dictionary of controls so that the dispatch controller can automatically
	// dispatch methods.
	tagDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:[NSNumber numberWithInt:1],@"FoldKey",nil],[NSValue valueWithPointer:fold],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:2],@"CallKey",nil],[NSValue valueWithPointer:call],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:3],@"BetKey",nil],[NSValue valueWithPointer:bet],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:4],@"CheckFoldKey",nil],[NSValue valueWithPointer:checkFold], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:5],@"FoldToAnyKey",nil],[NSValue valueWithPointer:foldToAny], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:6],@"CheckCallKey",nil],[NSValue valueWithPointer:checkCall], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:7],@"CheckCallAnyKey",nil],[NSValue valueWithPointer:checkCallAny], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:8],@"BetRaiseKey",nil],[NSValue valueWithPointer:betRaise], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:9],@"BetRaiseAnyKey",nil],[NSValue valueWithPointer:betRaiseAny], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:10],@"SitOutKey",nil],[NSValue valueWithPointer:sitOut],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:11],@"AutoPostKey",nil],[NSValue valueWithPointer:autoPost],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:12],@"SitOutAllTablesKey",nil],[NSValue valueWithPointer:sitOutAllTables], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:13],@"IncrementKey",nil],[NSValue valueWithPointer:increment], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:14],@"DecrementKey",nil],[NSValue valueWithPointer:decrement],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:15],@"leaveTable",nil],[NSValue valueWithPointer:leaveTable],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:16],@"leaveAllTables",nil],[NSValue valueWithPointer:leaveAllTables], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:17],@"PotBetOneKey",nil],[NSValue valueWithPointer:potBetOne], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:18],@"PotBetTwoKey",nil],[NSValue valueWithPointer:potBetTwo], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:19],@"PotBetThreeKey",nil],[NSValue valueWithPointer:potBetThree], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:20],@"PotBetFourKey",nil],[NSValue valueWithPointer:potBetFour],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:21],@"PotBetFiveKey",nil],[NSValue valueWithPointer:potBetFive],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:22],@"PotBetSixKey",nil],[NSValue valueWithPointer:potBetSix],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:23],@"AllInKey",nil],[NSValue valueWithPointer:allIn],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:24],@"ToggleAllKey",nil],[NSValue valueWithPointer:toggleAllHotkeys],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:25],@"PFROneKey",nil],[NSValue valueWithPointer:pfrOne],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:26],@"PFRTwoKey",nil],[NSValue valueWithPointer:pfrTwo],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:27],@"PFRThreeKey",nil],[NSValue valueWithPointer:pfrThree],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:28],@"PFRFourKey",nil],[NSValue valueWithPointer:pfrFour],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:29],@"PFRFiveKey",nil],[NSValue valueWithPointer:pfrFive],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:30],@"FoldToAnyLeftKey",nil],[NSValue valueWithPointer:foldToAnyLeft], 
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:99],@"DebugKey",nil],[NSValue valueWithPointer:debugHK],	
			   nil];
	
	SRRecorderControl *sc; 	KeyCombo key;
	for (id tag in [tagDict allKeys]) {
		sc = [tag pointerValue];
		[sc setAnimates:YES];
		[sc setStyle:(SRRecorderStyle)SRGreyStyle];
		[sc setAllowsKeyOnly:YES escapeKeysRecord:NO];
		
		NSString *dictKey = [[tagDict objectForKey:tag] objectAtIndex:SRKEY];
		if ([[NSUserDefaults standardUserDefaults] objectForKey:dictKey] != nil) {
			[[[NSUserDefaults standardUserDefaults] objectForKey:dictKey] getBytes:&key length:sizeof(KeyCombo)];
			[sc setKeyCombo:key];
		} else {
			KeyCombo k = [sc keyCombo];
			[[NSUserDefaults standardUserDefaults] setObject:[NSData dataWithBytes:&k length:sizeof(KeyCombo)] forKey:dictKey];
		}
	}	
	
	// Set up the pot bet fields.
	for (int i = 17; i < 23; i++) {
		[self setPotBetAmount:[potBetPrefsView viewWithTag:i]];
	}
	
	for (int i = 25; i < 30; i++) {
		[self setPFRAmount:[potBetPrefsView viewWithTag:i]];
	}
	
	// Trigger the rounding controls.
	[self setRoundingAmount:[potBetPrefsView viewWithTag:ROUNDINGAMOUNTTAG]];
	[self setRoundingType:[potBetPrefsView viewWithTag:ROUNDINGTYPETAG]];
	
}

- (BOOL)textField:(NSTextField *)textField openURL:(NSURL *)anURL
{
	[logger debug:@"In delegate method for textField"];
	[[NSWorkspace sharedWorkspace] openURL:anURL];
	return YES;
}

-(IBAction)redetectTheme:(id)sender {
    [self detectTheme];
}

-(void)detectTheme {
	HKLowLevel *lowLevel = [[HKLowLevel alloc] init];
	
	if ([[lowLevel appName] isEqualTo: @"Full Tilt Poker"] == YES) {
		FullTiltTheme *currentTheme = [FullTiltInfo determineTheme];
		[logger info:@"Detected FT theme %@", currentTheme];
		while (![currentTheme supported]) {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"Help"];
			[alert addButtonWithTitle:@"Redetect Theme"];
			[alert addButtonWithTitle:@"Quit"];
			[alert setMessageText:[@"BlazingStars does not support your FullTilt table theme: " stringByAppendingString:[currentTheme name]]];
			[alert setInformativeText:@"Supported themes are Racetrack."];
			NSInteger result = [alert runModal];
			if (result == NSAlertThirdButtonReturn) {
				exit(0);
				
			} else if (result == NSAlertFirstButtonReturn) {
				[[NSApplication sharedApplication] showHelp:self];
				
			} else {
				currentTheme = [FullTiltInfo determineTheme];
				[logger info:@"Detected theme %@", currentTheme];
			}
		}
		[themeController setFTTheme:currentTheme];
		[currentThemeLabel setStringValue:[currentTheme name]];		
		
		
	} else {
		PokerStarsTheme *currentTheme = [PokerStarsInfo determineTheme];
		[logger info:@"Detected theme %@", currentTheme];
		while (![currentTheme supported]) {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"Help"];
			[alert addButtonWithTitle:@"Redetect Theme"];
			[alert addButtonWithTitle:@"Quit"];
			[alert setMessageText:[@"BlazingStars does not support your PokerStars table theme: " stringByAppendingString:[currentTheme name]]];
			[alert setInformativeText:@"Supported themes are Classic, Black, Slick, and Hyper-Simple."];
			NSInteger result = [alert runModal];
			if (result == NSAlertThirdButtonReturn) {
				exit(0);
				
			} else if (result == NSAlertFirstButtonReturn) {
				[[NSApplication sharedApplication] showHelp:self];
				
			} else {
				currentTheme = [PokerStarsInfo determineTheme];
				[logger info:@"Detected theme %@", currentTheme];
			}
		}
		[themeController setPsTheme:currentTheme];
		[currentThemeLabel setStringValue:[currentTheme name]];		
	}

}
     
-(IBAction)setPotBetAmount:(id)sender
{
	switch ([sender tag]) {
		case 17:
			[potStepperOneField setFloatValue:[sender floatValue]];
			[potStepperOne setFloatValue:[sender floatValue]];
			[appController setPotBetAmount:[sender floatValue] forTag:[sender tag]];
			break;
		case 18:
			[potStepperTwoField setFloatValue:[sender floatValue]];
			[potStepperTwo setFloatValue:[sender floatValue]];			
			[appController setPotBetAmount:[sender floatValue] forTag:[sender tag]];
			break;
		case 19:
			[potStepperThreeField setFloatValue:[sender floatValue]];
			[potStepperThree setFloatValue:[sender floatValue]];			
			[appController setPotBetAmount:[sender floatValue] forTag:[sender tag]];
			break;
		case 20:
			[potStepperFourField setFloatValue:[sender floatValue]];
			[potStepperFour setFloatValue:[sender floatValue]];			
			[appController setPotBetAmount:[sender floatValue] forTag:[sender tag]];
			break;
		case 21:
			[potStepperFiveField setFloatValue:[sender floatValue]];
			[potStepperFive setFloatValue:[sender floatValue]];			
			[appController setPotBetAmount:[sender floatValue] forTag:[sender tag]];
			break;
		case 22:
			[potStepperSixField setFloatValue:[sender floatValue]];
			[potStepperSix setFloatValue:[sender floatValue]];			
			[appController setPotBetAmount:[sender floatValue] forTag:[sender tag]];
			break;
		default:
			break;
	}
}

-(IBAction)setPFRAmount:(id)sender
{
	switch ([sender tag]) {
		case 25:
			[pfrStepperOneField setFloatValue:[sender floatValue]];
			[pfrOneStepper setFloatValue:[sender floatValue]];
			[appController setPFRAmount:[sender floatValue] forTag:[sender tag]];	
			break;
		case 26:
			[pfrStepperTwoField setFloatValue:[sender floatValue]];
			[pfrTwoStepper setFloatValue:[sender floatValue]];
			[appController setPFRAmount:[sender floatValue] forTag:[sender tag]];	
			break;
		case 27:
			[pfrStepperThreeField setFloatValue:[sender floatValue]];
			[pfrThreeStepper setFloatValue:[sender floatValue]];
			[appController setPFRAmount:[sender floatValue] forTag:[sender tag]];	
			break;
		case 28:
			[pfrStepperFourField setFloatValue:[sender floatValue]];
			[pfrFourStepper setFloatValue:[sender floatValue]];
			[appController setPFRAmount:[sender floatValue] forTag:[sender tag]];	
			break;
		case 29:
			[pfrStepperFiveField setFloatValue:[sender floatValue]];
			[pfrFiveStepper setFloatValue:[sender floatValue]];
			[appController setPFRAmount:[sender floatValue] forTag:[sender tag]];	
			break;
		default:
			break;
			
	}
}

-(IBAction)setRoundingAmount:(id)sender
{
	[roundingStepper setFloatValue:[sender floatValue]];
	[roundingTextField setFloatValue:[roundingStepper floatValue]];
	[appController setRoundingAmount:[sender floatValue]];
}

-(IBAction)setRoundingType:(id)sender
{
	[appController setRoundingType:[sender selectedRow]];
}

-(IBAction)voiceCommandsChangedState:(id)sender
{
	[appController voiceCommandsChangedState];
}

/* 
 * DBPrefsWindowController overrides. 
 */

-(void)setupToolbar
{
	[self addView:basicKeysPrefsView label:@"Basic Keys"];
	[self addView:potBetPrefsView label:@"Pot Bets"];
	[self addView:windowView label:@"Windows"];
	[self addView:openClosePrefsView label:@"Open:Close"];
	[self addView:setupPrefsView label:@"Setup"];
	[self addView:advancedPrefsView label:@"Advanced"];
}

// Need to override this to set the window delegate.  
- (IBAction)showWindow:(id)sender 
{
	[super showWindow:sender];
	[[self window] setDelegate:self];
	[[self window] makeKeyAndOrderFront:sender];
}

-(IBAction)resetDefaults:(id)sender
{
	[logger info:@"Resetting defaults to factory state!"];
	
	NSAlert *alert = [NSAlert alertWithMessageText:@"Are you sure you want to permanently restore the default settings?"
					defaultButton:@"Restore Defaults" 
				  alternateButton:@"Cancel" 
					  otherButton:nil 
		informativeTextWithFormat:@"You can't undo this action."];
	
	if ([alert runModal] == NSAlertAlternateReturn)
		return;
	
	BOOL autoChecks = [[NSUserDefaults standardUserDefaults] boolForKey:@"SUEnableAutomaticChecks"];
	
	[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:@"com.fullyfunctional.blazingstars"];
	[NSUserDefaults resetStandardUserDefaults];
	[NSUserDefaults standardUserDefaults];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *shortcutDefaults = [NSMutableDictionary dictionary];
	
	KeyCombo kc;
	
	kc.code = 3; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"FoldKey"];
	kc.code = 8; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"CallKey"];
	kc.code = 11; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"BetKey"];
	kc.code = 12; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"CheckFoldKey"];	
	kc.code = 13; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"FoldToAnyKey"];	
	kc.code = 45; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"FoldToAnyLeftKey"];		
	kc.code = 14; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"CheckCallKey"];	
	kc.code = 15; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"CheckCallAnyKey"];	
	kc.code = 17; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"BetRaiseKey"];	
	kc.code = 16; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"BetRaiseAnyKey"];	
	kc.code = 35; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"SitOutKey"];		
	kc.code = 33; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"AutoPostKey"];	
	kc.code = 30; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"SitOutAllTablesKey"];
	kc.code = 126; kc.flags = 10486016; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"IncrementKey"];	
	kc.code = 125; kc.flags = 10486016; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"DecrementKey"];	
	kc.code = 37; kc.flags = 0; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"leaveTable"];	
	kc.code = 37; kc.flags = 1179914; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"leaveAllTables"];	
	kc.code = 0; kc.flags = 1179914; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"AllInKey"];		
	kc.code = 35; kc.flags = 1573160; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"ToggleAllKey"];	
	kc.code = 40; kc.flags = 1048840; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"DebugKey"];		
	
	kc.code = 19; kc.flags = 1048840; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"PotBetOneKey"];		
	kc.code = 20; kc.flags = 1048840; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"PotBetTwoKey"];	
	kc.code = 21; kc.flags = 1048840; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"PotBetThreeKey"];		
	kc.code = 23; kc.flags = 1048840; [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"PotBetFourKey"];	
	kc.code = 49; kc.flags = 256;     [shortcutDefaults setObject:[NSData dataWithBytes:&kc length:sizeof(KeyCombo)] forKey:@"PFRKey"];
	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:25.0] forKey:@"potBetOneKey"];
	[shortcutDefaults setObject:[NSNumber numberWithFloat:50.0] forKey:@"potBetTwoKey"];
	[shortcutDefaults setObject:[NSNumber numberWithFloat:75.0] forKey:@"potBetThreeKey"];
	[shortcutDefaults setObject:[NSNumber numberWithFloat:100.0] forKey:@"potBetFourKey"];	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:125.0] forKey:@"potBetFiveKey"];	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:150.0] forKey:@"potBetSixKey"];	
	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:2.5] forKey:@"pfrOneKey"];	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:3.0] forKey:@"pfrTwoKey"];	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:4.0] forKey:@"pfrThreeKey"];	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:5.0] forKey:@"pfrFourKey"];	
	[shortcutDefaults setObject:[NSNumber numberWithFloat:6.0] forKey:@"pfrFiveKey"];	

	NSColor *aColor = [NSColor yellowColor];
	NSData *theData=[NSArchiver archivedDataWithRootObject:aColor];
	[shortcutDefaults setObject:theData forKey:@"windowFrameColourKey"];
	
    [defaults registerDefaults:shortcutDefaults];
	
	// Need to set a few keys by hand;  this is obviously not the first time we've run
	// the program, so disable the "intro" stuff.
	[defaults setBool:YES forKey:@"FirstRunCompletedKey"];
	[defaults setBool:YES forKey:@"SUHasLaunchedBefore"];
	[defaults setBool:autoChecks forKey:@"SUEnableAutomaticChecks"];
	
	[NSUserDefaults resetStandardUserDefaults];
	[NSUserDefaults standardUserDefaults];
	
	[self populateControls];
}


/*
 * Hot key functions.
 */
- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	NSData *key = [NSData dataWithBytes:&newKeyCombo length:sizeof(KeyCombo)];
	[[NSUserDefaults standardUserDefaults] setObject:key
											  forKey: [[tagDict objectForKey:[NSValue valueWithPointer:aRecorder]] objectAtIndex:SRKEY]];
	[appController hkChangedFor:aRecorder withTag:[[[tagDict objectForKey:[NSValue valueWithPointer:aRecorder]] objectAtIndex:SRTAG] intValue]];
}

@end
