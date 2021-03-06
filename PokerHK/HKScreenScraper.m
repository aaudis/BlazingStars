//
//  HKScreenScraper.m
//  PokerHK
//
//  Created by Steven Hamblin on 16/06/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//
#import "HKScreenScraper.h"
#import <Carbon/Carbon.h>
#import "HKDefines.h"
#import "HKTesseract.h"

@implementation HKScreenScraper
@synthesize currencyCharacters;

-(void)awakeFromNib
{	
	logger = [SOLogger loggerForFacility:@"com.fullyfunctionalsoftware.blazingstars" options:ASL_OPT_STDERR];
	[logger info:@"Initializing screenScraper."];

	self.currencyCharacters = [[NSArray alloc] initWithObjects:@"$", @"€", @"£", nil];
    tesseract = [[HKTesseract alloc] init]; 

}

-(NSString *)runTesseract:(NSString *)inFilePath
{
	NSBundle * thisBundle = [NSBundle bundleForClass:[self class]];
	NSString * absolutePath = [thisBundle pathForResource:@"tesseract" ofType:@""];
	
	NSTask *task;
	task = [[NSTask alloc] init];
	[task setLaunchPath: absolutePath];
	
	NSString * tessdataPath = [NSString stringWithFormat:@"%@/", [thisBundle resourcePath]];
	NSMutableDictionary * environ = [NSMutableDictionary dictionaryWithDictionary:[task environment]];
	[environ setObject:tessdataPath forKey:@"TESSDATA_PREFIX"];
	
	[task setEnvironment:environ];
	
	char tempfilename[1024];
	strcpy(tempfilename, "/tmp/tmp_tesseract_gui_XXXXXX");
	char * tfile = mktemp(tempfilename);
	NSString *outputFileName = [NSString stringWithCString:tfile encoding:NSUTF8StringEncoding];
	
	NSString * inputPath = inFilePath;
	
	NSArray *arguments = [NSArray arrayWithObjects:inputPath, outputFileName, nil];
	
	[task setArguments: arguments];
	[task launch];
	[task waitUntilExit];
	
	NSString * ofile = [NSString stringWithFormat:@"%@.txt",outputFileName];
	NSString * output = [NSString stringWithContentsOfFile:ofile encoding:NSUTF8StringEncoding error:nil];
	if(output == nil)
		output = [NSString stringWithString:@"Error reading tesseract output"];
	
	int retval = unlink([ofile cStringUsingEncoding:NSUTF8StringEncoding]);
	if(retval)
		[logger warning:@"Failed to unlink: %@", ofile];
	
	return output;
}


// Based on Son of grab Developper example
-(NSImage*)imageWithWindow:(int)wid {
    
    // snag the image
	CGImageRef windowImage = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, wid, kCGWindowImageBoundsIgnoreFraming);
    
    // little bit of error checking
    if(CGImageGetWidth(windowImage) <= 1) {
        CGImageRelease(windowImage);
        return nil;
    }
    
    // Create a bitmap rep from the window and convert to NSImage...
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage: windowImage];
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation: bitmapRep];
    [bitmapRep release];
    CGImageRelease(windowImage);
    
    return [image autorelease];   
}

