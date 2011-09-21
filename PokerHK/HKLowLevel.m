//
//  HKLowLevel.m
//  PokerHK
//
//  Created by Steven Hamblin on 10-01-07.
//  Copyright 2010 Steven Hamblin. All rights reserved.
//

#import "HKLowLevel.h"
#import "CGSPrivate.h"
#import <Carbon/Carbon.h>
#import <AppKit/NSAccessibility.h>


typedef struct
{
	// Where to add window information
	NSMutableArray * outputArray;
	// Tracks the index of the window when first inserted
	// so that we can always request that the windows be drawn in order.
	int order;
} WindowListApplierData;

NSString *kAppNameKey = @"applicationName";    // Application Name & PID
NSString *kWindowOriginKey = @"windowOrigin";    // Window Origin as a string
NSString *kWindowSizeKey = @"windowSize";        // Window Size as a string
NSString *kWindowIDKey = @"windowID";            // Window ID
NSString *kWindowLevelKey = @"windowLevel";    // Window Level
NSString *kWindowOrderKey = @"windowOrder";    // The overall front-to-back ordering of the windows as returned by the window server
NSString *kWindowNameKey = @"windowName";
NSString *kWindowWorkspaceKey = @"workspace";

void WindowListApplierFunction(const void *inputDictionary, void *context)
{
    NSDictionary *entry = (NSDictionary*)inputDictionary;
    WindowListApplierData *data = (WindowListApplierData*)context;
    
    // The flags that we pass to CGWindowListCopyWindowInfo will automatically filter out most undesirable windows.
    // However, it is possible that we will get back a window that we cannot read from, so we'll filter those out manually.
    int sharingState = [[entry objectForKey:(id)kCGWindowSharingState] intValue];
    if(sharingState != kCGWindowSharingNone)
    {
        NSMutableDictionary *outputEntry = [NSMutableDictionary dictionary];
        
        // Grab the application name, but since it's optional so we need to check before we can use it.
        NSString *applicationName = [entry objectForKey:(id)kCGWindowOwnerName];
        if(applicationName != NULL)
        {
            // PID is required so we assume it's present.
            NSString *nameAndPID = [NSString stringWithFormat:@"%@ (%@)", applicationName, [entry objectForKey:(id)kCGWindowOwnerPID]];
            [outputEntry setObject:nameAndPID forKey:kAppNameKey];
        }
        else
        {
            // The application name was not provided, so we use a fake application name to designate this.
            // PID is required so we assume it's present.
            NSString *nameAndPID = [NSString stringWithFormat:@"((unknown)) (%@)", [entry objectForKey:(id)kCGWindowOwnerPID]];
            [outputEntry setObject:nameAndPID forKey:kAppNameKey];
        }
		
        // Grab the Window Bounds, it's a dictionary in the array, but we want to display it as strings
        CGRect bounds;
        CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[entry objectForKey:(id)kCGWindowBounds], &bounds);
        NSString *originString = [NSString stringWithFormat:@"%.0f/%.0f", bounds.origin.x, bounds.origin.y];
        [outputEntry setObject:originString forKey:kWindowOriginKey];
        NSString *sizeString = [NSString stringWithFormat:@"%.0f*%.0f", bounds.size.width, bounds.size.height];
        [outputEntry setObject:sizeString forKey:kWindowSizeKey];
        
        // Grab the Window ID & Window Level. Both are required, so just copy from one to the other
        [outputEntry setObject:[entry objectForKey:(id)kCGWindowNumber] forKey:kWindowIDKey];
        [outputEntry setObject:[entry objectForKey:(id)kCGWindowLayer] forKey:kWindowLevelKey];
        
		NSString *windowName = [entry objectForKey:(id)kCGWindowName];
		if (windowName != NULL) {
			[outputEntry setObject:windowName forKey:kWindowNameKey];
		}
		
		// SH:  See if we can grab the workspace to see if we're in the same workspace.
		NSNumber *workspace = [entry objectForKey:(id)kCGWindowWorkspace];
		if (workspace != NULL) {
			[outputEntry setObject:workspace forKey:kWindowWorkspaceKey];
		}
		
        // Finally, we are passed the windows in order from front to back by the window server
        // Should the user sort the window list we want to retain that order so that screen shots
        // look correct no matter what selection they make, or what order the items are in. We do this
        // by maintaining a window order key that we'll apply later.
        [outputEntry setObject:[NSNumber numberWithInt:data->order] forKey:kWindowOrderKey];
		
		// Look for PokerStars window:
//		HKLowLevel *lowLevel = [[HKLowLevel alloc] init];
		if ([applicationName isEqual:@"PokerStars"] || [applicationName isEqual:@"PokerStarsIT"] || 
			[applicationName isEqual:@"Full Tilt Poker"] || [applicationName isEqual:@"PokerStarsFR"]) {
			data->order++;
			[data->outputArray addObject:outputEntry];
		} 
			
    }
}



