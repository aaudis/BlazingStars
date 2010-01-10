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
	
	logger = [SOLogger loggerForFacility:@"com.fullyfunctionalsoftware.blazingstars" options:ASL_OPT_STDERR];
	[logger info:@"Initializing themeController."];
	
    return self;
}

-(void)awakeFromNib {
}

-(PokerStarsTheme *)psTheme {
    return psTheme;
}

-(void)setPsTheme:(PokerStarsTheme *)thePsTheme
{
	[logger info:@"Setting theme: %@",thePsTheme];
	psTheme = thePsTheme;
}

-(id)param:(NSString *)key
{
	return [[psTheme themeDict] objectForKey:key];
}

@end