-(float)getPotSize
{
    AXUIElementRef mainWindow = [lowLevel getMainWindow];
	NSRect potRect = [windowManager getPotBounds:mainWindow];
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"debugOverlayWindowKey"]) {
        NSRect window = [lowLevel getWindowBounds:[lowLevel getMainWindow]];
        NSRect r = NSMakeRect(potRect.origin.x+window.origin.x, potRect.origin.y+window.origin.y, potRect.size.width, potRect.size.height);
        [windowManager debugWindow:r];
    }
    
    
    /*	
     New revision doesnt use opengl to grab a screenshot (faster ?) in all cases, it works fine under Lion
     */	
    NSImage *temp = [self imageWithWindow:[lowLevel getWindowIDForTable:mainWindow]];
	CGImageRef temp2 = [temp CGImageForProposedRect:NULL context:NULL hints:NULL];
    CGImageRef subImage = CGImageCreateWithImageInRect(temp2, NSRectToCGRect(potRect));
	NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:subImage];
	// Create an NSImage and add the bitmap rep to it...
	NSImage *imageConvert = [[NSImage alloc] initWithSize:NSMakeSize(potRect.size.width, potRect.size.height)];
	[imageConvert addRepresentation:bitmapRep];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    
    int minWidth =400;
    if(potRect.size.width<minWidth){
        NSImage* sourceImage = imageConvert;
        NSImage* newImage = nil;
        NSPoint thumbnailPoint = NSZeroPoint;
        
        float scaleFactor  = minWidth / potRect.size.width;                    
        float scaledWidth  = potRect.size.width  * scaleFactor;
        float scaledHeight = potRect.size.height * scaleFactor;
        thumbnailPoint.x = (minWidth - scaledWidth) * 0.5;
        
        newImage = [[NSImage alloc] initWithSize:NSMakeSize(scaledWidth,scaledHeight)];
        
        [newImage lockFocus];
        
        NSRect thumbnailRect;
        thumbnailRect.origin = thumbnailPoint;
        thumbnailRect.size.width = scaledWidth;
        thumbnailRect.size.height = scaledHeight;
        
        [sourceImage drawInRect: thumbnailRect
                       fromRect: NSZeroRect
                      operation: NSCompositeSourceOver
                       fraction: 1.0];
        
        [newImage unlockFocus];
        
        [imageConvert release];
        imageConvert = newImage;
    }
	[bitmapRep release];
    [temp release];
    
    bitmapRep = [NSBitmapImageRep imageRepWithData:[imageConvert TIFFRepresentation]];
    
    //NSLog(@"%@",[imageRep description]); 
	
   	
	NSString * result = [tesseract recognise:bitmapRep];
    [bitmapRep release];
	[logger info:@"Pot size is: %@",result];
	float returnVal;
	
	result = [result stringByReplacingOccurrencesOfString:@" " withString:@""];
	[logger info:@"Pot after stripping spaces: %@",result];
    
 	NSMutableCharacterSet *excludeSet = [[[NSCharacterSet characterSetWithCharactersInString:@"0123456789,."] invertedSet] mutableCopy];
	[excludeSet formUnionWithCharacterSet:[NSCharacterSet symbolCharacterSet]];
	
	result = [result stringByTrimmingCharactersInSet:excludeSet];
	[logger info:@"Pot after stripping exclude set: %@",result];
	
	// If there's a period in the string, split on it.  If the number of characters after the period
	// is greater than 2, then it's supposed to be a comma.
	if ([result rangeOfString:@"."].location != NSNotFound) {
		// Found a period.  Now split and check substring length after the *first* period. There could
		// be more than one.
		if ([[[result componentsSeparatedByString:@"."] objectAtIndex:1] length] > 2) {
			[logger info:@"Replacing period in %@ with null.",result];
			int index = [result rangeOfString:@"."].location;
			NSString *tempResult = [NSString stringWithString:[result substringToIndex:index]];
			NSString *tempResult2 = [NSString stringWithString:[result substringFromIndex:index+1]];
			result = [tempResult stringByAppendingString:tempResult2];
			[logger info:@"Result is now: %@",result];
		}
	}
    
	// At small sizes, tesseract will sometimes confuse the O in POT for a 0.  This will in turn
	// confuse the number formatter, which will drop everything after the 0 and report that the
	// potsize is zero.  Until I can come up with a more elegant way to fix this, I'm just going to 
	// look for the problem and drop everything before the $.  
	// This should drop everything before the $...
	for (id currencyCharacter in self.currencyCharacters) {
		if ([result rangeOfString:currencyCharacter].location != NSNotFound) {
			result = [[result componentsSeparatedByString:currencyCharacter] objectAtIndex:1];		
			[logger info:@"Pot after dropping everything before the %@: %@", currencyCharacter,result];
			break;
		}
	}
	
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	[formatter setNumberStyle:NSNumberFormatterDecimalStyle];	
	[formatter setGeneratesDecimalNumbers:YES];
	[formatter setDecimalSeparator:@"."];
	NSNumber *pot = [formatter numberFromString:result];
	[logger info:@"New pot value from formatter is: %g",[pot doubleValue]];
	returnVal = [pot floatValue];
	
	// Use the fact that any decimal followed by more than two digits is a comma.  
	NSRange position = [result rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
	if (position.location != NSNotFound) {
		[logger info:@"Position of decimal: %d",position.location];
	}
	
	return returnVal;    
}

@end