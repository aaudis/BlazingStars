//
//  HKWindowManager.m
//  PokerHK
//
//  Created by Steven Hamblin on 09/06/09.
//  Copyright 2009 Steven Hamblin. All rights reserved.
//

#import "HKWindowManager.h"
#import "HKTransparentBorderedView.h"
#import "HKTransparentWindow.h"
#import "HKDefines.h"
#import "PokerStarsInfo.h"

void axObserverCallback(AXObserverRef observer, 
						AXUIElementRef elementRef, 
						CFStringRef notification, 
						void *refcon);	

// I don't like doing this this way, but the refcon data crashes when I try to send a msg to it.
HKWindowManager *wm = NULL;

@implementation HKWindowManager

@synthesize activated;

#pragma mark Initialization

+(void)initialize {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
	[appDefaults setObject:[NSNumber numberWithFloat:1.0] forKey:@"tournamentCloseLobbyDelayKey"];
	[appDefaults setObject:[NSNumber numberWithBool:YES] forKey:@"hsWarningKey"];
    [defaults registerDefaults:appDefaults];
}

-(id)init {
	if ((self = [super init])) {		
		logger = [SOLogger loggerForFacility:@"com.fullyfunctionalsoftware.blazingstars" options:ASL_OPT_STDERR];
		[logger info:@"Initializing windowManager."];
	}
	return self;
}

-(void)awakeFromNib
{
	wm = self;
	
	AXError err = AXObserverCreate([lowLevel pokerstarsPID], axObserverCallback, &observer);
	
	if (err != kAXErrorSuccess) {
		[logger critical:@"Creating observer for window notifications in windowManager failed.  Exiting!"];
		[[NSApplication sharedApplication] terminate: nil];			
	}
	
	AXUIElementRef appRef = [lowLevel appRef];
	AXObserverAddNotification(observer, appRef, kAXWindowCreatedNotification, (void *)self);
	AXObserverAddNotification(observer, appRef, kAXWindowResizedNotification, (void *)self);
	AXObserverAddNotification(observer, appRef, kAXWindowMovedNotification, (void *)self);
	AXObserverAddNotification(observer, appRef, kAXFocusedWindowChangedNotification, (void *)self);		
	AXObserverAddNotification(observer, appRef, kAXApplicationActivatedNotification, (void *)self);	
	AXObserverAddNotification(observer, appRef, kAXApplicationDeactivatedNotification, (void *)self);	

	CFRunLoopAddSource ([[NSRunLoop currentRunLoop] getCFRunLoop], AXObserverGetRunLoopSource(observer), kCFRunLoopDefaultMode);

	// Set up window dictionary
	windowDict = [[NSMutableDictionary alloc] init];
	[self updateWindowDict];
}

#pragma mark Window overlay

-(void)debugWindow:(NSRect)windowRect
{
	NSWindow *window = [[NSWindow alloc] initWithContentRect:FlippedScreenBounds(windowRect) styleMask:NSBorderlessWindowMask backing:NSBackingStoreNonretained defer:YES];
	[window setOpaque:NO];
	[window setAlphaValue:0.20];
	[window setBackgroundColor:[NSColor yellowColor]];
	[window setLevel:NSStatusWindowLevel];
	[window setReleasedWhenClosed:YES];
	[window orderFront:nil];
	
	[NSThread sleepForTimeInterval:0.5];
	[window close];	
}

-(void)drawWindowFrame
{
	// Close old window first, or they'll clutter the screen endlessly.
	[frameWindow close];
	AXUIElementRef mw = [lowLevel getMainWindow];
	NSRect frameRect = [NSWindow contentRectForFrameRect:FlippedScreenBounds([lowLevel getWindowBounds:mw]) styleMask:NSTitledWindowMask];	
	frameWindow = [[HKTransparentWindow alloc] initWithContentRect:frameRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreNonretained defer:YES];
	[frameWindow orderFront:nil];	
}

#pragma mark Window Interaction

