//
//  HKLowLevel.m
//  PokerHK
//
//  Created by Steven Hamblin on 10-01-07.
//  Copyright 2010 Steven Hamblin. All rights reserved.
//

#import "HKLowLevel.h"
#import <Carbon/Carbon.h>
#import <AppKit/NSAccessibility.h>


@implementation HKLowLevel

@synthesize appName,pokerstarsPID,appRef;

-(id)init 
{
	if ((self = [super init])) {
		logger = [SOLogger loggerForFacility:@"com.fullyfunctionalsoftware.blazingstars" options:ASL_OPT_STDERR];
		[logger info:@"Initializing low-level interface in HKLowLevel."];
	
		if (!AXAPIEnabled()) {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:@"Accessibility API must be activated in the Universal Access Preferences Pane."];
			[alert setInformativeText:@"Make sure that the \"Enable access for assistive devices\" check box is selected at the bottom of the preference pane.  BlazingStars will now quit to allow you to modify the settings."];
			[alert runModal];
			[[NSApplication sharedApplication] terminate: nil];
		}
				
		NSWorkspace * ws = [NSWorkspace sharedWorkspace];
		NSArray * apps = [ws valueForKeyPath:@"launchedApplications.NSApplicationName"];

		if ([apps containsObject:@"PokerStarsIT"]) {
			appName = [NSString stringWithFormat:@"PokerStarsIT"];
		} else if ([apps containsObject:@"PokerStars"]) {
			appName = [NSString stringWithFormat:@"PokerStars"];
		} else {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:@"PokerStars client not found!"];
			[alert setInformativeText:@"The PokerStars client must be running for this program to operate.  Please start the client and then re-open BlazingStars."];
			[NSApp activateIgnoringOtherApps:YES];
			[alert runModal];
			[[NSApplication sharedApplication] terminate: nil];			
		}

		NSArray *pids = [[NSWorkspace sharedWorkspace] launchedApplications];
		
		for (id app in pids) {
			if ([[app objectForKey:@"NSApplicationName"] isEqualToString: appName]) {
				pokerstarsPID =(pid_t) [[app objectForKey:@"NSApplicationProcessIdentifier"] intValue];
			}		
		}		
		
		appRef = AXUIElementCreateApplication(pokerstarsPID);
		
		if (!appRef) {
			[logger critical:@"Could not get accessibility API reference to the PokerStars application."];
			NSException* apiException = [NSException
										 exceptionWithName:@"PokerStarsNotFoundException"
										 reason:@"Cannot get accessibility API reference to the PokerStars application."									
										 userInfo:nil];
			@throw apiException;
		}		
		
		
		NSNotificationCenter *center = [ws notificationCenter];
		[center addObserver:self
				   selector:@selector(appTerminated:)
					   name:NSWorkspaceDidTerminateApplicationNotification
					 object:nil];
		
	}
	return self;
}

-(BOOL)pokerStarsClientIsActive
{
	NSWorkspace * ws = [NSWorkspace sharedWorkspace];
	NSArray * apps = [ws valueForKeyPath:@"launchedApplications.NSApplicationName"];

	return [apps containsObject:appName];
}

-(AXUIElementRef)getFrontMostApp
{
	pid_t pid;
	ProcessSerialNumber psn;
	
	GetFrontProcess(&psn);
	GetProcessPID(&psn, &pid);
	return AXUIElementCreateApplication(pid);	
}

-(AXUIElementRef)getMainWindow
{
	AXUIElementRef mainWindow = nil;
	
	for (id child in [self getChildrenFrom:self.appRef]) {
		NSString *value;
		AXUIElementCopyAttributeValue((AXUIElementRef)child,kAXMainAttribute,(CFTypeRef *)&value);	
		// Check to see if this is main window we're looking at.  It's here that we'll send the mouse events.
		if ([value intValue] == 1) {
			NSString *title;
			AXUIElementCopyAttributeValue((AXUIElementRef)child,kAXTitleAttribute,(CFTypeRef *)&title);
			mainWindow = (AXUIElementRef)child;
		}
	}
	return mainWindow;
}

-(NSRect)getWindowBounds:(AXUIElementRef)windowRef
{
	id *size;
	CGSize sizeVal;
	
	AXUIElementCopyAttributeValue(windowRef,kAXSizeAttribute,(CFTypeRef *)&size);
	
	if (!AXValueGetValue((AXValueRef) size, kAXValueCGSizeType, &sizeVal)) {
		[logger warning:@"Could not get window size for windowRef: %@",windowRef];
		return NSMakeRect(0,0,0,0);
	} 
	
	id *position;
	AXError axErr = AXUIElementCopyAttributeValue(windowRef,kAXPositionAttribute,(CFTypeRef *)&position);
	if (axErr != kAXErrorSuccess) {
		[logger warning:@"\nCould not retrieve window position for windowRef: %@. Error code: %d",windowRef,axErr];
		return NSMakeRect(0,0,0,0);
	}
	
	CGPoint corner;
	if (!AXValueGetValue((AXValueRef)position, kAXValueCGPointType, &corner)) {
		[logger warning:@"Could not get window corner for windowRef: %@",windowRef];
		return NSMakeRect(0,0,0,0);
	}
	
	NSRect windowRect;
	windowRect.origin = *(NSPoint *)&corner;
	windowRect.size = *(NSSize *)&sizeVal;
	return windowRect;
}


