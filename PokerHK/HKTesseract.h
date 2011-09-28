//
//  HKTesseract.h
//  PokerHK
//
//  Created by Simon Vanesse on 26/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Foundation/Foundation.h"


@interface HKTesseract : NSObject {


    // Tesseract object
    void *tess;

    // Thread lock for tesseract
    id recognitionLock;
}
- (NSString*)recognise: (NSBitmapImageRep*) bitmapRep;
- (void)dealloc;
@end