-(void)clickPointForXSize:(float)xsize andYSize:(float)ysize andHeight:(float)height andWidth:(float)width
{
	AXUIElementRef mainWindow = [lowLevel getMainWindow];
	NSRect windowRect = [lowLevel getWindowBounds:mainWindow];
	
	windowRect.origin.x = windowRect.size.width * xsize + windowRect.origin.x;
	windowRect.origin.y = windowRect.size.height * ysize + windowRect.origin.y;	
	windowRect.size.width = windowRect.size.width * width;
	windowRect.size.height = windowRect.size.height * height;		
	
	CGPoint eventCenter = {
		.x = (windowRect.origin.x + (windowRect.size.width / 2)),
		.y = (windowRect.origin.y + (windowRect.size.height / 2))
	};

	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"debugOverlayWindowKey"]) 
		[self debugWindow:windowRect];

	[logger info:@"\nAttempting mouse click at: x=%g y=%g.",eventCenter.x,eventCenter.y];
	[lowLevel clickAt:eventCenter];
}

-(NSPoint)getClickPointForXSize:(float)xsize andYSize:(float)ysize andHeight:(float)height andWidth:(float)width
{
	
	AXUIElementRef mainWindow = [lowLevel getMainWindow];
	
	NSRect windowRect = [lowLevel getWindowBounds:mainWindow];
	
	windowRect.origin.x = windowRect.size.width * xsize + windowRect.origin.x;
	windowRect.origin.y = windowRect.size.height * ysize + windowRect.origin.y;
	
	windowRect.size.width = windowRect.size.width * width;
	windowRect.size.height = windowRect.size.height * height;		
	
	CGPoint eventCenter = {
		.x = (windowRect.origin.x + (windowRect.size.width / 2)),
		.y = (windowRect.origin.y + (windowRect.size.height / 2))
	};
	
	[logger info:@"In getClickPointForXSize:andYSize:andHeight:andWidth:  x=%f,y=%f",eventCenter.x,eventCenter.y];
	return NSPointFromCGPoint(eventCenter);
}

#pragma mark Window dictionary

-(void)updateWindowDict
{
	[windowDict removeAllObjects];
	
	NSString *name = nil; 
	
	for (id child in [lowLevel getChildrenFrom:[lowLevel appRef]]) {
		AXUIElementCopyAttributeValue((AXUIElementRef)child,kAXTitleAttribute, (CFTypeRef *)&name);
		
		if ([self windowIsTable:(AXUIElementRef) child] == HKHoldemCashTable || [self windowIsTable:(AXUIElementRef)child] == HKTournamentTable) {
			id *size; CGSize sizeVal;			
			AXUIElementCopyAttributeValue((AXUIElementRef)child,kAXSizeAttribute,(CFTypeRef *)&size);
			if (!AXValueGetValue((AXValueRef) size, kAXValueCGSizeType, &sizeVal)) {
				[logger warning:@"Could not get size from window element in updateWindowDict"];
				return;
			}
			
			// Let's see if we can find the textArea.
			AXUIElementRef chatRef = [self findChatBoxForWindow:(AXUIElementRef) child];
			
			
			[windowDict setObject:[NSArray arrayWithObjects:NSStringFromSize(NSSizeFromCGSize(sizeVal)),chatRef,nil] forKey:name];			
			AXObserverAddNotification(observer, (AXUIElementRef)child, kAXUIElementDestroyedNotification, (void *)self);			
			AXObserverAddNotification(observer, chatRef, kAXValueChangedNotification, (void *)self);
		}
	}
	[logger info:@"windowDict: %@",windowDict];
	
}

-(void)addWindowToWindowDict:(AXUIElementRef)windowRef
{
	NSString *title;

	AXError err = AXUIElementCopyAttributeValue(windowRef,kAXTitleAttribute,(CFTypeRef*)&title);		
	
	if (err != kAXErrorSuccess) {
		[logger warning:@"Copy attribute failed in addWindowToWindowDict."];
		return;
	}
		
	id *size; CGSize sizeVal;			
	AXUIElementCopyAttributeValue(windowRef,kAXSizeAttribute,(CFTypeRef *)&size);
	if (!AXValueGetValue((AXValueRef) size, kAXValueCGSizeType, &sizeVal)) {
		[logger warning:@"Could not get size from window element in addWindowToWindowDict"];
		return;		
	}
	
	AXUIElementRef chatRef = [self findChatBoxForWindow:(AXUIElementRef) windowRef];	
	
	[windowDict setObject:[NSArray arrayWithObjects:NSStringFromSize(NSSizeFromCGSize(sizeVal)),chatRef,nil] forKey:title];		
	AXObserverAddNotification(observer,windowRef, kAXUIElementDestroyedNotification, (void *)self);	
	AXObserverAddNotification(observer, chatRef, kAXValueChangedNotification, (void *)self);	
	[logger info:@"windowDict is now: %@",windowDict];
}

