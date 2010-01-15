//
//  HKDispatchController.h
//  PokerHK
//
//  Created by Steven Hamblin on 31/05/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SOLogger/SOLogger.h>
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
	SOLogger *logger;
	NSMutableDictionary *fieldMap;
	NSDictionary *keyMap;
	NSDictionary *speechCommands;
	NSMutableDictionary *potBetAmounts, *pfrAmounts;
	float pfrAmount;
	AXUIElementRef systemWideElement;
	AXObserverRef keyObserver;	
	float amountToChange;
	PrefsWindowController *prefsWindowController;
	IBOutlet HKScreenScraper *screenScraper;
	IBOutlet HKWindowManager *windowManager;
	IBOutlet HKThemeController *themeController;
	IBOutlet HKLowLevel *lowLevel;
	EventHandlerRef hotkeyEventHandlerRef;
	EventHandlerRef mouseEventHandlerRef;
	float roundingAmount;
	int roundingType;
	BOOL toggled;
	NSSpeechRecognizer* speechRecognizer;
}

@property (copy) NSDictionary *keyMap;
@property BOOL toggled;

-(void)setPotBetAmount:(float)amount forTag:(int)tag;
-(void)setPFRAmount:(float)amount forTag:(int)tag;
-(void)setRoundingAmount:(float)amount;
-(void)setRoundingType:(int)type;
-(BOOL)keyComboAlreadyRegistered:(KeyCombo)kc; 
-(void)registerHotKeyForControl:(SRRecorderControl *)control withTag:(int)tag;
-(void)buttonPress:(NSString *)prefix withButton:(NSString *)size;
-(void)buttonPress:(NSString *)prefix withButton:(NSString *)size onTable:(AXUIElementRef)tableRef;
-(void)buttonPressAllTables:(int)tag;
-(void)autoBet;
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
-(void)simulateHotKey:(int)tag;
-(void)potBet:(int)tag;
-(void)pfr:(int)tag;
-(void)leaveAllTables;
-(void)sitOutAllTables;
-(void)debugHK;
-(void)voiceCommandsChangedState;
@end
