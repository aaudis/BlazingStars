//
//  HKTesseract.m
//  PokerHK
//
//  Created by Simon Vanesse on 26/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HKTesseract.h"
#import <Tesseract/baseapi.h>

#import "util.h"
#import <Tesseract/memry.h>
#import <Tesseract/imgs.h>

using namespace tesseract;

@implementation HKTesseract

- (id)init
{
    self = [super init];
    if (self) {
        // #### TESSERACT LOADING ####
        
        recognitionLock = [[NSRecursiveLock alloc] init];
        // Define the location of the training folder
        NSString* dataPathDirectory = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources/"];
        const char* dataPathDirectoryCString = [dataPathDirectory cStringUsingEncoding:NSUTF8StringEncoding];
        setenv("TESSDATA_PREFIX", dataPathDirectoryCString, 1);
        
        // Loading the tesseract object    
        tess = new tesseract::TessBaseAPI();
        // Language Configuration
        //		tess->InitWithLanguage("CocoaApp" , NULL, NULL,
        //									  NULL, false, 0, NULL);
        
        // Other configuration
        ((TessBaseAPI*)tess)->Init(dataPathDirectoryCString, NULL, NULL, 0, false);
        //tess->SetPageSegMode(PSM_SINGLE_COLUMN);
        ((TessBaseAPI*)tess)->SetAccuracyVSpeed(AVS_MOST_ACCURATE);
        
        // END TESSERACT LOADING

    }
    
    return self;
}

- (NSString*)recognise : (NSBitmapImageRep*) bitmapRep
{
    
    unsigned char* imageData = [bitmapRep bitmapData];
    char *text;
	NSSize imageSize = NSMakeSize([bitmapRep pixelsWide],[bitmapRep pixelsHigh]);
	int bytes_per_line = [bitmapRep bytesPerRow];

	text = ((TessBaseAPI*)tess)->TesseractRect((const unsigned char*)imageData, [bitmapRep bitsPerPixel]/8,
                               bytes_per_line, 0, 0,
                               imageSize.width, imageSize.height);
	
	
	NSString * result = [NSString stringWithCString:text encoding:NSUTF8StringEncoding];
    
	delete(text);

    return result;
}

- (void)dealloc
{
	
	[recognitionLock release];
	
	((TessBaseAPI*)tess)->End();
	[super dealloc];
}

@end
