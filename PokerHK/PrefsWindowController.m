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
@synthesize themes;
@synthesize selectedTheme;
@synthesize radiobuttonMatrix;
@synthesize stepper;
@synthesize scrollWheelCheckBox;

-(void)awakeFromNib
{
	themes = [NSArray arrayWithObjects:@"Hyper-Simple",@"Slick",@"Black",nil];
	NSInteger defaultIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"themeKey"];
	selectedTheme = [themes objectAtIndex:defaultIndex];
	NSLog(@"defaultIndex: %d selectedTheme: %@",defaultIndex,selectedTheme);
	[themeController setTheme:selectedTheme];

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
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:21],@"AllInKey",nil],[NSValue valueWithPointer:allIn],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:22],@"ToggleAllKey",nil],[NSValue valueWithPointer:toggleAllHotkeys],
			   [NSArray arrayWithObjects:[NSNumber numberWithInt:99],@"DebugKey",nil],[NSValue valueWithPointer:debugHK],			   
			   nil];
	
	SRRecorderControl *sc; 	KeyCombo key;
	for (id tag in [tagDict allKeys]) {
		sc = [tag pointerValue];
		[sc setAnimates:YES];
		[sc setStyle:(SRRecorderStyle)SRGreyStyle];
		[sc setAllowsKeyOnly:YES escapeKeysRecord:NO];
		
		NSString *dictKey = [[tagDict objectForKey:tag] objectAtIndex:SRKEY];
		NSLog(@"Attempting to find key: %@",dictKey);
		if ([[NSUserDefaults standardUserDefaults] objectForKey:dictKey] != nil) {
			[[[NSUserDefaults standardUserDefaults] objectForKey:dictKey] getBytes:&key length:sizeof(KeyCombo)];
			[sc setKeyCombo:key];
			NSLog(@"code: %d flags: %d",key.code,key.flags);
		} else {
			KeyCombo k = [sc keyCombo];
			[[NSUserDefaults standardUserDefaults] setObject:[NSData dataWithBytes:&k length:sizeof(KeyCombo)] forKey:dictKey];
		}
	}	
	
	// Set up the pot bet fields.
	for (int i = 17; i < 21; i++) {
		[self setPotBetAmount:[potBetPrefsView viewWithTag:i]];
	}

	// Trigger the rounding controls.
	[self turnOnRounding:[potBetPrefsView viewWithTag:ROUNDINGONTAG]];
	[self setRoundingAmount:[potBetPrefsView viewWithTag:ROUNDINGAMOUNTTAG]];
	[self setRoundingType:[potBetPrefsView viewWithTag:ROUNDINGTYPETAG]];
	[self autoBetRounding:[potBetPrefsView viewWithTag:AUTOBETROUNDINGTAG]];
		
	[self autoBetAllIn:[potBetPrefsView viewWithTag:AUTOBETALLINTAG]];
	
}

-(IBAction)setThemeFromMenu:(id)sender
{
	NSLog(@"Item: %@",[[sender selectedItem] title]);
	[self setSelectedTheme:[[sender selectedItem] title]];
	[themeController setTheme:selectedTheme];
}

-(IBAction)setPotBetAmount:(id)sender
{
	NSLog(@"Changing pet bot amount to %f: ",[sender floatValue]);
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
		default:
			NSLog(@"setPotBetAmount:  why am I here? %d",[sender tag]);
			break;
	}
}

-(IBAction)turnOnRounding:(id)sender
{
	[appController turnOnRounding:[sender state]];
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

-(IBAction)autoBetRounding:(id)sender
{
	[appController autoBetRounding:[sender state]];
}

-(IBAction)autoBetAllIn:(id)sender
{
	[appController autoBetAllIn:[sender state]];
}

/* 
 * DBPrefsWindowController overrides. 
 */

-(void)setupToolbar
{
	[self addView:basicKeysPrefsView label:@"Basic Keys"];
	[self addView:potBetPrefsView label:@"Pot Bets"];
	[self addView:openClosePrefsView label:@"Open:Close"];
	[self addView:setupPrefsView label:@"Setup"];
	[self addView:advancedPrefsView label:@"Advanced"];
}

// Need to override this to set the window delegate.  
- (IBAction)showWindow:(id)sender 
{
	[super showWindow:sender];
	NSLog(@"Setting the delegate!");
	[[self window] setDelegate:self];
	[[self window] makeKeyAndOrderFront:sender];
}



/*
 * Hot key functions.
 */
- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	NSLog(@"Hot key captured in SRRC!");
	NSData *key = [NSData dataWithBytes:&newKeyCombo length:sizeof(KeyCombo)];
	[[NSUserDefaults standardUserDefaults] setObject:key
											  forKey: [[tagDict objectForKey:[NSValue valueWithPointer:aRecorder]] objectAtIndex:SRKEY]];
	[appController hkChangedFor:aRecorder withTag:[[[tagDict objectForKey:[NSValue valueWithPointer:aRecorder]] objectAtIndex:SRTAG] intValue]];
}


@end