#pragma mark WindowDidOpen helpers.

-(AXUIElementRef)findChatBoxForWindow:(AXUIElementRef)windowRef
{
	AXUIElementRef chatRef;
	NSString *role;
	for (id child in [lowLevel getChildrenFrom:windowRef]) {
		AXUIElementCopyAttributeValue((AXUIElementRef)child, kAXRoleAttribute,(CFTypeRef *)&role);
		if ([role isEqualToString:@"AXScrollArea"]) {
			[logger debug:@"Found scroll area!"];
			for (id subChild in [lowLevel getChildrenFrom:(AXUIElementRef)child]) {
				AXUIElementCopyAttributeValue((AXUIElementRef)subChild, kAXRoleAttribute,(CFTypeRef *)&role);						
				if ([role isEqualToString:@"AXTextField"]) {
					[logger debug:@"Found dealer chat!"];
					NSString *chat;
					AXUIElementCopyAttributeValue((AXUIElementRef)subChild, kAXValueAttribute, (CFTypeRef *)&chat);
					[logger debug:@"Chat area text:\n%@",chat];
					chatRef = (AXUIElementRef)subChild;
					break;
				}
			}
		}
	}	
	return chatRef;
}

-(double)findTournamentNum:(NSString *)title inLobby:(BOOL)lobbyBool
{
	NSRange tourneyRange,endRange,tnumRange;
	tourneyRange = [title rangeOfString:@"Tournament"];
	
	if (lobbyBool) {
		endRange = [title rangeOfString:@"Lobby"];		
	} else {
		endRange = [title rangeOfString:@"Table"];
	}
	
	if ((tourneyRange.location == NSNotFound) || (endRange.location == NSNotFound)) {
		return 0;
	}
	
	float start = tourneyRange.location + tourneyRange.length;  float len = endRange.location-start;
	tnumRange = NSMakeRange(start,len);
	NSString *tnum = [title substringWithRange:tnumRange];
	return [tnum doubleValue];
}


-(AXUIElementRef)findLobbyForTournament:(double)tnum
{	
	NSString *childTitle;
	AXUIElementRef lobby = nil;
	for (id child in [lowLevel getChildrenFrom:[lowLevel appRef]]) {
		// Check to see if this is the lobby.
		AXUIElementCopyAttributeValue((AXUIElementRef)child,kAXTitleAttribute,(CFTypeRef*)&childTitle);

		if ([childTitle rangeOfString:@"Tournament"].location != NSNotFound && [childTitle rangeOfString:@"Lobby"].location != NSNotFound) {
			if ([self findTournamentNum:childTitle inLobby:YES] == tnum) {
				lobby = (AXUIElementRef)child;
			}
		}						
	}
	return lobby;
}



-(void)closeLobbyForTournament:(AXUIElementRef)elementRef
{
	NSString *title;
	
	AXUIElementCopyAttributeValue(elementRef,kAXTitleAttribute,(CFTypeRef*)&title);		
	
	if ([title rangeOfString:@"Tournament"].location != NSNotFound && [title rangeOfString:@"Table"].location != NSNotFound) {	
		double tnum = [self findTournamentNum:title inLobby:NO];
		
		AXUIElementRef lobby = [self findLobbyForTournament:tnum];
		if (lobby == nil) {
			[logger warning:@"Could not find lobby, bailing out!"];
			return;
		}
		
		// Raise the lobby and close it.
		AXError err = AXUIElementPerformAction(lobby, kAXRaiseAction);
		if (err != kAXErrorSuccess) {
			[logger warning:@"Raising the lobby failed! Error: %d",err];
			return;
		}
		// Cycle through the children, find the close button, and close the window.
		NSString *role,*subrole; AXError roleErr,subroleErr;
		
		for (id child in [lowLevel getChildrenFrom:lobby]) {
			roleErr = AXUIElementCopyAttributeValue((AXUIElementRef)child,kAXRoleAttribute,(CFTypeRef*)&role);
			if (roleErr == kAXErrorSuccess) {
				subroleErr = AXUIElementCopyAttributeValue((AXUIElementRef)child,kAXSubroleAttribute,(CFTypeRef*)&subrole);
				if (subroleErr == kAXErrorSuccess) {
					if ([role rangeOfString:@"AXButton"].location != NSNotFound && [subrole rangeOfString:@"AXCloseButton"].location != NSNotFound) {
						AXUIElementPerformAction((AXUIElementRef)child, kAXPressAction);
						break;
					}
				}
			}
		}
		// Finally, clean up the window dict.  
		[self windowDidClose:lobby];
	}
	
}


