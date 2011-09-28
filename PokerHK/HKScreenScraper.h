//
//  HKScreenScraper.h
//  PokerHK
//
//  Created by Steven Hamblin on 16/06/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SOLogger/SOLogger.h>
#import "HKDefines.h"
#import "HKDispatchController.h"
#import "HKTesseract.h"
#import "HKWindowManager.h"
#import "Foundation/Foundation.h"


@class HKDispatchController;
@class HKWindowManager;

@interface HKScreenScraper : NSObject {
	SOLogger *logger;
    HKTesseract *tesseract;
	IBOutlet HKDispatchController *dc;
	IBOutlet HKWindowManager *windowManager;
	IBOutlet HKLowLevel *lowLevel;
	NSArray *currencyCharacters;
}

@property (nonatomic, retain) NSArray *currencyCharacters;

-(float)getPotSize;
-(NSImage*)imageWithWindow:(int)wid;
-(void)dealloc;

@end
