//
//  HKDispatchController.m
//  PokerHK
//
//  Created by Steven Hamblin on 31/05/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import "HKDispatchController.h"
#import "PrefsWindowController.h"
#import "HKScreenScraper.h"
#import "HKDefines.h"
#import <Carbon/Carbon.h>
#import <AppKit/NSAccessibility.h>
#import <asl.h>

extern NSString *appName;

EventHotKeyRef	gHotKeyRef;
EventHotKeyID	gHotKeyID;
EventHandlerUPP	gAppHotKeyFunction;

// Forwards
pascal OSStatus hotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
							  void *userData);

pascal OSStatus mouseEventHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
							  void *userData);

void axHotKeyObserverCallback(AXObserverRef observer, AXUIElementRef elementRef, CFStringRef notification, void *refcon);	

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
        // Finally, we are passed the windows in order from front to back by the window server
        // Should the user sort the window list we want to retain that order so that screen shots
        // look correct no matter what selection they make, or what order the items are in. We do this
        // by maintaining a window order key that we'll apply later.
        [outputEntry setObject:[NSNumber numberWithInt:data->order] forKey:kWindowOrderKey];
		
		// Look for PokerStars window:
		if ([applicationName isEqual:appName]) {
			data->order++;
			
			[data->outputArray addObject:outputEntry];
			
		}
    }
}



// Allow global access to the controller.
HKDispatchController *dc;
HKWindowManager *wm;

@implementation HKDispatchController

@synthesize keyMap;
@synthesize toggled;

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
	
	return;
}


#pragma mark Initialization

-(id)init
{
	if ((self = [super init])) {
		fieldMap = [[NSMutableDictionary alloc] init];
		keyMap = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"keyMap" ofType: @"plist"]];
		speechCommands = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"speechCommands" ofType:@"plist"]];
		potBetAmounts = [[NSMutableDictionary alloc] init];
		amountToChange = 2.0;
		rounding = NO;
		autoBetRounding = NO;
		toggled = YES;

		// Not in key map...need to refactor this.
		NSMutableArray *commands = [NSMutableArray arrayWithCapacity:20];
		for (id keyName in keyMap) {
			[commands addObject:[speechCommands objectForKey:[[keyMap objectForKey:keyName] objectAtIndex:0]]];
		}
		[commands addObject:@"Increase Bet"];
		[commands addObject:@"Decrease Bet"];
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"voiceCommandsEnabledKey"]) {
			speechRecognizer = [[NSSpeechRecognizer alloc] init];
			[speechRecognizer setCommands:commands];
			[speechRecognizer setDelegate:self];
			[speechRecognizer setListensInForegroundOnly:NO];
			[speechRecognizer setDisplayedCommandsTitle:@"BlazingStars commands"];			
		} else {
			speechRecognizer = nil;
		}
    }
	return self;
}

-(void)awakeFromNib 
{
	dc = self;
	wm = windowManager;

	// Register global event handler.
	EventTypeSpec eventType;
	eventType.eventClass=kEventClassKeyboard;
	eventType.eventKind=kEventHotKeyPressed;
	
	EventTypeSpec mouseEventType;
	mouseEventType.eventClass=kEventClassMouse;
	mouseEventType.eventKind=kEventMouseWheelMoved;

	InstallApplicationEventHandler(&hotKeyHandler,1,&eventType,(void *)self,&hotkeyEventHandlerRef);
	InstallEventHandler(GetEventMonitorTarget(),&mouseEventHandler,1,&mouseEventType,(void *)self,&mouseEventHandlerRef);
	
	NSArray *pids = [[NSWorkspace sharedWorkspace] launchedApplications];
	
	for (id app in pids) {
		if ([[app objectForKey:@"NSApplicationName"] isEqualToString: @"PokerStars"]) {
			pokerstarsPID =(pid_t) [[app objectForKey:@"NSApplicationProcessIdentifier"] intValue];
		}
	}
	
	// Accessibility framework stuff now.
	appRef = AXUIElementCreateApplication(pokerstarsPID);
	
	if (!appRef) {
		NSLog(@"Could not get application ref.");
		NSException* apiException = [NSException
									exceptionWithName:@"PokerStarsNotFoundException"
									reason:@"Cannot get accessibility API reference to the PokerStars application."									
									userInfo:nil];
		@throw apiException;
	}

	systemWideElement = AXUIElementCreateSystemWide();

	// Get the PrefsWindowController.
	prefsWindowController = [PrefsWindowController sharedPrefsWindowController];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"voiceCommandsEnabledKey"] == YES) {
		NSLog(@"In awakeFromNib, dispatchController, starting speech recognition.");
		[speechRecognizer startListening];	
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopVoiceCommands:) name:NSApplicationWillTerminateNotification object:nil];
	}
}

