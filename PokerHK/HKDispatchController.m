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

EventHotKeyRef	gHotKeyRef;
EventHotKeyID	gHotKeyID;
EventHandlerUPP	gAppHotKeyFunction;

// Forwards
pascal OSStatus hotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
							  void *userData);

pascal OSStatus mouseEventHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
							  void *userData);

void axHotKeyObserverCallback(AXObserverRef observer, AXUIElementRef elementRef, CFStringRef notification, void *refcon);	

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
		logger = [SOLogger loggerForFacility:@"com.fullyfunctionalsoftware.blazingstars" options:ASL_OPT_STDERR];
		[logger info:@"Initializing dispatchController."];
				
		fieldMap = [[NSMutableDictionary alloc] init];
		keyMap = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"keyMap" ofType: @"plist"]];
		speechCommands = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"speechCommands" ofType:@"plist"]];
		potBetAmounts = [[NSMutableDictionary alloc] init];
		pfrAmounts = [[NSMutableDictionary alloc] init];
		amountToChange = 2.0;
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
	
	systemWideElement = AXUIElementCreateSystemWide();

	// Get the PrefsWindowController.
	prefsWindowController = [PrefsWindowController sharedPrefsWindowController];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"voiceCommandsEnabledKey"] == YES) {
		[logger info:@"Activating speech recognition at startup."];
		[speechRecognizer startListening];	
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopVoiceCommands:) name:NSApplicationWillTerminateNotification object:nil];
	}
}

- (void)stopVoiceCommands:(NSNotification *)notification
{
	[speechRecognizer stopListening];
}

-(void)setPotBetAmount:(float)amount forTag:(int)tag
{
	[potBetAmounts setObject:[NSNumber numberWithFloat:amount] forKey:[NSNumber numberWithInt:tag]];
}

-(void)setPFRAmount:(float)amount forTag:(int)tag
{
	[pfrAmounts setObject:[NSNumber numberWithFloat:amount] forKey:[NSNumber numberWithInt:tag]];
}

-(void)setRoundingAmount:(float)amount
{
	roundingAmount = amount;
}

-(void)setRoundingType:(int)type
{
	roundingType = type;
}


#pragma mark Hot Key Registration

-(BOOL)keyComboAlreadyRegistered:(KeyCombo)kc 
{
	for (id key in fieldMap) {
		KeyCombo temp = [[key pointerValue] keyCombo];
		if (temp.code == kc.code && temp.flags == kc.flags) 
			return YES;
	}
	return NO;
}

