//
//  GrowlBezelWindowView.h
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 09/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlNotificationView.h"

@interface GrowlBezelWindowView : GrowlNotificationView {
	NSImage			*icon;
	NSString		*title;
	NSString		*text;

	NSColor			*textColor;
	NSColor			*backgroundColor;
	NSLayoutManager	*layoutManager;
}

- (void) setIcon:(NSImage *)icon;
- (void) setTitle:(NSString *)title;
- (void) setText:(NSString *)text;
- (void) setPriority:(int)priority;

- (CGFloat) descriptionHeight:(NSString *)text attributes:(NSDictionary *)attributes width:(CGFloat)width;

- (id) target;
- (void) setTarget:(id)object;

- (SEL) action;
- (void) setAction:(SEL)selector;

@end