- (void)stopVoiceCommands:(NSNotification *)notification
{
	NSLog(@"Turning off the speech recognizer.");
	[speechRecognizer stopListening];
}

-(void)setPotBetAmount:(float)amount forTag:(int)tag
{
	[potBetAmounts setObject:[NSNumber numberWithFloat:amount] forKey:[NSNumber numberWithInt:tag]];
	NSLog(@"Pot bet amounts now: %@",potBetAmounts);
}

-(void)turnOnRounding:(BOOL)round
{
	NSLog(@"Setting rounding to: %@\n", (round ? @"YES" : @"NO"));
	rounding = round;
}

-(void)setRoundingAmount:(float)amount
{
	NSLog(@"Setting rounding amount to: %f\n",amount);
	roundingAmount = amount;
}

-(void)setRoundingType:(int)type
{
	NSLog(@"Setting rounding type to: %d\n",type);
	roundingType = type;
}

-(void)autoBetRounding:(BOOL)aBool
{
	NSLog(@"Setting autoBetRounding to: %@\n",(aBool ? @"YES" : @"NO"));
	autoBetRounding = aBool;
}

-(void)autoBetAllIn:(BOOL)aBool
{
	NSLog(@"Setting autoBetAllIn to:%@\n",(aBool ? @"YES" : @"NO"));
	autoBetAllIn = aBool;
}

#pragma mark Hot Key Registration

-(BOOL)keyComboAlreadyRegistered:(KeyCombo)kc 
{
	NSLog(@"Checking to see if key code is registered.");
	for (id key in fieldMap) {
		KeyCombo temp = [[key pointerValue] keyCombo];
		if (temp.code == kc.code && temp.flags == kc.flags) 
			return YES;
	}
	return NO;
}

-(void)registerHotKeyForControl:(SRRecorderControl *)control withTag:(int)tag
{
	NSLog(@"In registering function for SRRC. Tag: %d  Combo: %@",tag,[control keyComboString]);
	
	if ([[fieldMap allKeys] containsObject:[NSValue valueWithPointer:control]] == YES) {
		[fieldMap removeObjectForKey:[NSValue valueWithPointer:control]];
		NSLog(@"Yes, we found it.  Unregistering.");		
	} 

	
	if ([control keyCombo].code != -1) {
		if ([self keyComboAlreadyRegistered:[control keyCombo]] == NO) {
			[fieldMap setObject:[NSArray arrayWithObjects:[NSValue valueWithPointer:NULL],[NSNumber numberWithInt:tag],nil] forKey:[NSValue valueWithPointer:control]];			
		} else {
			NSLog(@"Key combo is a duplicate.");
			// Warn the user.
			NSAlert *alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Shortcut keys must be unique, and the key combination %@ is already being used.",[control keyComboString]]
							defaultButton:@"OK" 
							alternateButton:nil 
							otherButton:nil
				informativeTextWithFormat:@"You will need to select a new key combination."];

			[alert beginSheetModalForWindow:[control window]
							  modalDelegate:self
							 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
								contextInfo:NULL];

			KeyCombo temp; temp.code = -1; temp.flags = 0;
			[control setKeyCombo:temp];
						
			}
	} else {
		NSLog(@"Didn't register null key.");
	}
}

