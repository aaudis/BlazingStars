//
//  Menulet.m
//  PokerHK
//
//  Created by Steven Hamblin on 29/05/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import "Menulet.h"

@implementation Menulet

@synthesize statusItem;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

	[CMCrashReporter check];
}

- (void) setMenuImage
{
	// Get image file.
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSString *path;
    
    if (dc.toggled) {
        path = [bundle pathForResource:@"icon-menulet" ofType:@"png"];
    }
    else {
        path = [bundle pathForResource:@"icon-menulet-disabled" ofType:@"png"];
    }

    NSImage *image = [[NSImage alloc] initWithContentsOfFile:path];
    
    [self.statusItem setImage:image];
    [image release];
}

- (NSStatusItem *) statusItem
{
    if (statusItem == nil) {
        statusItem = [[[NSStatusBar systemStatusBar] 
                       statusItemWithLength:NSVariableStatusItemLength] retain];
        [statusItem setTitle:[NSString stringWithString:@""]]; 
        [statusItem setHighlightMode:YES];
        [statusItem setEnabled:YES];
        [statusItem setToolTip:@"PokerHK"];
        [statusItem setMenu:theMenu];	
    }
    
    return statusItem;
}

- (void)awakeFromNib
{
    [self setMenuImage];
}

@end