-(void)registerHotKeyForControl:(SRRecorderControl *)control withTag:(int)tag
{
	[logger info:@"In registering function for SRRC. Tag: %d  Combo: %@",tag,[control keyComboString]];
	
	if ([[fieldMap allKeys] containsObject:[NSValue valueWithPointer:control]] == YES) {
		[fieldMap removeObjectForKey:[NSValue valueWithPointer:control]];
	} 

	
	if ([control keyCombo].code != -1) {
		if ([self keyComboAlreadyRegistered:[control keyCombo]] == NO) {
			[fieldMap setObject:[NSArray arrayWithObjects:[NSValue valueWithPointer:NULL],[NSNumber numberWithInt:tag],nil] forKey:[NSValue valueWithPointer:control]];			
		} else {
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
		[logger notice:@"Didn't register null key."];
	}
}

-(void)unregisterAllHotKeys
{
	SRRecorderControl *sc;
	NSMutableDictionary *newFieldMap = [[NSMutableDictionary alloc] init];
	for (id key in fieldMap) {
		sc = [key pointerValue];
		int tag = [[[fieldMap objectForKey:key] objectAtIndex:1] intValue];

		if (tag != TOGGLETAG) {
			OSStatus errCode = UnregisterEventHotKey([[[fieldMap objectForKey:key] objectAtIndex:0] pointerValue]);
			[newFieldMap setObject:[NSArray arrayWithObjects:[NSValue valueWithPointer:NULL],[NSNumber numberWithInt:tag],nil] forKey:key];
			if (errCode != noErr) {
				[logger warning:@"Unregistering hotkey combo: %@ withTag: %d failed!",[sc keyComboString],[[[fieldMap objectForKey:key] objectAtIndex:1] intValue]];
			}
			
		}
	}
	fieldMap = [newFieldMap mutableCopy];
}

-(void)registerAllHotKeys
{
	EventHotKeyRef hkref;
	NSMutableDictionary *newFieldMap = [[NSMutableDictionary alloc] init];
	for (id field in fieldMap) {
		int tag = [[[fieldMap objectForKey:field] objectAtIndex:1] intValue];
		SRRecorderControl *control = [field pointerValue];
		
		gHotKeyID.signature='wwhk';
		gHotKeyID.id=tag;
		
		//NSLog(@"Tag: %d Keycombo: %@",tag,[control keyComboString]);
				
		OSStatus err = RegisterEventHotKey([control keyCombo].code, SRCocoaToCarbonFlags([control keyCombo].flags), gHotKeyID, 
							GetApplicationEventTarget(), 0, &hkref);

		if (err != noErr) {
			[logger warning:@"Registration failed! %d",err];
		}
		
		[newFieldMap setObject:[NSArray arrayWithObjects:[NSValue valueWithPointer:hkref],[NSNumber numberWithInt:tag],nil] forKey:field];
	}
	fieldMap = [newFieldMap mutableCopy];
}


-(void)toggleAllHotKeys
{
	if (toggled == YES) {
		toggled = NO;
		if ([windowManager activated] == YES) {
			[self unregisterAllHotKeys];			
		}
	} else if (toggled == NO) {
		toggled = YES;
		if ([windowManager activated] == YES) {
			[self registerAllHotKeys];			
		}
	}
}

-(void)activateHotKeys
{
	if (toggled == YES) {
		if ([windowManager activated] == YES)
			[self registerAllHotKeys];			
	} 
}

-(void)deactivateHotKeys
{
	if (toggled == YES) {
		if ([windowManager activated] == NO) {
			[self unregisterAllHotKeys];			
		}		
	} 	
}

#pragma mark Hot Key Execution.

-(void)buttonPress:(NSString *)prefix withButton:(NSString *)size
{
	[windowManager clickPointForXSize:[[themeController param:[prefix stringByAppendingString:@"OriginX"]] floatValue]
					andYSize:[[themeController param:[prefix stringByAppendingString:@"OriginY"]] floatValue]
				   andHeight:[[themeController param:[size stringByAppendingString:@"ButtonHeight"]] floatValue]
					andWidth:[[themeController param:[size stringByAppendingString:@"ButtonWidth"]] floatValue]];		
}

-(void)buttonPress:(NSString *)prefix withButton:(NSString *)size onTable:(AXUIElementRef)tableRef
{
	AXError err = AXUIElementPerformAction(tableRef, kAXRaiseAction);
	NSString *role,*title;
	AXUIElementCopyAttributeValue(tableRef, kAXRoleAttribute, (CFTypeRef *)&role);
	AXUIElementCopyAttributeValue(tableRef, kAXRoleAttribute, (CFTypeRef *)&title);
	
	[logger debug:@"Window info->  role: %@  title: %@",role,title];
	
	if (err == kAXErrorSuccess) {
		[windowManager clickPointForXSize:[[themeController param:[prefix stringByAppendingString:@"OriginX"]] floatValue]
								 andYSize:[[themeController param:[prefix stringByAppendingString:@"OriginY"]] floatValue]
								andHeight:[[themeController param:[size stringByAppendingString:@"ButtonHeight"]] floatValue]
								 andWidth:[[themeController param:[size stringByAppendingString:@"ButtonWidth"]] floatValue]];				
	} else{
		[logger warning:@"Could not raise the table to press the time bank button. Error: %d",err];
	}
}

-(void)buttonPressAllTables:(int)tag
{
	NSArray *tables = [windowManager getAllPokerTables];

	for (id table in tables) {
		AXUIElementRef tableRef = [table pointerValue];
		AXUIElementPerformAction(tableRef, kAXRaiseAction);
		
		NSString *prefix = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",tag]] objectAtIndex:0];
		NSString *size = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",tag]] objectAtIndex:1];
		[self buttonPress:prefix withButton:size];		
		[NSThread sleepForTimeInterval:0.3];
	}
}

-(void)autoBet
{
	NSString *prefix = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",3]] objectAtIndex:0];
	NSString *size = [[keyMap objectForKey:[NSString stringWithFormat:@"%d",3]] objectAtIndex:1];
	[self buttonPress:prefix withButton:size];			
}

-(float)getBetSize
{
	NSPoint clickPoint = [windowManager getClickPointForXSize:[[themeController param:@"betBoxOriginX"] floatValue]
										 andYSize:[[themeController param:@"betBoxOriginY"] floatValue]
										andHeight:[[themeController param:@"betBoxHeight"] floatValue]
										 andWidth:[[themeController param:@"betBoxWidth"] floatValue]];
	

	AXUIElementRef betBoxRef;
	
	AXError err = AXUIElementCopyElementAtPosition([lowLevel appRef],
									 clickPoint.x,
									 clickPoint.y,
									 &betBoxRef);
	
	switch(err) {
		case kAXErrorNoValue:
			[logger critical:@"CopyElementAtPosition reports that the bet box is not where we think it is! (kAXErrorNoValue)"];
			return -1;
		case kAXErrorIllegalArgument:
			[logger critical:@"CopyElementAtPosition reports that one of the arguments is illegal! (kAXErrorIllegalArgument)"];
			return -1;
		case kAXErrorInvalidUIElement:
			[logger critical:@"CopyElementAtPosition reports that the AXUIElementRef (appRef) is invalid! (kAXErrorInvalidUIElement)"];
			return -1;
		case kAXErrorCannotComplete:
			[logger critical:@"CopyElementAtPosition reports that the messaging API has failed! (kAXErrorCannotComplete)"];
			return -1;
		case kAXErrorNotImplemented:
			[logger critical:@"CopyElementAtPosition reports that the process does not fully support the accessibility API! (kAXErrorNotImplmented)"];
			return -1;
		default: 
			 break;
	}
	
	NSString *value;
	err = AXUIElementCopyAttributeValue(betBoxRef, kAXValueAttribute,(CFTypeRef *)&value);
	
	if (!value || err != kAXErrorSuccess) {
		switch(err) {
			case kAXErrorAttributeUnsupported:
				[logger critical:@"CopyAttributeValue reports that the specified AXUIElementref (betBoxRef) does not support the specified attribute (ValueAttribute)! (kAXErrorAttributeUnsupported)"];
				return -1;
			case kAXErrorNoValue:
				[logger critical:@"CopyAttributeValue reports that the bet box is not where we think it is! (kAXErrorNoValue)"];
				return -1;
			case kAXErrorIllegalArgument:
				[logger critical:@"CopyAttributeValue reports that one of the arguments is illegal! (kAXErrorIllegalArgument)"];
				return -1;
			case kAXErrorInvalidUIElement:
				[logger critical:@"CopyAttributeValue reports that the AXUIElementRef (betBoxRef) is invalid! (kAXErrorInvalidUIElement)"];
				return -1;
			case kAXErrorCannotComplete:
				[logger critical:@"CopyAttributeValue reports that the messaging API has failed! (kAXErrorCannotComplete)"];
				return -1;
			case kAXErrorNotImplemented:
				[logger critical:@"CopyAttributeValue reports that the process does not fully support the accessibility API! (kAXErrorNotImplmented)"];
				return -1;
			default: 
				break;
		}
		return -1;
	}
	[logger info:@"Bet size is: %f",[value floatValue]];
	return [value floatValue];
}

-(void)setBetSize:(float)amount
{
	NSPoint clickPoint = [windowManager getClickPointForXSize:[[themeController param:@"betBoxOriginX"] floatValue]
											andYSize:[[themeController param:@"betBoxOriginY"] floatValue]
										   andHeight:[[themeController param:@"betBoxHeight"] floatValue]
											andWidth:[[themeController param:@"betBoxWidth"] floatValue]];
	
	AXUIElementRef betBoxRef;
	
	AXUIElementCopyElementAtPosition([lowLevel appRef],
									 clickPoint.x,
									 clickPoint.y,
									 &betBoxRef);
	
	// Set up string to the value to bet, and then strip trailing zeros if the bet is an even amount.
	NSString *valueToSet = [NSString stringWithFormat:@"%.2f",amount];
	[logger info:@"Attempting to set value: %@", valueToSet];
	if ([[valueToSet substringFromIndex:[valueToSet length]-2] isEqual:@"00"]) {
		valueToSet = [valueToSet substringToIndex:[valueToSet length]-3];
		[logger info:@"String is now: %@",valueToSet];
	}
	
	[lowLevel clickAt:NSPointToCGPoint(clickPoint)];

	[lowLevel keyPress:124 repeated:10 withFlush:YES];
	[lowLevel keyPress:117 repeated:10 withFlush:YES];
	[lowLevel keyPress:51 repeated:10 withFlush:YES];	
	[lowLevel writeString:valueToSet];
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
			break;
		case 1:
			betIncrement = amountToChange * [[gameParams objectAtIndex:HKSmallBlind] floatValue];
			break;
	}
	return betIncrement;
}