-(void)closeTournamentRegistrationPopup:(AXUIElementRef)popupRef
{			
	[logger info:@"Table registration popup detected!  Trying to close."];
	
	NSString *name;
	AXUIElementCopyAttributeValue(popupRef, kAXTitleAttribute, (CFTypeRef *)&name);
	
	if ([name isEqual:@"Tournament Registration"]) {
		AXUIElementRef OKButton = NULL;
		for (id child in [lowLevel getChildrenFrom:popupRef]) {
			AXUIElementCopyAttributeValue((AXUIElementRef) child,kAXRoleAttribute, (CFTypeRef *)&name);
			if ([name isEqual:@"AXRadioButton"]) {
				AXUIElementPerformAction((AXUIElementRef)child,kAXPressAction);
			} else if ([name isEqual:@"AXCheckBox"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"registerForIdenticalKey"]) {
				AXUIElementPerformAction((AXUIElementRef)child,kAXPressAction);
			} else if ([name isEqual:@"AXButton"]) {
				NSString *buttonName;
				AXUIElementCopyAttributeValue((AXUIElementRef) child,kAXTitleAttribute,(CFTypeRef *)&buttonName);
				
				if ([buttonName isEqual:@"OK"] || [buttonName isEqual:@"Check"]) {
					OKButton = (AXUIElementRef) child;
				}
			}
			if ([name isEqual:@"(null)"]) {
				break;
			}
		}
		// Necessary because the window controls don't seem to populate fast enough - the button won't get pressed.
		[NSThread sleepForTimeInterval:0.3];
		AXUIElementPerformAction(OKButton, kAXPressAction);
	}
}

-(AXUIElementRef)findOKButtonInPopupWindow:(AXUIElementRef)windowRef
{
	NSString *role;
	AXUIElementRef OKButton = nil;
	
	for (id child in [lowLevel getChildrenFrom:windowRef]) {
		AXUIElementCopyAttributeValue((AXUIElementRef) child,kAXRoleAttribute, (CFTypeRef *)&role);
		
		if ([role isEqual:@"AXButton"]) {
			NSString *buttonName;
			AXUIElementCopyAttributeValue((AXUIElementRef) child,kAXTitleAttribute,(CFTypeRef *)&buttonName);
			[logger debug:@"In findOKButtonInPopupWindow, button name is: %@",buttonName];
			if ([buttonName isEqual:@"OK"] || [buttonName isEqual:@"Check"]) {
				OKButton = (AXUIElementRef) child;
			}
		}
	}
	return OKButton;
}

-(void)closeTablePopupWindows
{
	NSMutableArray *windowsToClose = [[NSMutableArray alloc] init];
	
	[logger info:@"Table popup detected! Trying to close."];
	
	// Build list of Table popups.
	for (id child in [lowLevel getChildrenFrom:[lowLevel appRef]]) {
		if ([self windowIsTableAtOpening:(AXUIElementRef)child] == HKTablePopup) {
			[windowsToClose addObject:child];
		}
	}
	
	[logger debug:@"Windows to close: %@",windowsToClose];
	
	// Go through each table popup, try to press the close button.  This is *extremely* inelegant, but I'm having trouble coming up
	// with another way to handle this right now.
	for (id element in windowsToClose) {
		AXUIElementRef OKButton = [self findOKButtonInPopupWindow:(AXUIElementRef)element];
		[NSThread sleepForTimeInterval:0.2];
		AXUIElementPerformAction(OKButton, kAXPressAction);
	}	
}

