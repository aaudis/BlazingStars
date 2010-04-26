//
//  FullTiltTheme.h
//  PokerHK
//
//  PokerStarsTheme.h created by Steve McLeod on 28/12/09; this file is derived from Steve's work.
//  Created by Steven Hamblin on 11/04/10.
//

#import <Cocoa/Cocoa.h>


@interface FullTiltTheme : NSObject {
    BOOL supported;
    NSString *name;
	NSDictionary *themeDict;
}

@property (copy) NSDictionary *themeDict;

-(id)initWithName: (NSString*) themeName supported:(BOOL)themeSupported;
-(BOOL)supported;
-(NSString *)name;

@end
