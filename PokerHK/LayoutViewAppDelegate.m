//
//  LayoutViewAppDelegate.m
//  PokerHK
//
//  Created by Quentin Zervaas on 20/11/10.
//  Copyright 2010 Zervaas Enterprises. All rights reserved.
//

#import "LayoutViewAppDelegate.h"
#import "PokerStarsTheme.h"

@interface LayoutViewAppDelegate()
- (void) setupThemes;
@end;

@implementation LayoutViewAppDelegate

@synthesize window, themeButton, imageButton, itemButton, commitButton, themes, imageView, items;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
    [self setupThemes];
}

- (void) setupThemes
{
    [self.themeButton removeAllItems];
    
    for (PokerStarsTheme *theme in self.themes) {
        [self.themeButton addItemWithTitle:[theme name]];
    }
    
    [self.itemButton removeAllItems];
    
    for (NSDictionary *row in self.items) {
        [self.itemButton addItemWithTitle:[row objectForKey:@"t"]];
    }
    
    [self.themeButton selectItemAtIndex:0];
    [self themeChanged:self.themeButton];
}

- (IBAction) themeChanged:(id)sender
{
    [self.imageButton removeAllItems];
    
    PokerStarsTheme *theme = [self.themes objectAtIndex:[self.themeButton indexOfSelectedItem]];

    NSString *path = [NSString stringWithFormat:@"%@/themes/%@", [[NSBundle mainBundle] resourcePath], [theme name]];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    
    for (NSString *file in files) {
        [self.imageButton addItemWithTitle:file];
    }

    [self.imageButton selectItemAtIndex:0];
    [self imageChanged:self.imageButton];
    
    [self.itemButton selectItemAtIndex:0];
    [self itemChanged:self.itemButton];
}

- (IBAction) imageChanged:(id)sender
{
    PokerStarsTheme *theme = [self.themes objectAtIndex:[self.themeButton indexOfSelectedItem]];
    NSString *filename = [self.imageButton titleOfSelectedItem];
    
    NSString *path = [NSString stringWithFormat:@"%@/themes/%@/%@", [[NSBundle mainBundle] resourcePath], [theme name], filename];

    NSImage *image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
    [self.imageView setImage:image];
}

- (IBAction) itemChanged:(id)sender
{

}

- (NSArray *) themes
{
    if (themes == nil) {
        // @todo should be able to auto-fetch all of these from theme manager
        themes = [[NSArray arrayWithObjects:
                  [[[PokerStarsTheme alloc] initWithName:@"Slick" supported:YES] autorelease],
                  nil] retain];
    }
    
    return themes;
}

- (NSArray *) items
{
    if (items == nil) {
        items = [[NSMutableArray arrayWithObjects:
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Big Button: Bet", @"t", @"bet", @"n", @"b", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Big Button: Call", @"t", @"call", @"n", @"b", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Big Button: Fold", @"t", @"fold", @"n", @"b", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Big Button: Time Bank", @"t", @"timeBank", @"n", @"b", @"s", nil],
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Small Button: Check/Fold", @"t", @"checkFold", @"n", @"s", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Small Button: Check/Call", @"t", @"checkCall", @"n", @"s", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Small Button: Fold to Any", @"t", @"foldToAny", @"n", @"s", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Small Button: Bet/Raise", @"t", @"betRaise", @"n", @"s", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Small Button: Bet/Raise Any", @"t", @"betRaiseAny", @"n", @"s", @"s", nil],

                  [NSDictionary dictionaryWithObjectsAndKeys:@"Left Button: Fold to Any", @"t", @"foldToAnyLeft", @"n", @"s", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Left Button: Sit Out Next Hand", @"t", @"sitOutNextHand", @"n", @"s", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Left Button: Auto-Post/Sit Out", @"t", @"autoPostSitOut", @"n", @"s", @"s", nil],

                  [NSDictionary dictionaryWithObjectsAndKeys:@"Other: Leave Table", @"t", @"leaveTable", @"n", @"s", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Other: Pot Box", @"t", @"potBox", @"n", @"p", @"s", nil],
                  
                  nil] retain];
    }
    
    return items;
}

@end
