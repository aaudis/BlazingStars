//
//  PokerStarsInfo.h
//  PokerHK
//
//  Created by Steve McLeod on 28/12/09.
//

#import <Cocoa/Cocoa.h>
#import "PokerStarsTheme.h"

@interface PokerStarsInfo : NSObject {
}
+(PokerStarsTheme *)determineTheme;
+(NSString *)determineUserName;

@end