#pragma mark Table identification / information.

// Helper function:  is this window a poker *table* as opposed to lobby or other window?  Pass in an elementRef to get the answer from the title.
-(int)windowIsTable:(AXUIElementRef)windowRef
{
	NSString *title;
	AXUIElementCopyAttributeValue(windowRef, kAXTitleAttribute, (CFTypeRef *)&title);	
	
	if ([title length] > 0) {
		// Poker tables have two hyphens in their name.   Strange trick, but it works (suggested by Steve.McLeod).
		if ([[title componentsSeparatedByString:@"-"] count] > 2) {
			if ([title rangeOfString:@"Tournament"].location != NSNotFound) {
				[logger info:@"Found tournament table."];
				return HKTournamentTable;
			} else if ([title rangeOfString:@"Hold'em"].location != NSNotFound) {
				[logger info:@"Found hold'em table."];				
				return HKHoldemCashTable;
			} else if ([title rangeOfString:@"Omaha"].location != NSNotFound) {
				[logger info:@"Found omaha table."];				
				return HKPLOTable;
			}
		} else {
			if ([title rangeOfString:@"Tournament"].location != NSNotFound && [title rangeOfString:@"Lobby"].location != NSNotFound)
				return HKTournamentLobby;
			if ([title rangeOfString:@"Tournament Registration"].location != NSNotFound)
				return HKTournamentLobby;
		}
	} else {
		return HKNotTable;
	}
	return HKNotTable;
}

-(int)windowIsTableAtOpening:(AXUIElementRef)windowRef
{
	[logger info:@"Attempting to identify window at opening."];
	
	NSString *title;
	AXUIElementCopyAttributeValue(windowRef, kAXTitleAttribute, (CFTypeRef *)&title);	
	
	if ([title length] > 0) {
		// Sometimes, the table opens faster and the full title is available at the beginning.  If there's two hyphens,
		// we know it's a table of some kind.
		if ([[title componentsSeparatedByString:@"-"] count] > 2) {
			[logger info:@"Title %@ identified as HKGeneralTable.",title];
			return HKGeneralTable;
		}
		if ([title isEqualToString:@"Table"]){
			[logger info:@"Title %@ identified as HKGeneralTable.",title];
			return HKGeneralTable;
		} else if ([title hasPrefix:@"Tournament #"]) {
			[logger info:@"Title %@ identified as HKTournamentLobby.",title];
			return HKTournamentLobby;
		} else if ([title hasPrefix:@"Tournament"] && [title rangeOfString:@"Lobby"].location != NSNotFound) {
			[logger info:@"Title %@ identified as HKTournamentLobby.",title];
			return HKTournamentLobby;				
		} else if ([title isEqualToString:@"Tournament Registration"]) {
			[logger info:@"Title %@ identified as HKTournamentRegistration",title];
			return HKTournamentRegistration;
		} else if (([title rangeOfString:@"Table"].location != NSNotFound && [title length] > 5) ||
				   [title isEqualToString:@"PokerStars"]){
			[logger info:@"Title %@ identified as HKTablePopup",title];
			return HKTablePopup;
		} else {
			[logger info:@"title %@ identified as HKNotTable",title];
			return HKNotTable;
		}				
	} else {
		return HKNotTable;
	}
	
}

-(BOOL)pokerWindowIsActive
{
	int retVal = [self windowIsTable:[lowLevel getMainWindow]];
	if (retVal == HKTournamentTable || retVal == HKHoldemCashTable || retVal == HKPLOTable) {
		return YES;
	} else {
		return NO;
	}
}

-(NSArray *)getAllPokerTables
{
	NSMutableArray *pokerTables = [[NSMutableArray alloc] init];

	for (id child in [lowLevel getChildrenFrom:[lowLevel appRef]]) {
		int tableType = [self windowIsTable:(AXUIElementRef)child];
		if (tableType == HKHoldemCashTable || tableType == HKTournamentTable || tableType == HKPLOTable) {
			[pokerTables addObject:[NSValue valueWithPointer:child]];
		}
	}	
	return pokerTables;
}

#pragma mark Window / table parameters.