-(void)unregisterAllHotKeys
{
	NSLog(@"Unregistering all hotkeys.");
	SRRecorderControl *sc;
	NSMutableDictionary *newFieldMap = [[NSMutableDictionary alloc] init];
	for (id key in fieldMap) {
		sc = [key pointerValue];
		int tag = [[[fieldMap objectForKey:key] objectAtIndex:1] intValue];

		if (tag != TOGGLETAG) {
			NSLog(@"Unregister combo: %@ withTag: %d",[sc keyComboString],[[[fieldMap objectForKey:key] objectAtIndex:1] intValue]);
			OSStatus errCode = UnregisterEventHotKey([[[fieldMap objectForKey:key] objectAtIndex:0] pointerValue]);
			[newFieldMap setObject:[NSArray arrayWithObjects:[NSValue valueWithPointer:NULL],[NSNumber numberWithInt:tag],nil] forKey:key];
			if (errCode != noErr) {
				NSLog(@"Failed to unregister hotkey! :-> %d",errCode);
			}
			
		}
	}
	fieldMap = [newFieldMap mutableCopy];
}

-(void)registerAllHotKeys
{
	NSLog(@"Registering all keys!");
	EventHotKeyRef hkref;
	NSMutableDictionary *newFieldMap = [[NSMutableDictionary alloc] init];
	for (id field in fieldMap) {
		int tag = [[[fieldMap objectForKey:field] objectAtIndex:1] intValue];
		SRRecorderControl *control = [field pointerValue];
		
		gHotKeyID.signature='wwhk';
		gHotKeyID.id=tag;
		
		NSLog(@"Tag: %d Keycombo: %@",tag,[control keyComboString]);
				
		OSStatus err = RegisterEventHotKey([control keyCombo].code, SRCocoaToCarbonFlags([control keyCombo].flags), gHotKeyID, 
							GetApplicationEventTarget(), 0, &hkref);

		if (err != noErr) {
			NSLog(@"Registration failed! %d",err);
		}
		
		[newFieldMap setObject:[NSArray arrayWithObjects:[NSValue valueWithPointer:hkref],[NSNumber numberWithInt:tag],nil] forKey:field];
	}
	NSLog(@"Length: %d -> %@",[[fieldMap allKeys] count],fieldMap);
	fieldMap = [newFieldMap mutableCopy];
}


-(void)toggleAllHotKeys
{
	NSLog(@"Toggling all hotkeys.");
	NSLog(@"Toggled is: %@\n", (toggled ? @"YES" : @"NO")); 
	NSLog(@"Activated is: %@\n", ([windowManager activated] ? @"YES" : @"NO"));
	
	if (toggled == YES) {
		NSLog(@"Toggling off.");
		toggled = NO;
		if ([windowManager activated] == YES) {
			NSLog(@"unregistering!");
			[self unregisterAllHotKeys];			
		}
	} else if (toggled == NO) {
		NSLog(@"Toggling on.");
		toggled = YES;
		if ([windowManager activated] == YES) {
			NSLog(@"registering!");
			[self registerAllHotKeys];			
		}
	}
}

-(void)activateHotKeys
{
	NSLog(@"Turning hotkeys on because window activated.");
	NSLog(@"Toggled is: %@\n", (toggled ? @"YES" : @"NO")); 
	NSLog(@"Activated is: %@\n", ([windowManager activated] ? @"YES" : @"NO"));
	
	if (toggled == YES) {
		if ([windowManager activated] == YES) {
			NSLog(@"registering!");
			[self registerAllHotKeys];			
		}		
	} else {
		NSLog(@"Global hotkey deactivation is turned on - skipping hotkey registration.");
	}
}

-(void)deactivateHotKeys
{
	NSLog(@"Turning hotkeys off because window deactivated.");
	NSLog(@"Toggled is: %@\n", (toggled ? @"YES" : @"NO")); 
	NSLog(@"Activated is: %@\n", ([windowManager activated] ? @"YES" : @"NO"));
	
	if (toggled == YES) {
		if ([windowManager activated] == NO) {
			NSLog(@"runegistering!");
			[self unregisterAllHotKeys];			
		}		
	} else {
		NSLog(@"Global hotkey deactivation is turned on - skipping hotkey registration.");
	}	
}

#pragma mark Hot Key Execution.