@implementation HKLowLevel

@synthesize appName,appPID,appRef;

-(id)init 
{
	if ((self = [super init])) {
		logger = [SOLogger loggerForFacility:@"com.fullyfunctionalsoftware.blazingstars" options:ASL_OPT_STDERR];
	
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
		} else if ([apps containsObject:@"Full Tilt Poker"]) {
			appName = [NSString stringWithFormat:@"Full Tilt Poker"];
			[logger info:@"Found FullTilt client!"];
		} else if ([apps containsObject:@"PokerStarsFR"]) {
			appName = [NSString stringWithFormat:@"PokerStarsFR"];
			[logger info:@"PokerStarsFR"];
		} else {
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:@"Poker client not found!"];
			[alert setInformativeText:@"The PokerStars or Full Tilt client must be running for this program to operate.  Please start the client and then re-open BlazingStars."];
			[NSApp activateIgnoringOtherApps:YES];
			[alert runModal];
			[[NSApplication sharedApplication] terminate: nil];			
		}

		NSArray *pids = [[NSWorkspace sharedWorkspace] launchedApplications];
		
		for (id app in pids) {
			if ([[app objectForKey:@"NSApplicationName"] isEqualToString: appName]) {
				appPID =(pid_t) [[app objectForKey:@"NSApplicationProcessIdentifier"] intValue];
			}		
		}		
		
		appRef = AXUIElementCreateApplication(appPID);
		CFRetain(appRef);
		
		if (!appRef) {
			[logger critical:@"Could not get accessibility API reference to the %@ application.",appName];
			NSException* apiException = [NSException
										 exceptionWithName:@"PokerClientNotFoundException"
										 reason:@"Cannot get accessibility API reference to the Full Tilt application."									
										 userInfo:nil];
			@throw apiException;
		}		
		
		
		NSNotificationCenter *center = [ws notificationCenter];
		[center addObserver:self
				   selector:@selector(appTerminated:)
					   name:NSWorkspaceDidTerminateApplicationNotification
					 object:nil];
		
		int pcWorkspace = [self getPokerClientWorkspace];
		CGSWorkspace workspaceID;
		CGSGetWorkspace(_CGSDefaultConnection(), &workspaceID);
		if (workspaceID != pcWorkspace && pcWorkspace != -1) {
			[logger critical:@"Could not find %@ in this space! BS: %d PS: %d",appName,workspaceID,pcWorkspace];
			NSAlert *alert = [[[NSAlert alloc] init] autorelease];
			[alert addButtonWithTitle:@"OK"];
			[alert setMessageText:[NSString stringWithFormat:@"%@ client not found in this Space!",appName]];
			[alert setInformativeText:[NSString stringWithFormat:@"BlazingStars must be started in the same Space (virtual desktop) as %@.  Please re-open BlazingStars in the correct Space.",appName]];
			[NSApp activateIgnoringOtherApps:YES];
			[alert runModal];
			[[NSApplication sharedApplication] terminate: nil];			
			
		}
		
	}
	return self;
}

-(BOOL)pokerClientIsActive
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
			CFMakeCollectable(title);
			mainWindow = (AXUIElementRef)child;
		}
	}
	if (mainWindow) {
		return mainWindow;		
	} else {
		return NULL;
	}

}