-(NSArray *)getChildrenFrom:(AXUIElementRef)ref
{
	NSArray *children;
	AXError err = AXUIElementCopyAttributeValues(ref, kAXChildrenAttribute, 0, 100, (CFArrayRef *)&children);

	if (err != kAXErrorSuccess) {
		[logger warning:@"Retrieving children failed. Error code: %d", err];
		return nil;
	}
	return children;
}

-(void)clickAt:(CGPoint)point
{
	CGAssociateMouseAndMouseCursorPosition(false);
	
	CGEventRef mouseEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, point, kCGMouseButtonLeft);
	
	// Cancel any of the modifier keys - this caused me a day of bug-hunting!
	CGEventSetFlags(mouseEvent,0);
	CGEventPost(kCGHIDEventTap,mouseEvent);
	mouseEvent = CGEventCreateMouseEvent(NULL,kCGEventLeftMouseUp,point,kCGMouseButtonLeft);
	CGEventSetFlags(mouseEvent,0);
	CGEventPost(kCGHIDEventTap,mouseEvent);

	CGAssociateMouseAndMouseCursorPosition(true);	
	FlushEventQueue(GetMainEventQueue());
	FlushEventQueue(GetCurrentEventQueue());
}

-(void)keyPress:(int)keyCode with:(int)flags
{
	CGEventRef keyEventDown = CGEventCreateKeyboardEvent(NULL,keyCode,true);
	CGEventSetFlags(keyEventDown,flags);
	CGEventRef keyEventUp = CGEventCreateKeyboardEvent(NULL, keyCode, false);
	CGEventSetFlags(keyEventUp,flags);
	
	CGEventPost(kCGSessionEventTap, keyEventDown);	
	CGEventPost(kCGSessionEventTap, keyEventUp);
		
	FlushEventQueue(GetMainEventQueue());
	FlushEventQueue(GetCurrentEventQueue());	
		
}

-(void)keyPress:(int)keyCode 
{
	[self keyPress:keyCode with:0];
	
}

-(void)keyPress:(int)keyCode repeated:(int)times withFlush:(BOOL)flush
{
	CGEventRef keyEventDown = CGEventCreateKeyboardEvent(NULL,keyCode,true);
	CGEventSetFlags(keyEventDown,0);
	CGEventRef keyEventUp = CGEventCreateKeyboardEvent(NULL, 124, false);
	CGEventSetFlags(keyEventUp,0);
	
	for (int j = 0; j < times; j++) {
		CGEventPost(kCGAnnotatedSessionEventTap, keyEventDown);	
		CGEventPost(kCGAnnotatedSessionEventTap, keyEventUp);
		
		if (flush) {
			FlushEventQueue(GetMainEventQueue());
			FlushEventQueue(GetCurrentEventQueue());	
		}
	}	
	
}

-(void)writeString:(NSString *)valueToSet
{
	UniChar buffer;
	CGEventRef keyEventDown = CGEventCreateKeyboardEvent(NULL, 1, true);
	CGEventRef keyEventUp = CGEventCreateKeyboardEvent(NULL, 1, false);
	CGEventSetFlags(keyEventDown,0);		
	CGEventSetFlags(keyEventUp,0);		
	for (int i = 0; i < [valueToSet length]; i++) {
		[valueToSet getCharacters:&buffer range:NSMakeRange(i, 1)];
		[logger debug:@"Character: %c",buffer];
		CGEventKeyboardSetUnicodeString(keyEventDown, 1, &buffer);
		CGEventPost(kCGAnnotatedSessionEventTap, keyEventDown);
		CGEventKeyboardSetUnicodeString(keyEventUp, 1, &buffer);
		CGEventPost(kCGAnnotatedSessionEventTap, keyEventUp);
	}
	
}

-(void)appTerminated:(NSNotification *)note
{
	if ([[[note userInfo] objectForKey:@"NSApplicationProcessIdentifier"] isEqual:[NSNumber numberWithInt:pokerstarsPID]]) {
		[logger notice:@"PokerStars terminated - quitting BlazingStars."];
		[[NSApplication sharedApplication] terminate: nil];
	}
}


@end
