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
}

-(void)setTheme:(NSString *)theTheme
{
	NSLog(@"Setting theme: %@",theTheme);
	theme = [theTheme copy];
	themeDict = [self themeDictionary:theme];
	NSLog(@"Theme dict is: %@", themeDict);
}

-(PokerStarsTheme *)psTheme {
    return psTheme;
}

-(void)setPsTheme:(PokerStarsTheme *)thePsTheme
{
	NSLog(@"Setting theme: %@",thePsTheme);
	psTheme = thePsTheme;
    NSString *selectedThemeName = [psTheme name];
	[self setTheme:selectedThemeName];
}

-(id)param:(NSString *)key
{
	return [themeDict objectForKey:key];
}

@end
