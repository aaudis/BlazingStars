//
//  HKLowLevel.h
//  PokerHK
//
//  Created by Steven Hamblin on 10-01-07.
//  Copyright 2010 Steven Hamblin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SOLogger/SOLogger.h>


@interface HKLowLevel : NSObject {
	NSString *appName;
	AXUIElementRef appRef;
	pid_t pokerstarsPID;
	
	SOLogger *logger;
}

@property (copy) NSString *appName;
@property (assign) pid_t pokerstarsPID;
@property (assign) AXUIElementRef appRef;

-(BOOL)pokerStarsClientIsActive;
-(AXUIElementRef)getFrontMostApp;
-(AXUIElementRef)getMainWindow;
-(NSRect)getWindowBounds:(AXUIElementRef)windowRef;
-(NSArray *)getChildrenFrom:(AXUIElementRef)ref;
-(void)clickAt:(CGPoint)point;
-(void)keyPress:(int)keyCode with:(int)flags;
-(void)keyPress:(int)keyCode;
-(void)keyPress:(int)keyCode repeated:(int)times withFlush:(BOOL)flush;
-(void)writeString:(NSString *)valueToSet;
-(NSArray *)getCGPokerStarsWindowList;
-(int)getWindowIDForTable:(AXUIElementRef)tableRef;

@end
