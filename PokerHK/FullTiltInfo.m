//
//  PokerStarsInfo.m
//  PokerHK
//
//  Created by Steve McLeod on 28/12/09.
//

#import "FullTiltInfo.h"
#import "HKDefines.h"
#import "HKLowLevel.h"

// declare private methods
@interface FullTiltInfo() 
+(BOOL)applicationInstalled:(NSString *)applicationName;
@end

@implementation FullTiltInfo

+(FullTiltTheme *)determineTheme {
	return [[FullTiltTheme alloc] initWithName:@"Racetrack" supported:YES];
	
/*    NSString *preference = [PokerStarsInfo pokerStarsPreference: @"0" inSection:@"themes"];
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
	
    if ([s hasPrefix:@"renaissance"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Renaissance" supported:YES];
    }
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
        return [[PokerStarsTheme alloc] initWithName:@"No Images" supported:NO];
    }
    if ([s isEqualToString:@"shiny"]) {
        return [[PokerStarsTheme alloc] initWithName:@"Shiny" supported:YES];
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
    }*/

    //return [[FullTiltTheme alloc] initWithName:[@"Unknown PokerStars theme: " stringByAppendingString: s] supported:NO];
}

+(NSString *)determineUserName
{
	return @"Winawer0";
	//return [FullTiltInfo pokerStarsPreference: @"Name" inSection:@"User"];
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


@end
