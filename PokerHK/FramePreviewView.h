//
//  FramePreviewView.h
//  PokerHK
//
//  Created by Steven Hamblin on 10-01-18.
//  Copyright 2010 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HKLowLevel.h"


@interface FramePreviewView : NSView {
	HKLowLevel *lowLevel;
}

-(IBAction)colorChanged:(id)sender;
-(IBAction)opacityChanged:(id)sender;
-(IBAction)thicknessChanged:(id)sender;

@end
