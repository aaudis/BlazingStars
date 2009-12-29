//
//  PokerStarsInfo.m
//  PokerHK
//
//  Created by Steve McLeod on 28/12/09.
//

#import "PokerStarsInfo.h"

// declare private methods
@interface PokerStarsInfo() 
+(BOOL)applicationInstalled:(NSString *)appName;
+(NSString *)pokerStarsPreferencesFilename;
+(NSString *)pokerStarsPreference: (NSString *)preference inSection:(NSString *)section;
@end

@implementation PokerStarsInfo

+(PokerStarsTheme *)determineTheme {
    NSString *preference = [PokerStarsInfo pokerStarsPreference: @"0" inSection:@"themes"];
    if (preference == nil) {
        @throw [NSException exceptionWithName:@"ThemeException" reason:@"Can't access PokerStars preferences" userInfo:nil];
    }

    NSRange range = [preference rangeOfString:@"@"];
    if (range.location == NSNotFound) {
        // this typically means a custom theme is in use 
        return [[PokerStarsTheme alloc] initWithName:@"Custom" supported:NO];
    }
    
    NSString *s = [preference substringToIndex:range.location];
	
    if ([s hasPrefix:@"renaissance"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Renaissance" supported:NO];
    }
    if ([s hasPrefix:@"slick"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Slick" supported:YES];
    }
    if ([s isEqualToString:@"default"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Classic" supported:NO];
    }
    if ([s isEqualToString:@"black"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Black" supported:YES];
    }
    if ([s isEqualToString:@"simple"]) {
        return [[PokerStarsTheme alloc] initWithName:@"No Images" supported:NO];
    }
    if ([s isEqualToString:@"shiny"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Shiny" supported:NO];
    }
    if ([s isEqualToString:@"marine"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Marine" supported:NO];
    }
    if ([s isEqualToString:@"stars"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Stars" supported:NO];
    }
    if ([s isEqualToString:@"ordinary"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Hyper-Simple" supported:YES];
    }
    if ([s isEqualToString:@"saloon"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Saloon" supported:NO];
    }
    if ([s isEqualToString:@"techno"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Techno" supported:NO];
    }
    if ([s isEqualToString:@"azure"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Azure" supported:NO];
    }

    return [[PokerStarsTheme alloc] initWithName:[@"Unknown PokerStars theme: " stringByAppendingString: s] supported:NO];
}

/* 
 Returns YES if an application with the given name exists in the Applications folder
 */
+(BOOL)applicationInstalled: (NSString *)appName {
    NSString *path = [NSString stringWithFormat:@"/Applications/%@.app", appName];
    BOOL directory;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path isDirectory:&directory];
}

/*
 Returns the name of the poker stars preferences file
 */
+(NSString *) pokerStarsPreferencesFilename {
    if ([self applicationInstalled:@"PokerStarsIT"]) {
        return [@"~/Library/Preferences/com.pokerstars.it.user.ini" stringByExpandingTildeInPath];
    }
    return [@"~/Library/Preferences/com.pokerstars.user.ini" stringByExpandingTildeInPath];
}

/*
 Returns the value of a specific poker stars preference in the specified section
 */
+(NSString *)pokerStarsPreference:(NSString *)preference inSection:(NSString *)section {
    NSString *prefix = [preference stringByAppendingString:@"="];
    NSString * filename = [self pokerStarsPreferencesFilename];
    
    BOOL directory;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL exists = [fileManager fileExistsAtPath:filename isDirectory:&directory];
    if (!exists) {
        return nil;
    }

    NSString *contents = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding  error:NULL];
    NSArray *lines = [contents componentsSeparatedByString:@"\n"];
    NSEnumerator *nse = [lines objectEnumerator];
    NSString *line;

    BOOL inSection = NO;

    while (line = [nse nextObject]) {
        if (inSection) {
            if ([line hasPrefix:@"["]) {
                break;
            }
                  
            if ([line hasPrefix:prefix]) {
                return [line substringFromIndex:[prefix length]];
            }
            
        } else if ([line isEqualToString:[NSString stringWithFormat:@"[%@]", section]]) {
            inSection = YES;
        }
        
    }
    
    return nil;
}

@end
