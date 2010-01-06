//
//  HKWindowManager.h
//  PokerHK
//
//  Created by Steven Hamblin on 09/06/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HKDefines.h"
#import "HKDispatchController.h"
#import "HKThemeController.h"

enum {
	HKNotTable = 0,
	HKTournamentTable = 1,
	HKTournamentLobby = 2,
	HKTournamentPopup = 3,
	HKHoldemCashTable = 4,
	HKGeneralTable = 5,
	HKTournamentRegistration = 6,
	HKTablePopup = 7,
	HKPLOTable = 8,
};



#define HKSizePos 0

@class HKDispatchController;
@class HKThemeController;

@interface HKWindowManager : NSObject {
//	pid_t pokerstarsPID;
	AXObserverRef observer;
//	AXUIElementRef appref;
	
	IBOutlet HKDispatchController *dispatchController;
	IBOutlet HKThemeController *themeController;
	
	NSMutableDictionary *windowDict;
	BOOL activated;
}

@property BOOL activated;

-(void)debugWindow:(NSRect)windowRect;
-(void)clickPointForXSize:(float)xsize andYSize:(float)ysize andHeight:(float)height andWidth:(float)width;
-(NSPoint)getClickPointForXSize:(float)xsize andYSize:(float)ysize andHeight:(float)height andWidth:(float)width;
-(BOOL)pokerWindowIsActive;
-(int)windowIsTable:(AXUIElementRef)windowRef;
-(int)windowIsTableAtOpening:(AXUIElementRef)windowRef;
-(AXUIElementRef)getMainWindow;
-(NSArray *)getAllPokerTables;
-(NSRect)getWindowBounds:(AXUIElementRef)windowRef;
-(NSRect)getPotBounds:(AXUIElementRef)windowRef;
-(NSArray *)getGameParameters;
-(double)findTournamentNum:(NSString *)title inLobby:(BOOL)lobbyBool;
-(void)windowDidOpen:(AXUIElementRef)elementRef;
-(void)windowDidResize:(AXUIElementRef)elementRef;
-(void)windowDidClose:(AXUIElementRef)elementRef;
-(void)applicationDidActivate;
-(void)applicationDidDeactivate;
-(void)appTerminated:(NSNotification *)note;
@end