-(NSRect)getWindowBounds:(AXUIElementRef)windowRef
{
	id *size;
	CGSize sizeVal;
	
	AXError axErr = AXUIElementCopyAttributeValue(windowRef,kAXSizeAttribute,(CFTypeRef *)&size);
	CFMakeCollectable(size);
	if (axErr != kAXErrorSuccess) {
		[logger critical:@"Could not get window size for windowRef: %@.  Error code: %d",windowRef,axErr];
		return NSMakeRect(0,0,0,0);
	}
	
	if (!AXValueGetValue((AXValueRef) size, kAXValueCGSizeType, &sizeVal)) {
		[logger warning:@"Could not get window size for windowRef: %@",windowRef];
		return NSMakeRect(0,0,0,0);
	} 
	
	id *position;
	axErr = AXUIElementCopyAttributeValue(windowRef,kAXPositionAttribute,(CFTypeRef *)&position);
	CFMakeCollectable(position);
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
    NSLog(@"Position: (%f, %f)", windowRect.origin.x, windowRect.origin.y);
    NSLog(@"Size: %f x %f", windowRect.size.width, windowRect.size.height);
	return windowRect;
}


-(NSArray *)getChildrenFrom:(AXUIElementRef)ref
{
	NSArray *children;
	AXError err = AXUIElementCopyAttributeValues(ref, kAXChildrenAttribute, 0, 100, (CFArrayRef *)&children);
	CFMakeCollectable(children);

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
	
	CFRelease(mouseEvent);
	mouseEvent = CGEventCreateMouseEvent(NULL,kCGEventLeftMouseUp,point,kCGMouseButtonLeft);
	CGEventSetFlags(mouseEvent,0);
	CGEventPost(kCGHIDEventTap,mouseEvent);

	CGAssociateMouseAndMouseCursorPosition(true);	
	FlushEventQueue(GetMainEventQueue());
	FlushEventQueue(GetCurrentEventQueue());
	
	CFRelease(mouseEvent);
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
		
	CFRelease(keyEventUp);
	CFRelease(keyEventDown);
}

-(void)keyPress:(int)keyCode 
{
	[self keyPress:keyCode with:0];
	
}

-(void)keyPress:(int)keyCode repeated:(int)times withFlush:(BOOL)flush
{
	CGEventRef keyEventDown = CGEventCreateKeyboardEvent(NULL,keyCode,true);
	CGEventSetFlags(keyEventDown,0);
	CGEventRef keyEventUp = CGEventCreateKeyboardEvent(NULL, keyCode, false);
	CGEventSetFlags(keyEventUp,0);
	
	for (int j = 0; j < times; j++) {
		CGEventPost(kCGAnnotatedSessionEventTap, keyEventDown);	
		CGEventPost(kCGAnnotatedSessionEventTap, keyEventUp);
		
		if (flush) {
			FlushEventQueue(GetMainEventQueue());
			FlushEventQueue(GetCurrentEventQueue());	
		}
	}	
	CFRelease(keyEventUp);
	CFRelease(keyEventDown);
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
	CFRelease(keyEventUp);
	CFRelease(keyEventDown);

}

-(void)appTerminated:(NSNotification *)note
{
	if ([[[note userInfo] objectForKey:@"NSApplicationProcessIdentifier"] isEqual:[NSNumber numberWithInt:appPID]]) {
		[logger notice:@"%@ terminated - quitting BlazingStars.",appName];
		[[NSApplication sharedApplication] terminate: nil];
	}
}

-(NSArray *)getCGPokerClientWindowList
{
	CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);
	NSMutableArray * prunedWindowList = [NSMutableArray array];
    WindowListApplierData data = {prunedWindowList, 0};
    CFArrayApplyFunction(windowList, CFRangeMake(0, CFArrayGetCount(windowList)), &WindowListApplierFunction, &data);
    CFRelease(windowList);
	[logger debug:@"pruned window list: %@",prunedWindowList];
	return prunedWindowList;
}

-(int)getWindowIDForTable:(AXUIElementRef)tableRef
{
	NSString *title;
	AXUIElementCopyAttributeValue(tableRef, kAXTitleAttribute, (CFTypeRef *)&title);		
	
	NSArray *windowList = [self getCGPokerClientWindowList];
	
	for (id window in windowList) {
		[logger debug:@"Window name: %@ Window ID: %@",
		 [window objectForKey:kWindowNameKey],
		 [window objectForKey:kWindowIDKey]];
		
		if ([[window objectForKey:kWindowNameKey] isEqualToString:title]) {
			return [[window objectForKey:kWindowIDKey] intValue];
		}
	}
	return -1;
}

-(int)getPokerClientWorkspace
{
	NSArray *windowList = [self getCGPokerClientWindowList];
	
	for (id window in windowList) {
		NSNumber *workspace = [window objectForKey:kWindowWorkspaceKey];
		if (workspace) {
			return [workspace intValue];
		}
	}
	return -1;
}

@end
