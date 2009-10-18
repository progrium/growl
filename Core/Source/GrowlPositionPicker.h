//
//  GrowlPositionPicker.h
//  Growl
//
//  Created by Jamie Kirkpatrick on 01.05.06.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GrowlPreferencePane.h"
#import "GrowlPositioningDefines.h"

/* Size should be 150 * 100 */

#define GrowlPositionPickerMinWidth	 150.0
#define GrowlPositionPickerMinHeight	100.0

extern NSString *GrowlPositionPickerChangedSelectionNotification;

extern NSString *NSStringFromGrowlPositionOrigin(enum GrowlPositionOrigin pos);

@interface GrowlPositionPicker : NSView {	
	enum GrowlPositionOrigin	selectedPosition;
	enum GrowlPositionOrigin	rolloverPosition;
	unsigned					trackingRectTag;
	BOOL						mouseOverView;
	BOOL						windowWatchesMouseMovedEvents;
	NSBezierPath				*topLeftHotCorner;
	NSBezierPath				*topRightHotCorner;
	NSBezierPath				*bottomRightHotCorner;
	NSBezierPath				*bottomLeftHotCorner;
}

- (enum GrowlPositionOrigin) selectedPosition;
- (void) setSelectedPosition: (enum GrowlPositionOrigin) theSelectedPosition;

@end
