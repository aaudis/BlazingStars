//
//  AboutWindowController.m
//  PokerHK
//
//  Created by Steve McLeod on 24/01/10.
//

#import "AboutWindowController.h"


@implementation AboutWindowController

-(id)init {
    if (![super initWithWindowNibName:@"AboutWindow"]) {
        return nil;
    }
    return self;
}

-(void)windowDidLoad {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Credits"  ofType:@"rtf"];
    NSAttributedString *as = [[NSAttributedString alloc] initWithPath:path documentAttributes:NULL];
    [creditsLabel setAttributedStringValue:as];
    [creditsLabel becomeFirstResponder];

    NSBundle *mainBundle = [NSBundle mainBundle];
    NSDictionary *infoDictionary = [mainBundle infoDictionary];
    NSString *shortVersionString = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    NSString *bundleVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
    NSString *versionString = [NSString stringWithFormat:@"Version %@ (%@)", shortVersionString, bundleVersion];
    [versionLabel setStringValue:versionString];

}

-(void)showAboutPanel:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    [self.window center];
    [self showWindow:sender];
    [self.window makeKeyAndOrderFront:sender];
    
}

@end
