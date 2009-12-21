//
//  TFTesseractWrapper.m
//  TesseractFrontend
//
//  Created by Cristian Draghici on 2/2/09.
//  Copyright 2009 Modulo Consulting. All rights reserved.
//
//  License terms under license.txt
// 

#import "TFTesseractWrapper.h"

@implementation TFTesseractWrapper

- (void) runTesseract:(NSURL *)fin :(id) callbackTarget
{
	m_callbackTarget = callbackTarget;
	
	NSBundle * thisBundle = [NSBundle bundleForClass:[self class]];
	NSString * absolutePath = [thisBundle pathForResource:@"tesseract" ofType:@""];
	NSLog(@"executable path: %@", absolutePath);
	
	NSTask *task;
	task = [[NSTask alloc] init];
	[task setLaunchPath: absolutePath];
	
	NSString * tessdataPath = [NSString stringWithFormat:@"%@/", [thisBundle resourcePath]];
	NSMutableDictionary * environ = [NSMutableDictionary dictionaryWithDictionary:[task environment]];
	[environ setObject:tessdataPath forKey:@"TESSDATA_PREFIX"];
	
	NSLog(@"env: %@", environ);
	[task setEnvironment:environ];
	
	char tempfilename[1024];
	strcpy(tempfilename, "/tmp/tmp_tesseract_gui_XXXXXX");
	char * tfile = mktemp(tempfilename);
	m_outputFileName = [NSString stringWithCString:tfile encoding:NSUTF8StringEncoding];
	
	
	NSString * inputPath = [fin path];
	NSLog(@"input path: %@, output file name %@", inputPath, m_outputFileName);
	
	
	NSArray *arguments;
	if([[NSUserDefaults standardUserDefaults] stringForKey:@"prefLanguageSpec"] != nil)
	{
		/* check for this language pack */
		NSLog(@"Checking for path: %@", [NSString stringWithFormat:@"%@tessdata/%@.unicharset", tessdataPath, [[NSUserDefaults standardUserDefaults] stringForKey:@"prefLanguageSpec"]]);
		if(![[NSFileManager defaultManager] fileExistsAtPath:
			[NSString stringWithFormat:@"%@tessdata/%@.unicharset", tessdataPath, [[NSUserDefaults standardUserDefaults] stringForKey:@"prefLanguageSpec"]]])
		{
			NSAlert * alertModal = [NSAlert alertWithMessageText:@"Language pack not found"
										 defaultButton:@"OK"
									   alternateButton:nil
										   otherButton:nil
									   informativeTextWithFormat:
									[NSString stringWithFormat: @"Custom language pack (%@) has been specified, but it is not installed in the tessdata directory", 
																  [[NSUserDefaults standardUserDefaults] stringForKey:@"prefLanguageSpec"]]];
			[alertModal runModal];
		}
		
		arguments = [NSArray arrayWithObjects:inputPath, m_outputFileName, @"-l", [[NSUserDefaults standardUserDefaults] stringForKey:@"prefLanguageSpec"], nil];
	}
	else
		arguments = [NSArray arrayWithObjects:inputPath, m_outputFileName, nil];
	
	[task setArguments: arguments];
	NSPipe *pipe;
	pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	
	NSFileHandle *file;
	file = [pipe fileHandleForReading];
	
	NSNotificationCenter *nc;
	nc = [NSNotificationCenter defaultCenter];
	
	[nc addObserver:self
		   selector:@selector(processClientData:)
			   name:NSFileHandleReadCompletionNotification
			 object:file];
	
	
	[task launch];
	
	[file readInBackgroundAndNotify];	
	
}

- (void)processClientData:(NSNotification *)note
{
	NSData *data = [[note userInfo]
					objectForKey:NSFileHandleNotificationDataItem];
	
	NSString *string;
	string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	NSLog (@"got\n%@", string);
	
	[string autorelease];
	
	if(data != nil && [data length] > 0)
	{
		// Tell file handle to continue waiting for data
		[[note object] readInBackgroundAndNotify];
		return;
	}
	
	NSString * ofile = [NSString stringWithFormat:@"%@.txt", m_outputFileName];
	NSLog(@"All done");
	NSString * output = [NSString stringWithContentsOfFile:ofile encoding:NSUTF8StringEncoding error:nil];
	if(output == nil)
		output = [NSString stringWithString:@"Error reading tesseract output"];
	
	
	[m_callbackTarget processDoneCallback:output];
	int retval = unlink([ofile cStringUsingEncoding:NSUTF8StringEncoding]);
	if(retval)
		NSLog(@"Failed to unlink: %@", ofile);
}

@end