-(NSRect)getPotBounds:(AXUIElementRef)windowRef
{
	NSRect windowRect = [lowLevel getWindowBounds:windowRef];
	
	NSRect boundBox = NSMakeRect([[themeController param:@"potBoxOriginX"] floatValue],
								 [[themeController param:@"potBoxOriginY"] floatValue],
								 [[themeController param:@"potBoxWidth"] floatValue],
								 [[themeController param:@"potBoxHeight"] floatValue]);
	
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform scaleXBy:(windowRect.size.width / [[themeController param:@"defaultWindowWidth"] floatValue]) 
					yBy: ((windowRect.size.height) / [[themeController param:@"defaultWindowHeight"] floatValue])];
	[transform concat];
	
	boundBox.size = [transform transformSize:boundBox.size];
	boundBox.origin = [transform transformPoint:boundBox.origin];

	NSSize tempSize = windowRect.size;
	
	// Have to set the origin by hand.  
	boundBox.origin.y = [[themeController param:@"intercept"] floatValue] + ([[themeController param:@"coefficient"] floatValue] * tempSize.height) + windowRect.origin.y;
	boundBox.origin.x += windowRect.origin.x;
	return boundBox;
}

-(NSArray *)getGameParameters
{
	[logger info:@"Trying to get game parameters."];
	
	AXUIElementRef mainWindow = [lowLevel getMainWindow];
	
	if (!mainWindow)
		return nil;
	
	NSString *title; 
	AXUIElementCopyAttributeValue(mainWindow,kAXTitleAttribute,(CFTypeRef *)&title);
	
	NSString *smallBlind, *bigBlind, *gameType;
	
	NSMutableCharacterSet *money = [[NSMutableCharacterSet alloc] init];
	[money formUnionWithCharacterSet:[NSCharacterSet letterCharacterSet]];
	[money formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
	[money formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@"€$-'"]];
	
	if ([title rangeOfString:@"Tournament"].location == NSNotFound) {		
		smallBlind = [[title componentsSeparatedByString:@"/"] objectAtIndex:0];
		bigBlind = [[title componentsSeparatedByString:@"/"] objectAtIndex:1];
		
		smallBlind = [smallBlind stringByTrimmingCharactersInSet:money];
		bigBlind = [bigBlind stringByTrimmingCharactersInSet:money];
		[logger info:@"Small blind: %@  Big blind: %@",smallBlind,bigBlind];	
		
		gameType = [[[title componentsSeparatedByString:@"-"] objectAtIndex:2] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		[logger info:@"Game type: %@", gameType];
		
	} else {
		NSArray *temp = [[[title componentsSeparatedByString:@"/"] objectAtIndex:0] componentsSeparatedByString:@" "];
		smallBlind = [temp objectAtIndex:[temp count]-1];
		temp = [[[title componentsSeparatedByString:@"/"] objectAtIndex:1] componentsSeparatedByString:@" "];
		bigBlind = [temp objectAtIndex:0];
		
		smallBlind = [smallBlind stringByTrimmingCharactersInSet:money];
		bigBlind = [bigBlind stringByTrimmingCharactersInSet:money];
		[logger info:@"Small blind: %@  Big blind: %@",smallBlind,bigBlind];	
		
		gameType = @"Tournament";
		[logger info:@"Game type: %@", gameType];
	}
	
	return [NSArray arrayWithObjects:[NSNumber numberWithFloat:[smallBlind floatValue]],
			[NSNumber numberWithFloat:[bigBlind floatValue]],gameType,nil];
}


#pragma mark Notification handlers.

-(void)windowDidOpen:(AXUIElementRef)elementRef
{	
	NSUserDefaults *sdc = [NSUserDefaults standardUserDefaults];
	if ([sdc floatForKey:@"tournamentCloseLobbyDelayKey"]) {
		[NSThread sleepForTimeInterval:[sdc floatForKey:@"tournamentCloseLobbyDelayKey"]];
	} else {
		[NSThread sleepForTimeInterval:0.5];
	}
	
	if ([self windowIsTableAtOpening:elementRef] == HKGeneralTable) {
		[self addWindowToWindowDict:elementRef];

		if ([sdc boolForKey:@"tournamentCloseLobbyKey"]) {
			[self closeLobbyForTournament:elementRef];
		}
		
	} else if ([self windowIsTableAtOpening:elementRef] == HKTournamentRegistration) {
		if ([sdc boolForKey:@"tournamentRegistrationPopupKey"]) {
			[self closeTournamentRegistrationPopup:elementRef];
		}
	} else if ([self windowIsTableAtOpening:elementRef] == HKTablePopup) {
		[self closeTablePopupWindows];
	}		
	
	// If we opened a window and it was a poker window, draw the frame if we have to.
	[self windowFocusDidChange];
	return;
}

-(void)windowDidResize:(AXUIElementRef)elementRef
{
	[self windowFocusDidChange];
	[self updateWindowDict];
}


-(void)windowDidClose:(AXUIElementRef)elementRef
{
	[self updateWindowDict];
}

-(void)windowFocusDidChange
{
	if ([self pokerWindowIsActive] && [self activated] == YES && [[NSUserDefaults standardUserDefaults] boolForKey:@"windowFrameKey"]) {
		[self drawWindowFrame];
	} else {
		[frameWindow close];
	}
}

-(void)windowDidMove
{
	// For now, this is effectively the same as the window focus procedure, so I'll just call that method.
	[self windowFocusDidChange];
}

-(void)applicationDidActivate
{
	if ([self activated] == NO) {
		[self setActivated:YES];
		[dispatchController activateHotKeys];		
	}
	
	// Window focus changed notification gets called before the applicationDidActivate notification (why?), so we have to force the overlay
	// to redraw.
	[self windowFocusDidChange];
}

-(void)applicationDidDeactivate
{
	if ([self activated] == YES) {
		[self setActivated:NO];
		[dispatchController deactivateHotKeys];		
	} 
}

-(void)chatChanged:(AXUIElementRef)chatRef
{
	NSString *text;

	AXUIElementCopyAttributeValue(chatRef, kAXValueAttribute, (CFTypeRef *)&text);
	text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSArray* lines = [text componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];

	NSString *lastLine = [lines lastObject];

	//[logger debug:@"Last line: %@",lastLine];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"autoTimeBankKey"]) {
		if ([lastLine rangeOfString:[PokerStarsInfo determineUserName]].location != NSNotFound &&
			[lastLine rangeOfString:@"seconds to act"].location != NSNotFound) {
			[logger debug:@"Last line: %@",lastLine];			
			[logger debug:@"Time bank was activated!!"];
			
			AXUIElementRef scrollRef,tableRef;
			AXUIElementCopyAttributeValue(chatRef, kAXParentAttribute, (CFTypeRef *)&scrollRef);
			AXUIElementCopyAttributeValue(scrollRef, kAXParentAttribute, (CFTypeRef *)&tableRef);		
			[dispatchController buttonPress:@"timeBank" withButton:@"big" onTable:tableRef];			
		}		
	}
	
}

		 
@end


