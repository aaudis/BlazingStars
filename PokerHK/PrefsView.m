//
//  PrefsView.m
//  PokerHK
//
//  Created by Steven Hamblin on 09-12-22.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import "PrefsView.h"


@implementation PrefsView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
}


-(BOOL)acceptsFirstResponder
{
	return YES;
}

-(BOOL)becomeFirstResponder
{
	return YES;
}


-(void)keyDown:(NSEvent *)theEvent
{
	if ([theEvent keyCode] == 53){
		[[self window] performClose:self];
	}
	[super keyDown:theEvent];
}


@end
