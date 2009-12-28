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

-(NSDictionary *)themeDictionary:(NSString *)themeName
{
    NSLog(@"Loading themeDictionary for %@", themeName);
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] 
													pathForResource:themeName ofType: @"plist"]];
    NSLog(@"dict = %@", dict);
	return dict;
}

-(void)awakeFromNib
{
	[[PrefsWindowController sharedPrefsWindowController] setThemeController:self];
}

-(PokerStarsTheme *)psTheme {
    return psTheme;
}

-(void)setPsTheme:(PokerStarsTheme *)thePsTheme
{
	NSLog(@"Setting theme: %@",thePsTheme);
	psTheme = thePsTheme;
	themeDict = [self themeDictionary:[psTheme name]];
	NSLog(@"Theme dict is: %@", themeDict);
    
}

-(id)param:(NSString *)key
{
	return [themeDict objectForKey:key];
}

@end
