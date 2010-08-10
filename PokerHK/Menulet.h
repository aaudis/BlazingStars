//
//  Menulet.h
//  PokerHK
//
//  Created by Steven Hamblin on 29/05/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrefsWindowController.h"
#import <CMCrashReporter/CMCrashReporter.h>

@interface Menulet : NSObject {
	NSStatusItem *statusItem;
	IBOutlet NSMenu *theMenu;
    IBOutlet HKDispatchController *dc;	
	
}

@property (nonatomic, retain) NSStatusItem *statusItem;

- (void) setMenuImage;

@end
