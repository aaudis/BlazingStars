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
}

-(id)param:(NSString *)key
{
	return [[psTheme themeDict] objectForKey:key];
}

@end
