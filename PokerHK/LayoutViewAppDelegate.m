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
- (void) redrawPosBox;
@end;

@implementation LayoutViewAppDelegate

@synthesize window, themeButton, imageButton, itemButton, commitButton, themes, imageView, items, posView, contentView, plist;
@synthesize xSlider, ySlider, wSlider, hSlider;

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
    self.plist = nil;

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
    [self itemChanged:self.itemButton];
}

- (IBAction) itemChanged:(id)sender
{
    NSDictionary *item = [self.items objectAtIndex:[self.itemButton indexOfSelectedItem]];
    NSString *name = [item objectForKey:@"n"];
    
    CGFloat xPct= [[self.plist objectForKey:[name stringByAppendingString:@"OriginX"]] floatValue];
    CGFloat yPct = [[self.plist objectForKey:[name stringByAppendingString:@"OriginY"]] floatValue];
    CGFloat wPct;
    CGFloat hPct;
    
    if ([[item objectForKey:@"s"] isEqualToString:@"l"]) {
        wPct = [[self.plist objectForKey:@"bigButtonWidth"] floatValue];
        hPct = [[self.plist objectForKey:@"bigButtonHeight"] floatValue];
    }
    else if ([[item objectForKey:@"s"] isEqualToString:@"s"]) {
        wPct = [[self.plist objectForKey:@"smallButtonWidth"] floatValue];
        hPct = [[self.plist objectForKey:@"smallButtonHeight"] floatValue];
    }
    /*
        pot box is handled different, using absolute pixels
    else if ([[item objectForKey:@"s"] isEqualToString:@"p"]) {
        wPct = [[self.plist objectForKey:@"potBoxWidth"] floatValue];
        hPct = [[self.plist objectForKey:@"potBoxHeight"] floatValue];
    }
     */
    else if ([[item objectForKey:@"s"] isEqualToString:@"b"]) {
        wPct = [[self.plist objectForKey:@"betBoxWidth"] floatValue];
        hPct = [[self.plist objectForKey:@"betBoxHeight"] floatValue];
    }    
    
    self.xSlider.doubleValue = xPct;
    self.ySlider.doubleValue = 1 - yPct;
    self.wSlider.doubleValue = wPct;
    self.hSlider.doubleValue = hPct;
    
    [self redrawPosBox];
}

- (void) redrawPosBox
{
    NSSize imgSize = self.imageView.image.size;
    CGFloat imgRatio = imgSize.width / imgSize.height;
    CGFloat viewRatio = self.imageView.frame.size.width / self.imageView.frame.size.height;
    
    CGFloat imgH, imgW;
    
    if (imgRatio > viewRatio) {
        // use view height
        imgH = self.imageView.frame.size.height;
        imgW = imgH * imgRatio;
    }
    else {
        // use view width
        imgW = self.imageView.frame.size.width;
        imgH = imgW / imgRatio;
    }
    
    CGFloat x = imgW * self.xSlider.doubleValue;
    CGFloat y = imgH * self.ySlider.doubleValue;
    CGFloat w = imgW * self.wSlider.doubleValue;
    CGFloat h = imgH * self.hSlider.doubleValue;
    
    self.posView.frame = NSMakeRect(self.imageView.frame.origin.x + x, self.imageView.frame.origin.y + y - h, w, h);
    [self.posView needsDisplay];
}

- (IBAction) sliderChanged:(id)sender
{
    NSDictionary *item = [self.items objectAtIndex:[self.itemButton indexOfSelectedItem]];
    NSString *name = [item objectForKey:@"n"];
    
    [self.plist setObject:[NSNumber numberWithDouble:self.xSlider.doubleValue] forKey:[name stringByAppendingString:@"OriginX"]];
    [self.plist setObject:[NSNumber numberWithDouble:1 - self.ySlider.doubleValue] forKey:[name stringByAppendingString:@"OriginY"]];

    NSString *wKey = @"", *hKey = @"";
    if ([[item objectForKey:@"s"] isEqualToString:@"l"]) {
        wKey = @"bigButtonWidth";
        hKey = @"bigButtonHeight";
    }
    else if ([[item objectForKey:@"s"] isEqualToString:@"s"]) {
        wKey = @"smallButtonWidth";
        hKey = @"smallButtonHeight";
    }
    else if ([[item objectForKey:@"s"] isEqualToString:@"b"]) {
        wKey = @"betBoxWidth";
        hKey = @"betBoxHeight";
    }    
    
    if ([wKey length] > 0) {
        [self.plist setObject:[NSNumber numberWithDouble:self.wSlider.doubleValue] forKey:wKey];
    }
    
    if ([hKey length] > 0) {
        [self.plist setObject:[NSNumber numberWithDouble:self.hSlider.doubleValue] forKey:hKey];
    }

    [self redrawPosBox];
}

