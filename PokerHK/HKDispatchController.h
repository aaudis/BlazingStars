//
//  HKDispatchController.h
//  PokerHK
//
//  Created by Steven Hamblin on 31/05/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HKThemeController.h"
#import "ShortcutRecorder.h"
#import "PrefsWindowController.h"
#import "HKScreenScraper.h"
#import "HKWindowManager.h"

#define HKFold 1
#define HKCall 2
#define HKBet  3

#define HKSmallBlind 0
#define HKBigBlind 1
#define HKGameType 2

@class HKThemeController;
@class PrefsWindowController;
@class HKScreenScraper;
@class HKWindowManager;

@interface HKDispatchController : NSObject {
	NSMutableDictionary *fieldMap;
	NSDictionary *keyMap;
	NSMutableDictionary *potBetAmounts;
	pid_t pokerstarsPID;
	AXUIElementRef appRef;	
	AXUIElementRef systemWideElement;
	AXObserverRef keyObserver;	
	IBOutlet HKThemeController *themeController;
	float amountToChange;
	PrefsWindowController *prefsWindowController;
	IBOutlet HKScreenScraper *screenScraper;
	IBOutlet HKWindowManager *windowManager;
	EventHandlerRef hotkeyEventHandlerRef;
	EventHandlerRef mouseEventHandlerRef;
	BOOL rounding;
	float roundingAmount;
	int roundingType;
	BOOL autoBetRounding;
	BOOL autoBetAllIn;
	BOOL toggled;
}

@property (copy) NSDictionary *keyMap;
@property BOOL toggled;

-(void)setPotBetAmount:(float)amount forTag:(int)tag;
-(void)turnOnRounding:(BOOL)round;
-(void)setRoundingAmount:(float)amount;
-(void)setRoundingType:(int)type;
-(void)autoBetRounding:(BOOL)aBool;
-(void)autoBetAllIn:(BOOL)aBool;
-(void)registerHotKeyForControl:(SRRecorderControl *)control withTag:(int)tag;
-(void)buttonPress:(NSString *)prefix withButton:(NSString *)size;
-(void)buttonPressAllTables:(int)tag;
-(float)getBetSize;
-(float)betIncrement;
-(void)setBetSize:(float)amount;
-(void)incrementBetSize:(long)delta;
-(void)decrementBetSize:(long)delta;
-(void)registerAllHotKeys;
-(void)unregisterAllHotKeys;
-(void)toggleAllHotKeys;
-(void)activateHotKeys;
-(void)deactivateHotKeys;
-(void)potBet:(int)tag;
-(void)leaveAllTables;
-(void)sitOutAllTables;
-(void)debugHK;
@end
