//
//  PrefsWindowController.h
//  PokerHK
//
//  Created by Steven Hamblin on 29/05/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SOLogger/SOLogger.h>
#import "DBPrefsWindowController.h"
#import "HKThemeController.h"
#import "AppController.h"
#import "ShortcutRecorder.h"

#define SRTAG 0
#define SRKEY 1

#define ROUNDINGONTAG 900
#define ROUNDINGAMOUNTTAG 901
#define ROUNDINGTYPETAG 902
#define AUTOBETROUNDINGTAG 903
#define AUTOBETALLINTAG 904
#define AUTOPFRTAG 905

@class AppController;
@class HKThemeController;

@interface PrefsWindowController : DBPrefsWindowController {
	SOLogger *logger;
	
	// Subviews to load.
	IBOutlet NSView *basicKeysPrefsView;
	IBOutlet NSView *potBetPrefsView;
	IBOutlet NSView *windowView;
	IBOutlet NSView *openClosePrefsView;
	IBOutlet NSView *setupPrefsView;
	IBOutlet NSView *advancedPrefsView;

	// Outlets to misc. controls.
	IBOutlet NSTextField *changeAmountField;
	IBOutlet NSStepper *stepper;
	IBOutlet NSMatrix *radiobuttonMatrix;
	IBOutlet NSButton *scrollWheelCheckBox;
	IBOutlet NSStepper *potStepperOne;
	IBOutlet NSStepper *potStepperTwo;
	IBOutlet NSStepper *potStepperThree;
	IBOutlet NSStepper *potStepperFour;
	IBOutlet NSTextField *potStepperOneField;
	IBOutlet NSTextField *potStepperTwoField;
	IBOutlet NSTextField *potStepperThreeField;
	IBOutlet NSTextField *potStepperFourField;
	IBOutlet NSButton *roundPotCheckBox;
	IBOutlet NSTextField *roundingTextField;
	IBOutlet NSStepper *roundingStepper;
	IBOutlet NSMatrix *roundingMatrix;	
    IBOutlet NSTextField *currentThemeLabel;
	IBOutlet NSColorWell *windowFrameColourWell;
	IBOutlet NSStepper *pfrStepper;
	IBOutlet NSTextField *pfrStepperField;
	IBOutlet NSButton *autoPFRCheckBox;
	
	AppController * appController;
	HKThemeController *themeController;
	
	// hotkey fields.
	// God, this is gross.  I wish that I could do this programmatically.
	NSArray *tagArray;
	NSDictionary *tagDict;
	IBOutlet SRRecorderControl *fold;
	IBOutlet SRRecorderControl *call;
	IBOutlet SRRecorderControl *bet;
	IBOutlet SRRecorderControl *checkFold;
	IBOutlet SRRecorderControl *foldToAny;
	IBOutlet SRRecorderControl *foldToAnyLeft;
	IBOutlet SRRecorderControl *checkCall;
	IBOutlet SRRecorderControl *checkCallAny;
	IBOutlet SRRecorderControl *betRaise;
	IBOutlet SRRecorderControl *betRaiseAny;
	IBOutlet SRRecorderControl *sitOut;
	IBOutlet SRRecorderControl *autoPost;
	IBOutlet SRRecorderControl *sitOutAllTables;
	IBOutlet SRRecorderControl *increment;
	IBOutlet SRRecorderControl *decrement;
	IBOutlet SRRecorderControl *leaveTable;
	IBOutlet SRRecorderControl *leaveAllTables;
	IBOutlet SRRecorderControl *potBetOne;
	IBOutlet SRRecorderControl *potBetTwo;
	IBOutlet SRRecorderControl *potBetThree;
	IBOutlet SRRecorderControl *potBetFour;	
	IBOutlet SRRecorderControl *allIn;
	IBOutlet SRRecorderControl *toggleAllHotkeys;
	IBOutlet SRRecorderControl *debugHK;
	IBOutlet SRRecorderControl *pfr;

}
@property AppController *appController;
@property HKThemeController *themeController;
@property IBOutlet NSMatrix *radiobuttonMatrix;
@property IBOutlet NSStepper *stepper;
@property IBOutlet NSButton *scrollWheelCheckBox;
@property IBOutlet NSColorWell *windowFrameColourWell;

-(IBAction)setPotBetAmount:(id)sender;
-(IBAction)setPFRAmount:(id)sender;
-(IBAction)voiceCommandsChangedState:(id)sender;
-(IBAction)setRoundingAmount:(id)sender;
-(IBAction)setRoundingType:(id)sender;
-(void)detectTheme;
-(IBAction)redetectTheme:(id)sender;
@end