-(void)incrementBetSize:(long)delta
{
	float betSize = [self getBetSize];
	[logger debug:@"betSize here is: %f",betSize];
	betSize += ([self betIncrement] * (float)delta);
	[logger debug:@"betSize after is: %f",betSize];	
	[self setBetSize:betSize];
}

-(void)decrementBetSize:(long)delta
{
	float betSize = [self getBetSize];
	betSize -= [self betIncrement] * (float)delta;
	[self setBetSize:betSize];
}

-(void)potBet:(int)tag
{
	[logger info:@"Pot betting initiated."];

	float potSize = [screenScraper getPotSize];
	[logger info:@"Pot size is %f",potSize];
	
	float potBetAmt = [[potBetAmounts objectForKey:[NSNumber numberWithInt:tag]] floatValue] / 100;
	float betSize = potSize * potBetAmt;
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"roundingBoolKey"]) {
		NSArray *gameParameters = [windowManager getGameParameters];		
		float blindSize;
		if (roundingType == 1)
			blindSize = [[gameParameters objectAtIndex:HKSmallBlind] floatValue];
		else 
			blindSize = [[gameParameters objectAtIndex:HKBigBlind] floatValue];

		float blindAdj = blindSize * roundingAmount;
		if (fmod(betSize,blindAdj) != 0)
			betSize = ((int)(betSize / blindAdj) * blindAdj) + blindAdj;			
	} 

	[self setBetSize:betSize];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"autoBetRoundingKey"]) 
		[self autoBet];
}

