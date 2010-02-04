/*
	DSClickableURLTextField
	
	Copyright (c) 2006 - 2007 Night Productions, by Darkshadow. All Rights Reserved.
	http://www.nightproductions.net/developer.htm
	darkshadow@nightproductions.net
	
	May be used freely, but keep my name/copyright in the header.
	
	There is NO warranty of any kind, express or implied; use at your own risk.
	Responsibility for damages (if any) to anyone resulting from the use of this
	code rests entirely with the user.
	
	------------------------------------
	
	* August 25, 2006 - initial release
	* August 30, 2006
		• Fixed a bug where cursor rects would be enabled even if the
		  textfield wasn't visible.  i.e. it's in a scrollview, but the
		  textfield isn't scrolled to where it's visible.
		• Fixed an issue where mouseUp wouldn't be called and so clicking
		  on the URL would have no effect when the textfield is a subview
		  of a splitview (and maybe some other certain views).  I did this
		  by NOT calling super in -mouseDown:.  Since the textfield is
		  non-editable and non-selectable, I don't believe this will cause
		  any problems.
		• Fixed the fact that it was using the textfield's bounds rather than
		  the cell's bounds to calculate rects.
	* May 25, 2007
		Contributed by Jens Miltner:
			• Fixed a problem with the text storage and the text field's
			  attributed string value having different lengths, causing
			  range exceptions.
			• Added a delegate method allowing custom handling of URLs.
			• Tracks initially clicked URL at -mouseDown: to avoid situations
			  where dragging would end up in a different URL at -mouseUp:, opening
			  that URL. This includes situations where the user clicks on an empty
			  area of the text field, drags the mouse, and ends up on top of a
			  link, which would then erroneously open that link.
			• Fixed to allow string links to work as well as URL links.
		Changes by Darkshadow:
			• Overrode -initWithCoder:, -initWithFrame:, and -awakeFromNib to
			  explicitly set the text field to be non-editable and
			  non-selectable.  Now you don't need to remember to set this up,
			  and the class will work correctly regardless.
			• Added in the ability for the user to copy URLs to the clipboard.
			  Note that this is off by default.
			• Some code clean up.
*/

#import "DSClickableURLTextField.h"

@implementation DSClickableURLTextField

#pragma mark -
#pragma mark Init / Dealloc
#pragma mark -

/* Set the text field to be non-editable and
	non-selectable. */
- (id)initWithCoder:(NSCoder *)coder
{
	if ( (self = [super initWithCoder:coder]) ) {
		[self setEditable:NO];
		[self setSelectable:NO];
		canCopyURLs = NO;
		canDragURLs = YES;
		displayToolTips = YES;
	}
	
	return self;
}

/* Set the text field to be non-editable and
	non-selectable. */
- (id)initWithFrame:(NSRect)frameRect
{
	if ( (self = [super initWithFrame:frameRect]) ) {
		[self setEditable:NO];
		[self setSelectable:NO];
		canCopyURLs = NO;
		canDragURLs = YES;
		displayToolTips = YES;
	}
	
	return self;
}

- (void)dealloc
{
	[clickedURL release];
	[URLStorage release];
	[dragTextBackgroundColor release];
	[super dealloc];
}

#pragma mark -
#pragma mark Subclassed methods
#pragma mark -

/* Enforces that the text field be non-editable and
	non-selectable. Probably not needed, but I always
	like to be cautious.
*/
- (void)awakeFromNib
{
	//[super awakeFromNib];
	[self setEditable:NO];
	[self setSelectable:NO];
}

- (void)setAttributedStringValue:(NSAttributedString *)aStr
{
	[self setObjectValue:aStr];
}

- (void)setStringValue:(NSString *)aStr
{
	[self setObjectValue:aStr];
}

