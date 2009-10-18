//
//  NSWindow+Transforms.m
//  Rotated Windows
//
//  Created by Wade Tregaskis on Fri May 21 2004.
//
//  Copyright (c) 2004 Wade Tregaskis. All rights reserved.
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//    * Redistributions of source code must retain the above copyright notice, this
//      list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright notice, this
//      list of conditions and the following disclaimer in the documentation and/or
//      other materials provided with the distribution.
//    * Neither the name of Wade Tregaskis nor the names of its contributors may be
//      used to endorse or promote products derived from this software without specific
//      prior written permission.
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
//  SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
//  INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
//  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
// ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import "NSWindow+Transforms.h"
#import "CoreGraphicsServices.h"

@implementation NSWindow (Transforms)

- (NSPoint) windowToScreenCoordinates:(NSPoint)point {
	NSPoint result;
	NSRect screenFrame = [[[NSScreen screens] objectAtIndex:0U] frame];

	// Doesn't work... it looks like the y co-ordinate is not inverted as necessary
	//result = [self convertBaseToScreen:point];

	result.x = _frame.origin.x + point.x;
	result.y = screenFrame.origin.y + screenFrame.size.height - (_frame.origin.y + point.y);

	return result;
}

- (NSPoint) screenToWindowCoordinates:(NSPoint)point { // Untested
	NSPoint result;
	NSRect screenFrame = [[[NSScreen screens] objectAtIndex:0U] frame];

	result.x = point.x - (screenFrame.origin.x + _frame.origin.x);
	result.y = screenFrame.origin.y + screenFrame.size.height - _frame.origin.y - point.y;

	return point; // To be completed
}

- (void) rotate:(CGFloat)radians {
	[self rotate:radians about:NSMakePoint(_frame.size.width * 0.5, _frame.size.height * 0.5)];
}

- (void) rotate:(CGFloat)radians about:(NSPoint)point {
	CGAffineTransform original;
	CGSConnectionID connection;
	NSPoint rotatePoint = [self windowToScreenCoordinates:point];

	connection = _CGSDefaultConnection();
	CGSGetWindowTransform(connection, (CGSWindowID)_windowNum, &original);

	original = CGAffineTransformTranslate(original, rotatePoint.x, rotatePoint.y);
	original = CGAffineTransformRotate(original, -radians);
	original = CGAffineTransformTranslate(original, -rotatePoint.x, -rotatePoint.y);

	CGSSetWindowTransform(connection, (CGSWindowID)_windowNum, original);
}

- (void) scaleBy:(CGFloat)scaleFactor {
	[self scaleX:scaleFactor Y:scaleFactor];
}

- (void) scaleX:(CGFloat)x Y:(CGFloat)y {
	[self scaleX:x Y:y about:NSMakePoint(_frame.size.width * 0.5, _frame.size.height * 0.5) concat:YES];
}

- (void) setScaleX:(CGFloat)x Y:(CGFloat)y {
	[self scaleX:x Y:y about:NSMakePoint(_frame.size.width * 0.5, _frame.size.height * 0.5) concat:NO];
}

- (void) scaleX:(CGFloat)x Y:(CGFloat)y about:(NSPoint)point concat:(BOOL)concat {
	CGAffineTransform original;
	CGSConnectionID connection;
	NSPoint scalePoint = [self windowToScreenCoordinates:point];

	connection = _CGSDefaultConnection();

	if (concat) {
		CGSGetWindowTransform(connection, (CGSWindowID)_windowNum, &original);
	} else {
		// Get the screen position of the top left corner, by which our window is positioned
		NSPoint p = [self windowToScreenCoordinates:NSMakePoint(0.0, _frame.size.height)];
		original = CGAffineTransformMakeTranslation(-p.x, -p.y);
	}
	original = CGAffineTransformTranslate(original, scalePoint.x, scalePoint.y);
	original = CGAffineTransformScale(original, 1.0 / x, 1.0 / y);
	original = CGAffineTransformTranslate(original, -scalePoint.x, -scalePoint.y);

	CGSSetWindowTransform(connection, (CGSWindowID)_windowNum, original);
}

- (void) reset {
	// Note that this is not quite perfect... if you transform the window enough it may end up anywhere on the screen, but resetting it plonks it back where it started, which may correspond to it's most-logical position at that point in time.  Really what needs to be done is to reset the current transform matrix, in all places except it's translation, such that it stays roughly where it currently is.

	// Get the screen position of the top left corner, by which our window is positioned
	NSPoint point = [self windowToScreenCoordinates:NSMakePoint(0.0, _frame.size.height)];

	CGSSetWindowTransform(_CGSDefaultConnection(), (CGSWindowID)_windowNum, CGAffineTransformMakeTranslation(-point.x, -point.y));
}

#pragma mark -

// Thanks to Alcor for the following. This allows us to tell the window manager
// that the window should be sticky. A sticky window will stay around when the
// Expose sweep-all-windows-away event happens. Additionally, if a window is not
// sticky while it fades in (see FadingWindowController for an example of fading
// in), and simultaneously the desktop is switched via DesktopManager, the window
// may end up getting left on the previous desktop, even if that window's level
// set to NSStatusWindowLevel. See http://www.cocoadev.com/index.pl?DontExposeMe
// for more information.

- (void) setSticky:(BOOL)flag {
	CGSConnectionID cid;
	CGSWindowID wid;

	wid = (CGSWindowID)[self windowNumber];
	if (wid > 0) {
		cid = _CGSDefaultConnection();
		int tags[2] = { 0, 0 };
		
		if (!CGSGetWindowTags(cid, wid, tags, 32)) {
			tags[0] = flag ? (tags[0] | 0x00000800) : (tags[0] & ~0x00000800);
			CGSSetWindowTags(cid, wid, tags, 32);
		}
	}
}

@end