void axObserverCallback(AXObserverRef observer, 
                               AXUIElementRef elementRef, 
                               CFStringRef notification, 
                               void *refcon) 
{
	if (CFStringCompare(notification,kAXWindowCreatedNotification,0) == 0) {
		[wm windowDidOpen:elementRef];
	} else if (CFStringCompare(notification,kAXWindowResizedNotification,0) == 0) {
		[wm windowDidResize:elementRef];
	} else if (CFStringCompare(notification,kAXApplicationActivatedNotification,0) == 0) {
		// For some reason, this and the next notification get called multiple times.  
		[wm applicationDidActivate];
	} else if (CFStringCompare(notification,kAXApplicationDeactivatedNotification,0) == 0) {
		[wm applicationDidDeactivate];
	} else if (CFStringCompare(notification,kAXUIElementDestroyedNotification,0) == 0) {
		[wm windowDidClose:elementRef];
	} else if (CFStringCompare(notification,kAXFocusedWindowChangedNotification,0) == 0) {
		[wm windowFocusDidChange];
	} else if (CFStringCompare(notification,kAXWindowMovedNotification,0) == 0) {
		[wm windowDidMove];
	} else if (CFStringCompare(notification, kAXValueChangedNotification, 0) == 0) {
		[wm chatChanged:elementRef];
	}
}

