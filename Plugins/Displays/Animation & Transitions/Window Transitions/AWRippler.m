/*
 * Project:     RippleEffect
 * File:        AWRippler.m
 * Author:      Andrew Wellington
 *
 * License:
 * Copyright (C) 2005 Andrew Wellington.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "AWRippler.h"
#import <math.h>

/* NSWindow Category for our bonus features */
@interface NSWindow(AWRipplePrivate)
- (NSInteger)windowNum;
- (void)scaleX:(CGFloat)x Y:(CGFloat)y;
@end

@implementation NSWindow(AWRipplePrivate)
- (NSInteger)windowNum
{
    return _windowNum;
}
- (void)scaleX:(CGFloat)x Y:(CGFloat)y {
	CGAffineTransform original;
	NSPoint scalePoint;
	NSRect screenFrame;
	//NSLog(@"%@", NSStringFromRect(_frame));
	NSPoint point = NSMakePoint(_frame.size.width / 2.0, _frame.size.height / 2.0);
        
	if ([[NSScreen screens] count]) {
        screenFrame = [[[NSScreen screens] objectAtIndex:0] frame];
        
        scalePoint.x = _frame.origin.x + point.x;
        scalePoint.y = - ((_frame.origin.y + point.y) - screenFrame.size.height);
        
        original.a = 1.0 ; original.b = 0.0 ;
        original.c = 0.0 ; original.d = 1.0 ;
        original.tx = - _frame.origin.x ;
        original.ty = + _frame.origin.y + _frame.size.height - NSMaxY(screenFrame);
        
        original = CGAffineTransformTranslate(original, scalePoint.x, scalePoint.y);
        original = CGAffineTransformScale(original, x, y);
        original = CGAffineTransformTranslate(original, -scalePoint.x, -scalePoint.y);
        
        CGSSetWindowTransform(_CGSDefaultConnection(), (CGSWindow)_windowNum, original);
	}
}

@end

/* NSWindow Category implementation for easy rippling */
@implementation NSWindow(AWRipple)
- (void)ripple
{
    AWRippler *rippler;
    
    rippler = [[AWRippler alloc] init];
    [rippler rippleWindow:self];
    [rippler release];
}
@end

/* Interface for Core Image Core Graphics Server filter */
@interface CICGSFilter : NSObject
{
    void *_cid;
    unsigned int _filter_id;
}

+ (id)filterWithFilter:(CIFilter *)filter connectionID:(CGSConnection)cid;
- (id)initWithFilter:(CIFilter *)filter connectionID:(CGSConnection)cid;
- (void)dealloc;
- (void)setValue:(id)value forKey:(NSString *)key;
- (void)setValuesForKeysWithDictionary:(NSDictionary *)dict;
- (int)addToWindow:(CGSWindow)windowID flags:(unsigned int)flags;
- (int)removeFromWindow:(CGSWindow)windowID;
- (id)description;
@end

/* NSWindow subclass for our covering window */
@interface AWRippleWindow : NSWindow {
}
@end

@implementation AWRippleWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
#pragma unused (aStyle, bufferingType, flag)
    NSWindow* result = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [result setBackgroundColor: [NSColor clearColor]];
    [result setAlphaValue:1.0];
    [result setOpaque:NO];
    return result;
}
@end

/* NSView subclass for our covering window */
@interface AWRippleView : NSView {
}
@end

@implementation AWRippleView
-(void)drawRect:(NSRect)rect
{
#pragma unused (rect)
	NSLog(@"%s", __FUNCTION__);	
	
	[[NSColor clearColor] set];
    NSRectFill([self frame]);
}
@end

/* CoreGraphics private stuff */
extern CGSConnection _CGSDefaultConnection(void);

/* The magic rippler class */
@implementation AWRippler
- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    
    win = nil;
	startTime = 0;
	aWindowID = 0;
	rippleFilter = nil;
	windowFilter = nil;
    
    return self;
}

