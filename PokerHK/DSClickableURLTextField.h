/*
	DSClickableURLTextField
	
	Copyright (c) 2006 - 2009 Night Productions, by Darkshadow. All Rights Reserved.
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

#import <Cocoa/Cocoa.h>

#ifndef MAC_OS_X_VERSION_10_6
	#define MAC_OS_X_VERSION_10_6 1060
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
	@protocol DSClickableURLTextFieldDelegate <NSTextFieldDelegate>
		@optional
		- (BOOL)textField:(id)textField openURL:(NSURL *)url;
	@end
#endif

@interface DSClickableURLTextField : NSTextField {
	NSTextStorage	*URLStorage;
	NSLayoutManager *URLManager;
	NSTextContainer *URLContainer;
	NSURL			*clickedURL;
	NSColor			*dragTextBackgroundColor;
	BOOL			canCopyURLs;
	BOOL			canDragURLs;
	BOOL			displayToolTips;
}

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
- (void)setDelegate:(id <DSClickableURLTextFieldDelegate>)del;
- (id <DSClickableURLTextFieldDelegate>)delegate;
#endif
- (void)setCanCopyURLs:(BOOL)aFlag;
- (BOOL)canCopyURLs;
- (void)setCanDragURLs:(BOOL)flag;
- (BOOL)canDragURLs;
- (void)setDisplayToolTips:(BOOL)flag;
- (BOOL)displayToolTips;
- (void)setDragTextBackgroundColor:(NSColor *)color;
- (NSColor *)dragTextBackgroundColor;

@end

#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_6
@interface NSObject (DSClickableURLTextFieldDelegate)
- (BOOL)textField:(id)textField openURL:(NSURL *)url;
@end
#endif