-(void)buttonPress:(NSString *)prefix withButton:(NSString *)size
{
	// The prefix maps the button to the plist for the specified theme.  
	NSLog(@"Prefix: %@  Size: %@ X: %g Y: %g H: %g W: %g",prefix,size,
		[[themeController param:[prefix stringByAppendingString:@"OriginX"]] floatValue],
		[[themeController param:[prefix stringByAppendingString:@"OriginY"]] floatValue],
		[[themeController param:[size stringByAppendingString:@"ButtonHeight"]] floatValue],
		  [[themeController param:[size stringByAppendingString:@"ButtonWidth"]] floatValue]);
	
	[windowManager clickPointForXSize:[[themeController param:[prefix stringByAppendingString:@"OriginX"]] floatValue]
					andYSize:[[themeController param:[prefix stringByAppendingString:@"OriginY"]] floatValue]
				   andHeight:[[themeController param:[size stringByAppendingString:@"ButtonHeight"]] floatValue]
					andWidth:[[themeController param:[size stringByAppendingString:@"ButtonWidth"]] floatValue]];		
}

-(void)buttonPressAllTables:(int)tag
{
	NSArray *tables = [windowManager getAllPokerTables];
	NSLog(@"Poker table list: %@",tables);
	
	for (id table in tables) {
		NSLog(@"If no tables, shouldn't get here.");
		AXUIElementRef tableRef = [table pointerValue];
		AXUIElementPerformAction(tableRef, kAXRaiseAction);
		
		NSString *prefix = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",tag]] objectAtIndex:0];
		NSString *size = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",tag]] objectAtIndex:1];
		[self buttonPress:prefix withButton:size];		
		[NSThread sleepForTimeInterval:0.3];
	}
}

-(float)getBetSize
{
	NSPoint clickPoint = [windowManager getClickPointForXSize:[[themeController param:@"betBoxOriginX"] floatValue]
										 andYSize:[[themeController param:@"betBoxOriginY"] floatValue]
										andHeight:[[themeController param:@"betBoxHeight"] floatValue]
										 andWidth:[[themeController param:@"betBoxWidth"] floatValue]];
	
	NSLog(@"x=%f,y=%f",clickPoint.x,clickPoint.y);
	AXUIElementRef betBoxRef;
	
	AXError err = AXUIElementCopyElementAtPosition(appRef,
									 clickPoint.x,
									 clickPoint.y,
									 &betBoxRef);
	
	switch(err) {
		case kAXErrorNoValue:
			NSLog(@"CopyElementAtPosition reports that the bet box is not where we think it is! (kAXErrorNoValue)");
			return -1;
		case kAXErrorIllegalArgument:
			NSLog(@"CopyElementAtPosition reports that one of the arguments is illegal! (kAXErrorIllegalArgument)");
			return -1;
		case kAXErrorInvalidUIElement:
			NSLog(@"CopyElementAtPosition reports that the AXUIElementRef (appRef) is invalid! (kAXErrorInvalidUIElement)");
			return -1;
		case kAXErrorCannotComplete:
			NSLog(@"CopyElementAtPosition reports that the messaging API has failed! (kAXErrorCannotComplete)");
			return -1;
		case kAXErrorNotImplemented:
			NSLog(@"CopyElementAtPosition reports that the process does not fully support the accessibility API! (kAXErrorNotImplmented)");
			return -1;
		default: NSLog(@"CopyElementAtPosition succeeded!"); break;
	}
	
	NSString *value;
	err = AXUIElementCopyAttributeValue(betBoxRef, kAXValueAttribute,(CFTypeRef *)&value);
	
	if (!value || err != kAXErrorSuccess) {
		NSLog(@"Could not retrieve value from betBoxRef!");
		
		switch(err) {
			case kAXErrorAttributeUnsupported:
				NSLog(@"CopyAttributeValue reports that the specified AXUIElementref (betBoxRef) does not support the specified attribute (ValueAttribute)! (kAXErrorAttributeUnsupported)");
			case kAXErrorNoValue:
				NSLog(@"CopyAttributeValue reports that the bet box is not where we think it is! (kAXErrorNoValue)");
			case kAXErrorIllegalArgument:
				NSLog(@"CopyAttributeValue reports that one of the arguments is illegal! (kAXErrorIllegalArgument)");
			case kAXErrorInvalidUIElement:
				NSLog(@"CopyAttributeValue reports that the AXUIElementRef (betBoxRef) is invalid! (kAXErrorInvalidUIElement)");
			case kAXErrorCannotComplete:
				NSLog(@"CopyAttributeValue reports that the messaging API has failed! (kAXErrorCannotComplete)");
			case kAXErrorNotImplemented:
				NSLog(@"CopyAttributeValue reports that the process does not fully support the accessibility API! (kAXErrorNotImplmented)");
			default: NSLog(@"CopyAttributeValue succeeded!? How did we get here?"); break;
		}
		return -1;
	}
	NSLog(@"Value:  %@",value);

	return [value floatValue];
}

