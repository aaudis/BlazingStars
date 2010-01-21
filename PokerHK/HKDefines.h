/*
 *  HKDefines.h
 *  PokerHK
 *
 *  Created by Steven Hamblin on 21/06/09.
 *  Copyright 2009 Steven Hamblin. All rights reserved.
 *
 */

//#define HKDEBUG 1

#define TOGGLETAG 22

static NSRect FlippedScreenBounds(NSRect bounds)
{
    float screenHeight = NSMaxY([[[NSScreen screens] objectAtIndex:0] frame]);
    bounds.origin.y = screenHeight - NSMaxY(bounds);
    return bounds;
}
