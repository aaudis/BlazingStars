//
//  HKThemeController.h
//  PokerHK
//
//  Created by Steven Hamblin on 07/06/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SOLogger/SOLogger.h>
#import "PrefsWindowController.h"
#import "PokerStarsInfo.h"
#import "PokerStarsTheme.h"
#import "FullTiltInfo.h"
#import "FullTiltTheme.h"

@class PrefsWindowController;

@interface HKThemeController : NSObject {
    PokerStarsTheme *psTheme;
	FullTiltTheme *ftTheme;
	NSDictionary *themeDict;
	
	SOLogger *logger;
}
-(id)param:(NSString *)key;
-(void)setPsTheme:(PokerStarsTheme *)thePsTheme;
-(PokerStarsTheme *)psTheme;
-(void)setFTTheme:(FullTiltTheme *)theFTTheme;
-(FullTiltTheme *)ftTheme;


@end