-(void)setBetSize:(float)amount
{
	NSPoint clickPoint = [windowManager getClickPointForXSize:[[themeController param:@"betBoxOriginX"] floatValue]
											andYSize:[[themeController param:@"betBoxOriginY"] floatValue]
										   andHeight:[[themeController param:@"betBoxHeight"] floatValue]
											andWidth:[[themeController param:@"betBoxWidth"] floatValue]];
	
	NSLog(@"x=%f,y=%f",clickPoint.x,clickPoint.y);
	AXUIElementRef betBoxRef;
	
	AXUIElementCopyElementAtPosition(appRef,
									 clickPoint.x,
									 clickPoint.y,
									 &betBoxRef);
	
	// Set up string to the value to bet, and then strip trailing zeros if the bet is an even amount.
	NSString *valueToSet = [NSString stringWithFormat:@"%.2f",amount];
	NSLog(@"Attempting to set value: %@", valueToSet);
	if ([[valueToSet substringFromIndex:[valueToSet length]-2] isEqual:@"00"]) {
		valueToSet = [valueToSet substringToIndex:[valueToSet length]-3];
		NSLog(@"String is now: %@",valueToSet);
	}
	

	CGAssociateMouseAndMouseCursorPosition(false);
	CGEventRef mouseEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown,NSPointToCGPoint(clickPoint), kCGMouseButtonLeft);
	
	// Cancel any of the modifier keys - this cost me a day of bug-hunting!
	CGEventSetFlags(mouseEvent,0);
	CGEventPost(kCGSessionEventTap,mouseEvent);
	
	mouseEvent = CGEventCreateMouseEvent(NULL,kCGEventLeftMouseUp,NSPointToCGPoint(clickPoint),kCGMouseButtonLeft);
	CGEventSetFlags(mouseEvent,0);
	CGEventPost(kCGSessionEventTap,mouseEvent);
	CGAssociateMouseAndMouseCursorPosition(true);
	
	NSLog(@"Num of events in queue: %d",GetNumEventsInQueue(GetMainEventQueue()));
	
	NSLog(@"Flushing queue!");
	FlushEventQueue(GetMainEventQueue());
	FlushEventQueue(GetCurrentEventQueue());	
	
	CGEventRef keyEventDown = CGEventCreateKeyboardEvent(NULL,124,true);
	CGEventSetFlags(keyEventDown,0);
	CGEventRef keyEventUp = CGEventCreateKeyboardEvent(NULL, 124, false);
	CGEventSetFlags(keyEventUp,0);

	for (int j = 0; j < 10; j++) {
		CGEventPost(kCGSessionEventTap, keyEventDown);	
		CGEventPost(kCGSessionEventTap, keyEventUp);
		
		FlushEventQueue(GetMainEventQueue());
		FlushEventQueue(GetCurrentEventQueue());	
		
	}	
	
	keyEventDown = CGEventCreateKeyboardEvent(NULL,117,true);
	CGEventSetFlags(keyEventDown,0);			
	keyEventUp = CGEventCreateKeyboardEvent(NULL,117,false);
	CGEventSetFlags(keyEventDown,0);			
	
	for (int j = 0; j < 10; j++) {
		CGEventPost(kCGAnnotatedSessionEventTap, keyEventDown);		
		CGEventPost(kCGAnnotatedSessionEventTap, keyEventUp);
	}
	

	keyEventDown = CGEventCreateKeyboardEvent(NULL,51,true);
	CGEventSetFlags(keyEventDown,0);			
	keyEventUp = CGEventCreateKeyboardEvent(NULL,51,false);
	CGEventSetFlags(keyEventDown,0);			
	
	for (int j = 0; j < 10; j++) {
		CGEventPost(kCGAnnotatedSessionEventTap, keyEventDown);		
		CGEventPost(kCGAnnotatedSessionEventTap, keyEventUp);
	}
	
	UniChar buffer;
	keyEventDown = CGEventCreateKeyboardEvent(NULL, 1, true);
	keyEventUp = CGEventCreateKeyboardEvent(NULL, 1, false);
	CGEventSetFlags(keyEventDown,0);		
	CGEventSetFlags(keyEventUp,0);		
	for (int i = 0; i < [valueToSet length]; i++) {
		[valueToSet getCharacters:&buffer range:NSMakeRange(i, 1)];
		NSLog(@"Character: %c",buffer);
		CGEventKeyboardSetUnicodeString(keyEventDown, 1, &buffer);
		CGEventPost(kCGAnnotatedSessionEventTap, keyEventDown);
		CGEventKeyboardSetUnicodeString(keyEventUp, 1, &buffer);
		CGEventPost(kCGAnnotatedSessionEventTap, keyEventUp);
	}
}