- (void) rippleWindow:(NSWindow *)rippleWindow
{
    CGSConnection cid = _CGSDefaultConnection();
    NSRect rect;
    NSRect rippleRect;
    NSRect screenRect;
    NSArray *screens;
    NSEnumerator *screenEnum;
    NSScreen *screen;
    
    if (!FLOAT_EQ(startTime, 0.0))
        return;
    
    rippleRect = [rippleWindow frame];
    ripplingWindow = [rippleWindow retain];
    
    /* create covering window */
    rect = NSZeroRect;
    screens = [NSScreen screens];
    screenEnum = [screens objectEnumerator];
    
    while ((screen = [screenEnum nextObject]))
    {
        rect = NSUnionRect(rect, [screen frame]);
    }
        
    win = [[AWRippleWindow alloc] initWithContentRect:rect
                                            styleMask:NSBorderlessWindowMask
                                              backing:NSBackingStoreNonretained
                                                defer:NO];
	[win setBackgroundColor:[NSColor clearColor]];
	[win setOpaque:NO];
	[win setHasShadow:NO];
	[win setContentView:[[[AWRippleView alloc] initWithFrame:[win frame]] autorelease]];
	
	[win orderFrontRegardless];
    [rippleWindow orderWindow:NSWindowAbove relativeTo:[win windowNum]];
    
    
    /* calculate the rectangle in the covering window */
    screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    rippleRect.origin.y = - (NSMaxY(rippleRect) - screenRect.size.height);
   
    /* create filter */
    rippleFilter = [[CIFilter filterWithName:@"CIShapedWaterRipple"] retain];
    [rippleFilter setDefaults];
    [rippleFilter setValue:[NSNumber numberWithFloat:40.0f] forKey:@"inputCornerRadius"];
    [rippleFilter setValue:[CIVector vectorWithX:rippleRect.origin.x-40.0 Y:(rippleRect.origin.y - 40.0)] forKey:@"inputPoint0"];
    [rippleFilter setValue:[CIVector vectorWithX:(rippleRect.origin.x + rippleRect.size.width + 40.0) Y:(rippleRect.origin.y + rippleRect.size.height + 40.0)] forKey:@"inputPoint1"];

    
    [rippleFilter setValue:[NSNumber numberWithFloat:0.0f] forKey:@"inputPhase"];
    
    windowFilter = [[CICGSFilter filterWithFilter:rippleFilter connectionID:cid] retain];
	[windowFilter addToWindow:aWindowID flags:0x3001];    
    aWindowID = (CGSWindow)[win windowNum];
    [self retain];
    
    [NSThread detachNewThreadSelector:@selector(animationLoop:) toTarget:self withObject:self];
}

- (void)animationLoop:(id)sender
{
#pragma unused (sender)
    NSAutoreleasePool *pool;
	CGSConnection cid = _CGSDefaultConnection();
    CICGSFilter *oldFilter = windowFilter;
    double scale;
    CFAbsoluteTime now;
    CGAffineTransform originalTransform;
    
    CGSGetWindowTransform(cid, (CGSWindow)[ripplingWindow windowNum], &originalTransform);
    
    pool = [[NSAutoreleasePool alloc] init];
    
    startTime = CFAbsoluteTimeGetCurrent();
    now = CFAbsoluteTimeGetCurrent();
    
    while (now < (startTime + 2.5) && (now >= startTime))
    {
        if (now - startTime < 1.5) {
            scale = 1.0 - exp(-2.4 * (now - startTime)) * sin(40.0/M_PI * (now - startTime)) * 0.15;
            //[ripplingWindow scaleX:scale Y:scale];
        }
        else
        {
            CGSSetWindowTransform(cid, (CGSWindow)[ripplingWindow windowNum], originalTransform);
        }
        
        [rippleFilter setValue:[NSNumber numberWithDouble:160.0*(now - startTime)] forKey:@"inputPhase"];
        windowFilter = [[CICGSFilter filterWithFilter:rippleFilter connectionID:cid] retain];
		[windowFilter addToWindow:aWindowID flags:0x3001];
        [oldFilter removeFromWindow:aWindowID];
        
        now = CFAbsoluteTimeGetCurrent();
    }
    CGSSetWindowTransform(cid, (CGSWindow)[ripplingWindow windowNum], originalTransform);

    [windowFilter removeFromWindow:aWindowID];
    [rippleFilter release];
    [windowFilter release];
    [ripplingWindow release];
    [win orderOut: self];
    [win release];
    [pool release];
    startTime = 0.0;
}

@end
