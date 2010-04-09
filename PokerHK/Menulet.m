//
//  Menulet.m
//  PokerHK
//
//  Created by Steven Hamblin on 29/05/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import "Menulet.h"



@implementation Menulet

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

	[CMCrashReporter check];
}


- (void)awakeFromNib
{
	// Get image file.
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path = [bundle pathForResource:@"icon-menulet" ofType:@"png"];
	menuIcon = [[NSImage alloc] initWithContentsOfFile:path];
	
	statusItem = [[[NSStatusBar systemStatusBar] 
				   statusItemWithLength:NSVariableStatusItemLength] retain];
	[statusItem setTitle:[NSString stringWithString:@""]]; 
	[statusItem setHighlightMode:YES];
	[statusItem setImage:menuIcon];
	[statusItem setEnabled:YES];
	[statusItem setToolTip:@"PokerHK"];
	[statusItem setMenu:theMenu];	

}

@end