-(float)betIncrement 
{
	NSArray *gameParams = [windowManager getGameParameters];
	float betIncrement; 
	
	// Get updated amountToChange;
	amountToChange = [[prefsWindowController stepper] floatValue];
	
	int row = [[prefsWindowController radiobuttonMatrix] selectedRow];
	switch(row) {
		case 0:
			betIncrement = amountToChange * [[gameParams objectAtIndex:HKBigBlind] floatValue];
			NSLog(@"amountToChange: %g  bigBlind: %g  betIncrement: %g", amountToChange,[[gameParams objectAtIndex:HKBigBlind] floatValue], betIncrement);
			break;
		case 1:
			betIncrement = amountToChange * [[gameParams objectAtIndex:HKSmallBlind] floatValue];
			NSLog(@"amountToChange: %g  smallBlind: %g  betIncrement: %g", amountToChange,[[gameParams objectAtIndex:HKSmallBlind] floatValue], betIncrement);			
			break;
	}
	return betIncrement;
}

-(void)incrementBetSize:(long)delta
{
	float betSize = [self getBetSize];
	NSLog(@"Got betsize: %g",betSize);
	betSize += [self betIncrement] * (float)delta;
	[self setBetSize:betSize];
}

-(void)decrementBetSize:(long)delta
{
	float betSize = [self getBetSize];
	NSLog(@"Got betsize: %g",betSize);
	betSize -= [self betIncrement] * (float)delta;
	[self setBetSize:betSize];
}

-(void)potBet:(int)tag
{
	NSLog(@"In potBet");
	
	float potSize = [screenScraper getPotSize];
	NSLog(@"Got pot size: %f",potSize);
	
	// Process:  need to get the value from the 
	float potBetAmt = [[potBetAmounts objectForKey:[NSNumber numberWithInt:tag]] floatValue] / 100;
	NSLog(@"Got potBetAmt: %f",potBetAmt);
	float betSize = potSize * potBetAmt;
	
	NSLog(@"New betsize: %f",betSize);
		
	if (rounding == YES) {
		NSLog(@"Rounding!");
		NSArray *gameParameters = [windowManager getGameParameters];		
		float blindSize;
		if (roundingType == 1) {
			NSLog(@"Small blind!");
			blindSize = [[gameParameters objectAtIndex:HKSmallBlind] floatValue];
		} else {
			NSLog(@"Big blind!");
			blindSize = [[gameParameters objectAtIndex:HKBigBlind] floatValue];
		}
		NSLog(@"blindSize: %f",blindSize);
		float blindAdj = blindSize * roundingAmount;
		NSLog(@"blindAdjustment: %f",blindAdj);
		if (fmod(betSize,blindAdj) != 0) {
			NSLog(@"Adjusting!");
			betSize = ((int)(betSize / blindAdj) * blindAdj) + blindAdj;			
		}

		NSLog(@"Betsize after adjustment: %f",betSize);
	} 

	[self setBetSize:betSize];
	
	if (autoBetRounding == YES) {
		NSString *prefix = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",3]] objectAtIndex:0];
		NSString *size = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",3]] objectAtIndex:1];
		[self buttonPress:prefix withButton:size];		
	}
}

-(void)allIn
{
	[self setBetSize:99999];
	
	if (autoBetAllIn == YES) {
		NSString *prefix = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",3]] objectAtIndex:0];
		NSString *size = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",3]] objectAtIndex:1];
		[self buttonPress:prefix withButton:size];				
	}
}

