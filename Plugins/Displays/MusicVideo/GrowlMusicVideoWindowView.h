//
//  GrowlMusicVideoWindowView.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlNotificationView.h"

@interface GrowlMusicVideoWindowView : GrowlNotificationView {
	NSImage				*icon;
	NSString			*title;
	NSString			*text;
	NSDictionary		*textAttributes;
	NSDictionary		*titleAttributes;
	NSColor				*textColor;
	NSColor				*backgroundColor;

	CGLayerRef			layer;
	NSImage				*cache;
	BOOL				needsDisplay;
}

- (void) setIcon:(NSImage *)icon;
- (void) setTitle:(NSString *)title;
- (void) setText:(NSString *)text;
- (void) setPriority:(int)priority;

- (id) target;
- (void) setTarget:(id)object;

- (SEL) action;
- (void) setAction:(SEL)selector;

@end
