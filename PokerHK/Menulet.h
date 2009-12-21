//
//  Menulet.h
//  PokerHK
//
//  Created by Steven Hamblin on 29/05/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PrefsWindowController.h"

@interface Menulet : NSObject {
	NSStatusItem *statusItem;
	NSImage *menuIcon;
	IBOutlet NSMenu *theMenu;
	
}

@end
