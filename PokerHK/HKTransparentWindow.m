//
//  HKTransparentWindow.m
//  PokerHK
//
//  Created by Steven Hamblin on 10-01-06.
//  Copyright 2010 Steven Hamblin. All rights reserved.
//

#import "HKTransparentWindow.h"
#import "HKTransparentBorderedView.h"


@implementation HKTransparentWindow
- (id) initWithContentRect: (NSRect) contentRect
                 styleMask: (unsigned int) aStyle
                   backing: (NSBackingStoreType) bufferingType
                     defer: (BOOL) flag
{
    if (self = [super initWithContentRect:contentRect 
								styleMask:NSBorderlessWindowMask 
								  backing:NSBackingStoreBuffered 
									defer:NO]) {
        [self setLevel: NSStatusWindowLevel];
        [self setBackgroundColor: [NSColor clearColor]];
        [self setAlphaValue:1.0];
        [self setOpaque:NO];
        [self setHasShadow:NO];
		[self setIgnoresMouseEvents:YES];
		[self setContentView:[[HKTransparentBorderedView alloc] initWithFrame:contentRect]];
        return self;
    }
	return nil;
}
@end
