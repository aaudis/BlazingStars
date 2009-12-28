//
//  PokerStarsTheme.m
//  PokerHK
//
//  Created by Steve McLeod on 28/12/09.
//

#import "PokerStarsTheme.h"


@implementation PokerStarsTheme

-(id)initWithName: (NSString*) themeName supported:(BOOL)themeSupported {
    if (![super init]) {
        return nil;
    }
    
    name = themeName;
    supported = themeSupported;
    return self;
}

-(id)init {
    [self dealloc];
    @throw [NSException exceptionWithName:@"BadInitCall" reason:@"Unsupported init method" userInfo:nil];
    return nil;
}

-(BOOL)supported {
    return supported;
}

-(NSString *)name {
    return name;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"name=%@, supported=%d", name, supported];
}
@end
