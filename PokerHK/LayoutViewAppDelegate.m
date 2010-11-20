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

@synthesize window, themeButton, imageButton, itemButton, commitButton, themes, imageView;


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

@end
