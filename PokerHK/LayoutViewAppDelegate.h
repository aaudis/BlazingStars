//
//  LayoutViewAppDelegate.h
//  PokerHK
//
//  Created by Quentin Zervaas on 20/11/10.
//  Copyright 2010 Zervaas Enterprises. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface LayoutViewAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
    
    NSPopUpButton *themeButton, *imageButton, *itemButton;
    NSButton *commitButton;
    
    NSArray *themes, *items;
    
    NSImageView *imageView;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) IBOutlet NSPopUpButton *themeButton, *imageButton, *itemButton;
@property (nonatomic, retain) IBOutlet NSButton *commitButton;
@property (nonatomic, retain) NSArray *themes, *items;
@property (nonatomic, retain) IBOutlet NSImageView *imageView;

- (IBAction) themeChanged:(id)sender;
- (IBAction) imageChanged:(id)sender;
- (IBAction) itemChanged:(id)sender;

@end
