//
//  HKThemeController.m
//  PokerHK
//
//  Created by Steven Hamblin on 07/06/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import "HKThemeController.h"
#import "PrefsWindowController.h"


@implementation HKThemeController

@synthesize theme;

-(NSDictionary *)themeDictionary:(NSString *)themeName
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] 
													pathForResource:themeName ofType: @"plist"]];
	return dict;
}

-(void)awakeFromNib
{
	[[PrefsWindowController sharedPrefsWindowController] setThemeController:self];
	NSArray *themes = [NSArray arrayWithObjects:@"Hyper-Simple",@"Slick",@"Black",nil];
	NSInteger defaultIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"themeKey"];
	NSString *selectedTheme = [themes objectAtIndex:defaultIndex];
	NSLog(@"Getting the theme in themeController: %@",selectedTheme);
	[self setTheme:selectedTheme];	
}

-(void)setTheme:(NSString *)theTheme
{
	NSLog(@"Setting theme: %@",theTheme);
	theme = [theTheme copy];
	themeDict = [self themeDictionary:theme];
	NSLog(@"Theme dict is: %@", themeDict);
	
	// Hyper-simple theme support is still a little buggy, so we'll warn them once.
	if ([theme isEqual:@"Hyper-Simple"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"hsWarningKey"]) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert addButtonWithTitle:@"Don't warn again"];
		[alert setMessageText:@"Warning - support for Hyper-Simple pot-betting is currently buggy!"];
		[alert setInformativeText:@"Use of pot betting for the Hyper-Simple theme is not currently recommended.  Use at your own risk, especially if you have selected the automatic bet option."];
		if ([alert runModal] == NSAlertSecondButtonReturn) {
			NSLog(@"Stifling warning!");
			[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"hsWarningKey"];
		};
		
		
	}
}

-(id)param:(NSString *)key
{
	return [themeDict objectForKey:key];
}

@end