- (void)setObjectValue:(id)anObj
{
	if ( URLStorage == nil ) {
		NSRect cellBounds = [[self cell] drawingRectForBounds:[self bounds]];
		NSSize containerSize = cellBounds.size;
		URLContainer = [[[NSTextContainer alloc] initWithContainerSize:containerSize] autorelease];
		URLManager = [[[NSLayoutManager alloc] init] autorelease];
		URLStorage = [[NSTextStorage alloc] init];
		
		[URLContainer setLineFragmentPadding:(CGFloat)0.];
		[URLManager setUsesScreenFonts:YES];
		[URLManager setBackgroundLayoutEnabled:NO];
		
		[URLManager addTextContainer:URLContainer];
		[URLStorage addLayoutManager:URLManager];
	}
	
	if ( [anObj isKindOfClass:[NSAttributedString class]] ) {
		[URLStorage setAttributedString:anObj];
		/* Fix a bug where fonts don't match and causes a mismatch of what is seen
			and what is used to calculate where link is at.
		*/
		if ( [anObj length] > 0 ) {
			NSUInteger strLen = [anObj length];
			NSRange stringRange = { 0, strLen }, returnRange = { NSNotFound, 0 };
			while ( stringRange.location < strLen ) {
				NSFont *testFont = [anObj attribute:NSFontAttributeName atIndex:stringRange.location longestEffectiveRange:&returnRange inRange:stringRange];
				if ( testFont == nil ) {
					if ( (NSMaxRange(returnRange) == strLen) || (NSMaxRange(returnRange) == 0) ) {
						[URLStorage addAttribute:NSFontAttributeName value:[self font] range:NSMakeRange(0, strLen)];
						break;
					} else
						[URLStorage addAttribute:NSFontAttributeName value:[self font] range:returnRange];
				}
				stringRange.location = NSMaxRange(returnRange);
				stringRange.length = strLen - stringRange.location;
			}
		}
	} else if ( [anObj isKindOfClass:[NSString class]] ) {
		/* Assume the entire string is a link */
		NSMutableParagraphStyle *aStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_4
		if ( [[self cell] respondsToSelector:@selector(lineBreakMode)] ) {
			NSUInteger mode = NSLineBreakByWordWrapping;
			NSCell *cell = [self cell];
			NSInvocation *inv = [NSInvocation invocationWithMethodSignature:[cell methodSignatureForSelector:@selector(lineBreakMode)]];
			[inv setTarget:cell];
			[inv setSelector:@selector(lineBreakMode)];
			[inv invoke];
			[inv getReturnValue:&mode];
			[aStyle setLineBreakMode:mode];
		}
	#else
		[aStyle setLineBreakMode:[[self cell] lineBreakMode]];
	#endif
		[aStyle setAlignment:[self alignment]];
		NSDictionary *attribs = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor blueColor], NSForegroundColorAttributeName, [NSNumber numberWithInt:NSSingleUnderlineStyle], NSUnderlineStyleAttributeName, aStyle, NSParagraphStyleAttributeName, anObj, NSLinkAttributeName, [self font], NSFontAttributeName, nil];
		NSAttributedString *aStr = [[[NSAttributedString alloc] initWithString:anObj attributes:attribs] autorelease];
		[URLStorage setAttributedString:aStr];
		anObj = aStr;
	} else {
		[NSException raise:NSInternalInconsistencyException format:@"%@ can only take an attributed string or normal string as its object value", NSStringFromClass([self class])];
	}
	[super setObjectValue:anObj];
	[[self window] invalidateCursorRectsForView:self];
}

- (void)resetCursorRects
{
	if ( (URLStorage == nil) || ([URLStorage length] == 0) ) {
		[super resetCursorRects];
		return;
	}
	
	NSCursor *pointingCursor = nil;
	
#if MAC_OS_X_VERSION_MIN_REQUIRED < MAC_OS_X_VERSION_10_3
	if ( [NSCursor respondsToSelector:@selector(pointingHandCursor)] ) {
		pointingCursor = [NSCursor performSelector:@selector(pointingHandCursor)];
	} else {
		[super resetCursorRects];
		return;
	}
#else
	pointingCursor = [NSCursor pointingHandCursor];
#endif
	
	NSRect cellBounds = [[self cell] drawingRectForBounds:[self bounds]];
	
	NSUInteger myLength = [URLStorage length];
	NSRange stringRange = { 0, myLength };
	
	if ( displayToolTips ) [self removeAllToolTips];
	
	NSRect superVisRect = [self convertRect:[[self superview] visibleRect] fromView:[self superview]];
	
	while ( stringRange.location < myLength ) {
		NSRange returnRange = { NSNotFound, 0 };
		id aVal = [URLStorage attribute:NSLinkAttributeName atIndex:stringRange.location longestEffectiveRange:&returnRange inRange:stringRange];
		
		if ( aVal != nil ) {
			NSUInteger numRects = 0, i = 0;
			NSRange glyphRange = [URLManager glyphRangeForCharacterRange:returnRange actualCharacterRange:NULL];
			NSRectArray rectArray = [URLManager rectArrayForGlyphRange:glyphRange withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0) inTextContainer:URLContainer rectCount:&numRects], linkRects = NULL;
			linkRects = calloc( numRects, sizeof( NSRect ) );
			memcpy( linkRects, rectArray, numRects * sizeof( NSRect ) );
			for ( i = 0; i < numRects; i++ ) {
				NSRange thisRange = NSIntersectionRange([URLManager glyphRangeForBoundingRect:linkRects[i] inTextContainer:URLContainer], glyphRange);
				NSRect linkRect = [URLManager boundingRectForGlyphRange:thisRange inTextContainer:URLContainer];
				linkRect.origin.x += cellBounds.origin.x;
				linkRect.origin.y += cellBounds.origin.y;
				NSRect textRect = NSIntersectionRect(linkRect, cellBounds);
				NSRect cursorRect = NSIntersectionRect(textRect, superVisRect);
				if ( NSIntersectsRect( textRect, superVisRect ) ) {
					[self addCursorRect:cursorRect cursor:pointingCursor];
					if ( displayToolTips ) [self addToolTipRect:cursorRect owner:self userData:nil];
				}
			}
			free( linkRects );
		}
		stringRange.location = NSMaxRange(returnRange);
		stringRange.length = myLength - stringRange.location;
	}
}

