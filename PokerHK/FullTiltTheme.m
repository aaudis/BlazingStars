//
//  FullTiltTheme.m
//  PokerHK
//
//  PokerStarsTheme.m created by Steve McLeod on 28/12/09; this file is derived from Steve's work.
//  Created by Steven Hamblin on 11/04/10.
//

#import "FullTiltTheme.h"


@implementation FullTiltTheme

@synthesize themeDict;

-(id)initWithName: (NSString*) themeName supported:(BOOL)themeSupported {
    if (![super init]) {
        return nil;
    }
    
    name = themeName;
    supported = themeSupported;
	
	if (themeSupported) {
		NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] 
																		 pathForResource:themeName ofType: @"plist"]];
		self.themeDict = dict;
	}
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
