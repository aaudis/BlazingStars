//
//  TFTesseractWrapper.h
//  TesseractFrontend
//
//  Created by Cristian Draghici on 2/2/09.
//  Copyright 2009 Modulo Consulting. All rights reserved.
//
//  License terms under license.txt
// 

#import <Cocoa/Cocoa.h>
//#import "TFDebugging.h"

@interface TFTesseractWrapper : NSObject {
	NSString * m_outputFileName;
	id m_callbackTarget;
}
- (void) runTesseract:(NSURL *)fin :(id) callbackTarget;
@end
