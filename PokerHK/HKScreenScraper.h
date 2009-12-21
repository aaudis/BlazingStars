//
//  HKScreenScraper.h
//  PokerHK
//
//  Created by Steven Hamblin on 16/06/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HKDefines.h"
#import "HKDispatchController.h"
#import "HKWindowManager.h"

@class HKDispatchController;
@class HKWindowManager;

@interface HKScreenScraper : NSObject {
	pid_t pokerstarsPID;
	AXUIElementRef appRef;
	IBOutlet HKDispatchController *dc;
	IBOutlet HKWindowManager *windowManager;
	NSString *currencyName;
}

@property (nonatomic, retain) NSString *currencyName;

-(float)getPotSize;

@end
