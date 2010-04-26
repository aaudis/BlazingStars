//
//  PokerStarsInfo.h
//  PokerHK
//
//  Created by Steve McLeod on 28/12/09.
//

#import <Cocoa/Cocoa.h>
#import "FullTiltTheme.h"

@interface FullTiltInfo : NSObject {
}
+(FullTiltTheme *)determineTheme;
+(NSString *)determineUserName;

@end
