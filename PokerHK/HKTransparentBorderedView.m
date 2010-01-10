//
//  HKThemeView.m
//  PokerHK
//
//  Created by Steven Hamblin on 10-01-06.
//  Copyright 2010 Steven Hamblin. All rights reserved.
//

#import "HKTransparentBorderedView.h"
#import "PrefsWindowController.h"


@implementation HKTransparentBorderedView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}
		 

- (void)drawRect:(NSRect)dirtyRect
{
    NSColor *bgColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.0];
    NSRect bgRect = [self bounds];
	
	[bgColor set];
	NSRectFill(bgRect);
	
	NSColor *color = [[[PrefsWindowController sharedPrefsWindowController] windowFrameColourWell] color];
	[[NSColor colorWithDeviceRed:[color redComponent] 
						  green:[color greenComponent] 
						   blue:[color blueComponent] 
						   alpha:([[NSUserDefaults standardUserDefaults] floatForKey:@"windowFrameOpacityKey"]/100)] set];
	NSFrameRectWithWidth(bgRect,[[NSUserDefaults standardUserDefaults] floatForKey:@"windowFrameWidthKey"]);
}



@end
