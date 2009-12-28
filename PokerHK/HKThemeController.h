//
//  HKThemeController.h
//  PokerHK
//
//  Created by Steven Hamblin on 07/06/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrefsWindowController.h"
#import "PokerStarsInfo.h"
#import "PokerStarsTheme.h"

@class PrefsWindowController;

@interface HKThemeController : NSObject {
    PokerStarsTheme *psTheme;
	NSDictionary *themeDict;
}
-(NSDictionary *)themeDictionary:(NSString *)themeName;
-(id)param:(NSString *)key;
-(void)setPsTheme:(PokerStarsTheme *)thePsTheme;
-(PokerStarsTheme *)psTheme;


@end
