//
//  AppController.h
//  PokerHK
//
//  Created by Steven Hamblin on 29/05/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrefsWindowController.h"
#import "HKDispatchController.h"
#import "HKWindowManager.h"
#import "HKLowLevel.h"
#import "ShortcutRecorder.h"
#import "HKDefines.h";
//@class PrefsWindowController;
@class AboutWindowController;
@class HKDispatchController;
@class HKWindowManager;


@interface AppController : NSObject {
	IBOutlet HKDispatchController *dispatchController;
	IBOutlet HKWindowManager *windowManager;
	IBOutlet HKLowLevel *lowLevel;
    AboutWindowController *aboutWindowController;
}
-(void)finishedLaunching:(NSNotification *)notification;
-(IBAction)openPreferences:(id)sender;
-(IBAction)openAboutPanel:(id)sender;
-(IBAction)displayDonate:(id)sender;
-(void)hkChangedFor:(SRRecorderControl *)control withTag:(int)tag;
-(void)voiceCommandsChangedState;
-(void)setPotBetAmount:(float)amount forTag:(int)tag;
-(void)setPFRAmount:(float)amount forTag:(int)tag;
-(void)setRoundingAmount:(float)amount;
-(void)setRoundingType:(int)type;
@end
