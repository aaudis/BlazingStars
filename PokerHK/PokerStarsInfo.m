//
//  PokerStarsInfo.m
//  PokerHK
//
//  Created by Steve McLeod on 28/12/09.
//

#import "PokerStarsInfo.h"
#import "HKDefines.h"
#import "HKLowLevel.h"

// declare private methods
@interface PokerStarsInfo() 
+(BOOL)applicationInstalled:(NSString *)applicationName;
+(NSString *)pokerStarsPreferencesFilename;
+(NSString *)pokerStarsPreference: (NSString *)preference inSection:(NSString *)section;
@end

@implementation PokerStarsInfo

+(PokerStarsTheme *)determineTheme {
    NSString *preference = [PokerStarsInfo pokerStarsPreference: @"0" inSection:@"themes"];
    if (preference == nil) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:[NSString stringWithFormat:@"Fatal error: BlazingStars could not find the PokerStars preferences file at %@.",
			[PokerStarsInfo pokerStarsPreferencesFilename]]];
		[alert setInformativeText:@"Without this file, BlazingStars cannot determine the theme in use by PokerStars;  BlazingStars will now quit."];
		[alert runModal];		
        @throw [NSException exceptionWithName:@"ThemeException" reason:@"Can't access PokerStars preferences" userInfo:nil];
    }

    NSRange range = [preference rangeOfString:@"@"];
    if (range.location == NSNotFound) {
        // this typically means a custom theme is in use 
        return [[PokerStarsTheme alloc] initWithName:@"Custom" supported:NO];
    }
    
    NSString *s = [preference substringToIndex:range.location];
	
    if ([s hasPrefix:@"slick"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Slick" supported:YES];
    }
    if ([s isEqualToString:@"default"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Classic" supported:YES];
    }
	// Work around for a bug in the PokerStars IT preferences.  
    if ([s isEqualToString:@"black"] || [s isEqualToString:@"xblack"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Black" supported:YES];
    }
    if ([s isEqualToString:@"simple"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Simple" supported:YES];
    }
    if ([s isEqualToString:@"shiny"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Shiny" supported:YES];
    }
    if ([s isEqualToString:@"nova"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Nova" supported:YES];
    }
    if ([s isEqualToString:@"ordinary"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Simple" supported:YES];
    }
    if ([s isEqualToString:@"simple"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Simple" supported:YES];
    }
    if ([s isEqualToString:@"techno"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Techno" supported:YES];
    }
    if ([s isEqualToString:@"classic"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Classic" supported:YES];
    }

    return [[PokerStarsTheme alloc] initWithName:[@"Unknown PokerStars theme: " stringByAppendingString: s] supported:NO];
}

+(NSString *)determineUserName
{
	return [PokerStarsInfo pokerStarsPreference: @"Name" inSection:@"User"];
}

/* 
 Returns YES if an application with the given name exists in the Applications folder
 */
+(BOOL)applicationInstalled: (NSString *)applicationName {
    NSString *path = [NSString stringWithFormat:@"/Applications/%@.app", applicationName];
    BOOL directory;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:path isDirectory:&directory];
}

/*
 Returns the name of the poker stars preferences file
 */
+(NSString *) pokerStarsPreferencesFilename {
	HKLowLevel *lowLevel = [[HKLowLevel alloc] init];
	if ([[lowLevel appName] isEqualToString:@"PokerStarsIT"]) {
		return [@"~/Library/Preferences/com.pokerstars.it.user.ini" stringByExpandingTildeInPath];
	} else if ([[lowLevel appName] isEqualToString:@"PokerStarsFR"]) {
		return [@"~/Library/Preferences/com.pokerstars.fr.user.ini" stringByExpandingTildeInPath];
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