#pragma mark -
#pragma mark Supporting Methods
#pragma mark -

- (NSURL *)urlAtMouse:(NSPoint)mousePoint
{
	NSURL *urlAtMouse = nil;
	NSRect cellBounds = [[self cell] drawingRectForBounds:[self bounds]];
	
	if ( ([URLStorage length] > 0 ) && [self mouse:mousePoint inRect:cellBounds] ) {
		id aVal = nil;
		NSRange returnRange = { NSNotFound, 0 };
		NSUInteger glyphIndex = [URLManager glyphIndexForPoint:mousePoint inTextContainer:URLContainer];
		NSUInteger charIndex = [URLManager characterIndexForGlyphAtIndex:glyphIndex];
		
		aVal = [URLStorage attribute:NSLinkAttributeName atIndex:charIndex longestEffectiveRange:&returnRange inRange:NSMakeRange(charIndex, [URLStorage length] - charIndex)];
		
		if ( aVal != nil ) {
			NSUInteger numRects = 0, i = 0;
			NSRange glyphRange = [URLManager glyphRangeForCharacterRange:returnRange actualCharacterRange:NULL];
			NSRectArray rectArray = [URLManager rectArrayForGlyphRange:glyphRange withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0) inTextContainer:URLContainer rectCount:&numRects], linkRects = NULL;
			linkRects = calloc( numRects, sizeof( NSRect ) );
			memcpy( linkRects, rectArray, numRects * sizeof( NSRect ) );
			for ( i = 0; i < numRects; i++ ) {
				NSRange thisRange = NSIntersectionRange([URLManager glyphRangeForBoundingRect:linkRects[i] inTextContainer:URLContainer], glyphRange);
				NSRect linkRect = [URLManager boundingRectForGlyphRange:thisRange inTextContainer:URLContainer];
				linkRect.origin.x += cellBounds.origin.x;
				linkRect.origin.y += cellBounds.origin.y;
				if ( [self mouse:mousePoint inRect:NSIntersectionRect(linkRect, cellBounds)] ) {
					// be smart about links stored as strings
					if ( [aVal isKindOfClass:[NSString class]] ) aVal = [NSURL URLWithString:aVal];
					urlAtMouse = aVal;
				}
			}
			free( linkRects );
		}
	}
	return urlAtMouse;
}

- (NSString *)stringAtMouse:(NSPoint)mousePoint
{
	NSString *mouseString = nil;
	NSRect cellBounds = [[self cell] drawingRectForBounds:[self bounds]];
	
	if ( [URLStorage length] && [self mouse:mousePoint inRect:cellBounds] ) {
		id aVal = nil;
		NSRange charRange = { NSNotFound, 0 };
		NSUInteger glyphIndex = [URLManager glyphIndexForPoint:mousePoint inTextContainer:URLContainer];
		NSUInteger charIndex = [URLManager characterIndexForGlyphAtIndex:glyphIndex];
		
		aVal = [URLStorage attribute:NSLinkAttributeName atIndex:charIndex longestEffectiveRange:&charRange inRange:NSMakeRange(0, [URLStorage length])];
		
		if ( aVal ) {
			mouseString = [[URLStorage string] substringWithRange:charRange];
		}
	}
	return mouseString;
}

