//
//  FramePreviewView.m
//  PokerHK
//
//  Created by Steven Hamblin on 10-01-18.
//  Copyright 2010 Steven Hamblin. All rights reserved.
//

#import "FramePreviewView.h"
#import "PrefsWindowController.h"



@implementation FramePreviewView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		lowLevel = [[HKLowLevel init] alloc];
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSColor *bgColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.0];
    NSRect bgRect = [self bounds];
	
	[bgColor set];
	NSRectFill(bgRect);

	// This is a little hacky, but I can improve it later.
	// This value shoudln't be hardcoded, but making it programmatic will require a fair
	// amount of work.  
	// Perhaps the .user.ini file has something of use for this?  A default window size, for instance?
	NSRect frameRect = NSMakeRect(0, 0, 792, 568);
	
	NSColor *color = [[[PrefsWindowController sharedPrefsWindowController] windowFrameColourWell] color];
	[[NSColor colorWithDeviceRed:[color redComponent] 
						   green:[color greenComponent] 
							blue:[color blueComponent] 
						   alpha:([[NSUserDefaults standardUserDefaults] floatForKey:@"windowFrameOpacityKey"]/100)] set];
	NSFrameRectWithWidth(frameRect,[[NSUserDefaults standardUserDefaults] floatForKey:@"windowFrameWidthKey"]);
	
}


-(IBAction)colorChanged:(id)sender
{
	[self setNeedsDisplay:YES];
}

-(IBAction)opacityChanged:(id)sender
{
	[self setNeedsDisplay:YES];
}

-(IBAction)thicknessChanged:(id)sender
{
	[self setNeedsDisplay:YES];
}



@end
