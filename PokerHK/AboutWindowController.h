//
//  AboutWindowController.h
//  PokerHK
//
//  Created by Steve McLeod on 24/01/10.
//

#import <Cocoa/Cocoa.h>


@interface AboutWindowController : NSWindowController {
    IBOutlet NSTextField *versionLabel;
    IBOutlet NSTextField *creditsLabel;
    IBOutlet NSWindow *window;
}

-(void)showAboutPanel:(id)sender;
@end