- (void)copyURL:(id)sender
{
	NSPasteboard *copyBoard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
	NSArray *objs = [sender representedObject];
	NSURL *copyURL = [objs objectAtIndex:0];
	NSString *urlString = ([objs count] > 1) ? [objs objectAtIndex:1] : [copyURL absoluteString];
	[copyBoard declareTypes:[NSArray arrayWithObjects:NSURLPboardType, NSStringPboardType, nil] owner:nil];
	[copyURL writeToPasteboard:copyBoard];
	[copyBoard setString:urlString forType:NSStringPboardType];
}

#pragma mark -
#pragma mark Event Handling
#pragma mark -

- (NSMenu *)menuForEvent:(NSEvent *)aEvent
{
	if ( !canCopyURLs ) return nil;
	NSPoint mousePoint = [self convertPoint:[aEvent locationInWindow] fromView:nil];
	NSURL *anURL = [self urlAtMouse:mousePoint];
	
	if ( anURL ) {
		NSString *mouseString = [self stringAtMouse:mousePoint];
		NSMenu *aMenu = [[[NSMenu alloc] initWithTitle:@"Copy URL"] autorelease];
		NSMenuItem *anItem = [[[NSMenuItem alloc] initWithTitle:@"" action:@selector(copyURL:) keyEquivalent:@""] autorelease];
		NSString *title = NSLocalizedString(@"Copy URL", @"Copy URL");
		NSFont *menuFont = [NSFont menuFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
		[anItem setAttributedTitle:[[[NSAttributedString alloc] initWithString:title attributes:[NSDictionary dictionaryWithObject:menuFont forKey:NSFontAttributeName]] autorelease]];
		[anItem setTarget:self];
		[anItem setRepresentedObject:[NSArray arrayWithObjects:anURL, mouseString, nil]];
		[aMenu addItem:anItem];
		
		return aMenu;
	}
	
	return nil;
}

- (void)mouseDown:(NSEvent *)mouseEvent
{
	/* Not calling [super mouseDown:] because there are some situations where
		the mouse tracking is ignored otherwise. */
	
	/* Remember which URL was clicked originally, so we don't end up opening
		the wrong URL accidentally.
	*/
	[clickedURL release];
	clickedURL = [[self urlAtMouse:[self convertPoint:[mouseEvent locationInWindow] fromView:nil]] retain];
}

- (void)mouseDragged:(NSEvent *)mouseEvent
{
	if ( canDragURLs && (clickedURL != nil) ) {
		NSPoint mouseLoc = [self convertPoint:[mouseEvent locationInWindow] fromView:nil];
		NSString *mouseString = [self stringAtMouse:mouseLoc];
		NSPasteboard *dragBoard = [NSPasteboard pasteboardWithName:NSDragPboard];
		NSImage *anImg = nil, *dragImage = nil;
		NSString *iconType = nil, *scheme = [clickedURL scheme];
		CGFloat imgSize = (CGFloat)64.;
		NSAttributedString *str = nil;
		NSRect imgRect = NSZeroRect, dragRect = NSZeroRect, txtRect = NSZeroRect;
		
		if ( mouseString ) {
			str = [[[NSAttributedString alloc] initWithString:mouseString attributes:[NSDictionary dictionaryWithObjectsAndKeys:[self font], NSFontAttributeName, [NSColor alternateSelectedControlTextColor], NSForegroundColorAttributeName, nil]] autorelease];
		}
		
		if ( [scheme isEqualToString:@"http"] ) iconType = @"webloc";
		else if ( [scheme isEqualToString:@"mailto"] ) iconType = @"mailloc";
		else if ( [scheme isEqualToString:@"ftp"] ) iconType = @"ftploc";
		else if ( [scheme isEqualToString:@"afp"] ) iconType = @"afploc";
		else if ( [scheme isEqualToString:@"at"] ) iconType = @"atloc";
		else iconType = @"inetloc";
		
		
		anImg = [[NSWorkspace sharedWorkspace] iconForFileType:iconType];
		[anImg setScalesWhenResized:YES];
		[anImg setSize:NSMakeSize( imgSize, imgSize )];
		
		imgRect = dragRect = (NSRect){ {(CGFloat)0., (CGFloat)0.}, [anImg size] };
		
		if ( str ) {
			NSSize s = [str size];
			dragRect.size.height += (s.height + (CGFloat)4.);
			if ( dragRect.size.width < (s.width + (CGFloat)10.) )
				dragRect.size.width = (s.width + (CGFloat)10.);
			dragRect = NSIntegralRect( dragRect );
			txtRect = NSMakeRect( (CGFloat)0., (CGFloat)0., s.width, s.height );
			txtRect.origin.x = NSMidX(dragRect) - (NSWidth(txtRect) / (CGFloat)2.);
			txtRect.origin.y += (CGFloat)2.;
			txtRect = NSIntegralRect( txtRect );
			imgRect.origin.x = NSMidX(dragRect) - (NSWidth(imgRect) / (CGFloat)2.);
			imgRect.origin.y = NSHeight(dragRect) - imgSize;
			imgRect = NSIntegralRect( imgRect );
		}
		
		dragImage = [[[NSImage alloc] initWithSize:dragRect.size] autorelease];
		
		[dragImage lockFocus];
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		[[NSGraphicsContext currentContext] setShouldAntialias:YES];
		if ( str ) {
			NSRect pathRect = txtRect;
			pathRect.origin.x -= (CGFloat)4.;
			pathRect.size.width += (CGFloat)8.;
			pathRect.origin.y -= (CGFloat)2.;
			pathRect.size.height += (CGFloat)4.;
			pathRect = NSOffsetRect( NSIntegralRect( pathRect ), (CGFloat)0.5, (CGFloat)0.5 );
			NSBezierPath *path = [NSBezierPath bezierPathWithRect:pathRect];
			[[self dragTextBackgroundColor] set];
			[path fill];
			[[NSColor blackColor] set];
			[path stroke];
			[str drawInRect:txtRect];
		}
		[anImg drawInRect:imgRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:(CGFloat)1.0];
		[dragImage unlockFocus];
		
		[dragBoard declareTypes:[NSArray arrayWithObjects:NSURLPboardType, NSStringPboardType, nil] owner:nil];
		[clickedURL writeToPasteboard:dragBoard];
		if ( mouseString ) [dragBoard setString:mouseString forType:NSStringPboardType];
		else [dragBoard setString:[clickedURL absoluteString] forType:NSStringPboardType];
		
		mouseLoc.x -= NSMidX(imgRect);
		mouseLoc.y += NSMidY(imgRect);
		
		[self dragImage:dragImage at:mouseLoc offset:NSMakeSize((CGFloat)0., (CGFloat)0.) event:mouseEvent pasteboard:dragBoard source:self slideBack:YES];
		[clickedURL release];
		clickedURL = nil;
	}
}

- (void)mouseUp:(NSEvent *)mouseEvent
{
	NSURL *urlAtMouse = [self urlAtMouse:[self convertPoint:[mouseEvent locationInWindow] fromView:nil]];
	if ( (urlAtMouse != nil)  &&  [urlAtMouse isEqualTo:clickedURL] ) {
		// check if delegate wants to open the URL itself, if not, let the workspace open the URL
		if ( ([self delegate] == nil)  || ![[self delegate] respondsToSelector:@selector(textField:openURL:)] || ![[self delegate] textField:self openURL:urlAtMouse] )
			[[NSWorkspace sharedWorkspace] openURL:urlAtMouse];
	}
	[clickedURL release];
	clickedURL = nil;
	[super mouseUp:mouseEvent];
}

#pragma mark -
#pragma mark Accessors
#pragma mark -

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
- (void)setDelegate:(id <DSClickableURLTextFieldDelegate>)del
{
	[super setDelegate:del];
}

- (id <DSClickableURLTextFieldDelegate>)delegate
{
	return (id <DSClickableURLTextFieldDelegate>)[super delegate];
}
#endif

- (void)setCanCopyURLs:(BOOL)aFlag
{
	canCopyURLs = aFlag;
}

- (BOOL)canCopyURLs
{
	return canCopyURLs;
}

- (void)setCanDragURLs:(BOOL)flag
{
	canDragURLs = flag;
}

- (BOOL)canDragURLs
{
	return canDragURLs;
}

- (void)setDisplayToolTips:(BOOL)flag
{
	displayToolTips = flag;
}

- (BOOL)displayToolTips
{
	return displayToolTips;
}

- (void)setDragTextBackgroundColor:(NSColor *)color
{
	[color retain];
	[dragTextBackgroundColor release];
	dragTextBackgroundColor = color;
}

- (NSColor *)dragTextBackgroundColor
{
	if ( dragTextBackgroundColor ) return [[dragTextBackgroundColor retain] autorelease];
	else return [[[[NSColor alternateSelectedControlColor] colorWithAlphaComponent:(CGFloat)0.75] retain] autorelease];
}

#pragma mark -
#pragma mark Tooltips
#pragma mark -

- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData
{
	NSURL *anURL = [self urlAtMouse:point];
	if ( anURL ) return [anURL absoluteString];
	return nil;
}

@end