-(void)leaveAllTables
{
	[self buttonPressAllTables:15];
}

-(void)sitOutAllTables
{
	[self buttonPressAllTables:10];
}


-(void)debugHK
{
	NSLog(@"In the debugging hotkey.");
	CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionAll, kCGNullWindowID);

//	NSLog(@"window list: %@",windowList);
	NSMutableArray * prunedWindowList = [NSMutableArray array];
    WindowListApplierData data = {prunedWindowList, 0};
    CFArrayApplyFunction(windowList, CFRangeMake(0, CFArrayGetCount(windowList)), &WindowListApplierFunction, &data);
    CFRelease(windowList);

	NSLog(@"pruned window list: %@",prunedWindowList);
	
	AXUIElementRef window = [windowManager getMainWindow];
	
	NSString *name;
	AXUIElementCopyAttributeValue(window,kAXTitleAttribute, (CFTypeRef *)&name);
	
	NSLog(@"Current window name: %@",name);
	NSArray *components = [name componentsSeparatedByString:@"-"];
	NSLog(@"Components: %@",components);
	
	NSLog(@"Writing log to pasteboard.");
	NSPasteboard *cb = [NSPasteboard generalPasteboard];
	[cb declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
	
	NSMutableString *log = [NSMutableString stringWithCapacity:1000];
	
	aslmsg q,m;
	aslresponse r;
	q = asl_new(ASL_TYPE_QUERY);
	asl_set_query(q, ASL_KEY_SENDER, "BlazingStars", ASL_QUERY_OP_EQUAL);
	r = asl_search(NULL, q);

	int i;
	const char *key;
	
	while (NULL != (m = aslresponse_next(r)))
	{
		for (i = 0; (NULL != (key = asl_key(m, i))); i++)
		{
			[log appendString:[NSString stringWithFormat:@"%s %s %s\n",asl_get(m,"CFLog Local Time"),asl_get(m,ASL_KEY_SENDER),asl_get(m,ASL_KEY_MSG)]];
		}
	}
	aslresponse_free(r);

	[cb setString:log forType: NSStringPboardType];


}

-(void)voiceCommandsChangedState
{
	NSLog(@"In voiceCommandsChangedState");
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"voiceCommandsEnabledKey"]) {
		NSLog(@"Enabling voice commands.");
		if (speechRecognizer == nil) {
			NSMutableArray *commands = [NSMutableArray arrayWithCapacity:20];
			for (id keyName in keyMap) {
				[commands addObject:[speechCommands objectForKey:[[keyMap objectForKey:keyName] objectAtIndex:0]]];
			}
			[commands addObject:@"Increase Bet"];
			[commands addObject:@"Decrease Bet"];
			
			speechRecognizer = [[NSSpeechRecognizer alloc] init];
			[speechRecognizer setCommands:commands];
			[speechRecognizer setDelegate:self];
			[speechRecognizer setListensInForegroundOnly:NO];
			[speechRecognizer setDisplayedCommandsTitle:@"BlazingStars commands"];						
		}
		
		[speechRecognizer startListening];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopVoiceCommands:) name:NSApplicationWillTerminateNotification object:nil];		
	} else {
		NSLog(@"Disabling voice commands.");
		[speechRecognizer stopListening];
		speechRecognizer = nil;
	}
}

- (void)speechRecognizer:(NSSpeechRecognizer *)sender didRecognizeCommand:(id)command {
	for (id key in speechCommands) {
		if ([[speechCommands objectForKey:key] isEqualToString:command]) {
			NSLog(@"Speech command recognized!  Command was: %@",key);

			for (id field in keyMap) {
				NSLog(@"km: %@, field: %@",[[keyMap objectForKey:field] objectAtIndex:0],field);
				if ([[[keyMap objectForKey:field] objectAtIndex:0] isEqualToString:key]) {
					NSLog(@"Found a match! %@",field);
					[self simulateHotKey:[field intValue]];
					return;
				}
			}
			
			// Not in key map.  I need to refactor this...
			if ([key isEqualToString:@"increaseBet"]) {
				[self simulateHotKey:13];
			}
			if ([key isEqualToString:@"decreaseBet"]) {
				[self simulateHotKey:14];
			}
		}
	}
}