- (NSArray *) themes
{
    if (themes == nil) {
        // @todo should be able to auto-fetch all of these from theme manager
        themes = [[NSArray arrayWithObjects:
                   [[[PokerStarsTheme alloc] initWithName:@"Classic" supported:YES] autorelease],
                   [[[PokerStarsTheme alloc] initWithName:@"Hyper-Simple" supported:YES] autorelease],
                   [[[PokerStarsTheme alloc] initWithName:@"Black" supported:YES] autorelease],
                   [[[PokerStarsTheme alloc] initWithName:@"Shiny" supported:YES] autorelease],
                   [[[PokerStarsTheme alloc] initWithName:@"Slick" supported:YES] autorelease],
                   [[[PokerStarsTheme alloc] initWithName:@"Renaissance" supported:YES] autorelease],
                  nil] retain];
    }
    
    return themes;
}

- (NSArray *) items
{
    if (items == nil) {
        items = [[NSMutableArray arrayWithObjects:
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Big Button: Bet", @"t", @"bet", @"n", @"l", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Big Button: Call", @"t", @"call", @"n", @"l", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Big Button: Fold", @"t", @"fold", @"n", @"l", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Big Button: Time Bank", @"t", @"timeBank", @"n", @"l", @"s", nil],
                  
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Small Button: Check/Fold", @"t", @"checkFold", @"n", @"s", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Small Button: Check/Call", @"t", @"checkCall", @"n", @"s", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Small Button: Check/Call Any", @"t", @"checkCallAny", @"n", @"s", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Small Button: Fold to Any", @"t", @"foldToAny", @"n", @"s", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Small Button: Bet/Raise", @"t", @"betRaise", @"n", @"s", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Small Button: Bet/Raise Any", @"t", @"betRaiseAny", @"n", @"s", @"s", nil],

                  [NSDictionary dictionaryWithObjectsAndKeys:@"Left Button: Fold to Any", @"t", @"foldToAnyLeft", @"n", @"s", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Left Button: Sit Out Next Hand", @"t", @"sitOutNextHand", @"n", @"s", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Left Button: Auto-Post/Sit Out", @"t", @"autoPostSitOut", @"n", @"s", @"s", nil],

                  [NSDictionary dictionaryWithObjectsAndKeys:@"Other: Leave Table", @"t", @"leaveTable", @"n", @"s", @"s", nil],
                  //[NSDictionary dictionaryWithObjectsAndKeys:@"Other: Pot Box", @"t", @"potBox", @"n", @"p", @"s", nil],
                  [NSDictionary dictionaryWithObjectsAndKeys:@"Other: Bet Box", @"t", @"betBox", @"n", @"b", @"s", nil],
                  
                  nil] retain];
    }
    
    return items;
}

- (IBAction) getPlist:(id)sender
{
    NSData *xmlData = [NSPropertyListSerialization dataFromPropertyList:self.plist format:kCFPropertyListXMLFormat_v1_0 errorDescription:nil];
    NSString *s = [[[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding] autorelease];

    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSArray *types = [NSArray arrayWithObject:NSStringPboardType];
    
    [pb declareTypes:types owner:self];
    [pb setString:s forType:NSStringPboardType];
    
    NSAlert *alert = [NSAlert alertWithMessageText:@"Plist data copied to clipboard" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Plist data copied to clipboard"];
    [alert runModal];
}

- (NSMutableDictionary *) plist
{
    if (plist == nil) {
        PokerStarsTheme *theme = [self.themes objectAtIndex:[self.themeButton indexOfSelectedItem]];
        plist = [theme.themeDict mutableCopy];
    }
    
    return plist;
}

@end