-(void)pfr:(int)tag
{		
	NSArray *gameParameters = [windowManager getGameParameters];
	float blindSize = [[gameParameters objectAtIndex:HKBigBlind] floatValue];	
	
	[self setBetSize:[[pfrAmounts objectForKey:[NSNumber numberWithInt:tag]] floatValue]*blindSize];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"autoPFRBetKey"] == YES)
		[self autoBet];
}

-(void)allIn
{
	[self setBetSize:9999999];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"autoBetAllInKey"] == YES) 
		[self autoBet];
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
	[logger debug:@"In the debugging hotkey."];
	AXUIElementRef window = [lowLevel getMainWindow];
	
	int windowID = [lowLevel getWindowIDForTable:window];
	[logger debug:@"Window ID for main table is: %d",windowID];
	
	
	
}

-(void)voiceCommandsChangedState
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"voiceCommandsEnabledKey"]) {
		[logger info:@"Activating speech commands."];
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
		[logger info:@"Deactivating voice commands."];
		[speechRecognizer stopListening];
		speechRecognizer = nil;
	}
}

- (void)speechRecognizer:(NSSpeechRecognizer *)sender didRecognizeCommand:(id)command {
	for (id key in speechCommands) {
		if ([[speechCommands objectForKey:key] isEqualToString:command]) {
			[logger info:@"Speech command recognized!  Command was: %@",key];

			for (id field in keyMap) {
				if ([[[keyMap objectForKey:field] objectAtIndex:0] isEqualToString:key]) {
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
			case 23:
				[self pfr:tag];
				break;
			case 24:
				[self pfr:tag];
				break;
			case 25:
				[self pfr:tag];
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
		[logger warning:@"I was asked to simulate a hotkey I don't know: %d",tag];
	}
}

@end


pascal OSStatus hotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
							  void *userData)
{
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
	
	NSLog(@"In hot key handler, got tag: %d",l);
	
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
			case 23:
				[(id)userData pfr:l];
				break;
			case 24:
				[(id)userData pfr:l];
				break;
			case 25:
				[(id)userData pfr:l];
				break;				
			case 99:
				[(id)userData debugHK];
				break;
			default:
				prefix = [[[(id)userData keyMap] objectForKey:[NSString stringWithFormat:@"%d",l]] objectAtIndex:0];
				size = [[[(id)userData keyMap] objectForKey:[NSString stringWithFormat:@"%d",l]] objectAtIndex:1];
				NSLog(@"Prefix: %@  Size: %@",prefix,size);
				[(id)userData buttonPress:prefix withButton:size];
				break;
		}
		
		
	} else {
		retCode = eventNotHandledErr;
	}
	retCode = noErr;
	
	// Flush the events from the hotkey queue.
	FlushEventQueue(GetMainEventQueue());
	FlushEventQueue(GetCurrentEventQueue());

	return retCode;
}

pascal OSStatus mouseEventHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
							  void *userData)
{
/*	if ([[[PrefsWindowController sharedPrefsWindowController] scrollWheelCheckBox] state] == NSOnState) {
		if ([wm pokerWindowIsActive] == YES) {
			[NSThread sleepForTimeInterval:0.5];
			long delta;
			GetEventParameter(theEvent, kEventParamMouseWheelDelta, typeSInt32, NULL, sizeof(long), NULL, &delta);
			NSLog(@"Got delta: %d",delta);
			if (delta > 0) {
				NSLog(@"Calling increment.");
				[(id)userData incrementBetSize:1];
			} else if (delta < 0) {
				NSLog(@"Calling decrement.");				
				[(id)userData decrementBetSize:1];
			}
			FlushEventQueue(GetMainEventQueue());
			FlushEventQueue(GetCurrentEventQueue());			
			[NSThread sleepForTimeInterval:0.5];
		} else {
			CallNextEventHandler(nextHandler, theEvent);
			FlushEventQueue(GetMainEventQueue());
			FlushEventQueue(GetCurrentEventQueue());			
			return eventNotHandledErr;
		}
	}
	return noErr;*/
	return noErr;
}