- (void)simulateHotKey:(int)tag
{
	NSLog(@"In simulateHotKey, tag is: %d",tag);
	// Global toggle key.
	if (tag == TOGGLETAG) {
		[self toggleAllHotKeys];
	}
	NSString *size,*prefix;
	// Don't fire the keys if we're not in a poker window.
	if ([wm pokerWindowIsActive] == YES) {
		switch (tag) {
			case 12:
				[self sitOutAllTables];
				break;
			case 13:
				[self incrementBetSize:1];
				break;
			case 14:
				[self decrementBetSize:1];
				break;
			case 16:
				[self leaveAllTables];
				break;
			case 17:
			case 18:
			case 19:
			case 20:
				[self potBet:tag];
				break;
			case 21:
				[self allIn];
				break;
			case 99:
				[self debugHK];
				break;
			default:
				prefix = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",tag]] objectAtIndex:0];
				size = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",tag]] objectAtIndex:1];
								NSLog(@"Tag: %d Prefix: %@ Size: %@",tag,prefix,size);
				[self buttonPress:prefix withButton:size];
				break;
		}
	} else {
		NSLog(@"I was asked to simulate a hotkey I don't know: %d",tag);
	}
}

@end


pascal OSStatus hotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
							  void *userData)
{
	NSLog(@"In hotKeyHandler!");

	OSStatus retCode;
	
	EventHotKeyID hkCom;
	GetEventParameter(theEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,
					  sizeof(hkCom),NULL,&hkCom);
	
	int l = hkCom.id;

	NSString *size,*prefix;
	
	// Global toggle key.
	if (l == TOGGLETAG) {
		[(id)userData toggleAllHotKeys];
		return noErr;
	}
	
	// Don't fire the keys if we're not in a poker window.
	if ([wm pokerWindowIsActive] == YES) {
		switch (l) {
			case 12:
				[(id)userData sitOutAllTables];
				break;
			case 13:
				[(id)userData incrementBetSize:1];
				break;
			case 14:
				[(id)userData decrementBetSize:1];
				break;
			case 16:
				[(id)userData leaveAllTables];
				break;
			case 17:
			case 18:
			case 19:
			case 20:
				[(id)userData potBet:l];
				break;
			case 21:
				[(id)userData allIn];
				break;
			case 99:
				[(id)userData debugHK];
				break;
			default:
				prefix = [[[(id)userData keyMap] objectForKey:[NSString stringWithFormat:@"%d",l]] objectAtIndex:0];
				size = [[[(id)userData keyMap] objectForKey:[NSString stringWithFormat:@"%d",l]] objectAtIndex:1];
				[(id)userData buttonPress:prefix withButton:size];
				break;
		}
		
		
	} else {
		retCode = eventNotHandledErr;
	}
	retCode = noErr;
	
	NSLog(@"Number of events in mainQueue: %d  Number of events in currentQueue: %d", 
		GetNumEventsInQueue(GetMainEventQueue()),
		  GetNumEventsInQueue(GetCurrentEventQueue()));

	NSLog(@"Flushing the queue!");
	// Flush the events from the hotkey queue.
	OSStatus mainQueue = FlushEventQueue(GetMainEventQueue());
	OSStatus currentQueue = FlushEventQueue(GetCurrentEventQueue());
	
	NSLog(@"Error status for main queue: %d.  Error status for current queue: %d.",mainQueue, currentQueue);
	
	return retCode;
}

pascal OSStatus mouseEventHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
							  void *userData)
{
//	NSLog(@"In mouse event handler!");
	if ([[[PrefsWindowController sharedPrefsWindowController] scrollWheelCheckBox] state] == NSOnState) {
		if ([wm pokerWindowIsActive] == YES) {
			long delta;
			GetEventParameter(theEvent, kEventParamMouseWheelDelta, typeSInt32, NULL, sizeof(long), NULL, &delta);
			NSLog(@"Got delta: %d",delta);
			if (delta > 0) {
				[(id)userData incrementBetSize:delta];
			} else {
				[(id)userData decrementBetSize:delta];
			}
		} else {
			CallNextEventHandler(nextHandler, theEvent);
			return eventNotHandledErr;
		}
	}
	return noErr;
}
