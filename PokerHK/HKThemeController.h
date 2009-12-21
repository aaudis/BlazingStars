//
//  HKThemeController.h
//  PokerHK
//
//  Created by Steven Hamblin on 07/06/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrefsWindowController.h"

@class PrefsWindowController;

@interface HKThemeController : NSObject {
	NSString *theme;
	NSDictionary *themeDict;
}
@property (copy) NSString *theme;

-(NSDictionary *)themeDictionary:(NSString *)themeName;
-(id)param:(NSString *)key;

@end
