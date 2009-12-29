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

-(id)init {
    if (![super init]) {
        return nil;
    };
	[[PrefsWindowController sharedPrefsWindowController] setThemeController:self];
    return self;
}

-(void)awakeFromNib {
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
