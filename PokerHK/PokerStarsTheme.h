//
//  PokerStarsTheme.h
//  PokerHK
//
//  Created by Steve McLeod on 28/12/09.
//

#import <Cocoa/Cocoa.h>


@interface PokerStarsTheme : NSObject {
    BOOL supported;
    NSString *name;
	NSDictionary *themeDict;
}

@property (copy) NSDictionary *themeDict;

-(id)initWithName: (NSString*) themeName supported:(BOOL)themeSupported;
-(BOOL)supported;
-(NSString *)name;

@end
