//
//  GrowlPositionController.m
//  Growl
//
//  Created by Ofri Wolfus on 31/08/05.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details
//

#import "GrowlPositionController.h"
#import "GrowlDisplayWindowController.h"
#import "GrowlPreferencesController.h"
#import "NSMutableStringAdditions.h"
#import "GrowlDefines.h"
#import "GrowlTicketController.h"

#import "GrowlLog.h"

@interface GrowlPositionController (PRIVATE)
- (NSMutableSet *)reservedRectsForScreen:(NSScreen *)inScreen;
- (NSRectArray)copyRectsInSet:(NSSet *)rectSet count:(NSUInteger *)outCount padding:(CGFloat)padding excludingDisplayController:(GrowlDisplayWindowController *)displayController;
@end

@implementation GrowlPositionController

//Initialize
- (id) initSingleton {
	if ((self = [super initSingleton])) {
		reservedRects = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		reservedRectsByController = [[NSMutableDictionary alloc] init];
	}

	return self;
}

//Deallocate
- (void) destroy {
	CFRelease(reservedRects);
}

//Read in the stored selection from picker and translate to a properly returned GrowlPosition.
+ (enum GrowlPosition)selectedOriginPosition
{
	enum GrowlPositionOrigin globalSelectedPosition = (enum GrowlPositionOrigin)[[GrowlPreferencesController sharedController] integerForKey:GROWL_POSITION_PREFERENCE_KEY];
	enum GrowlPosition translatedPosition;
		
	switch(globalSelectedPosition){
		default:
		case GrowlNoOrigin:
			//Default to middle of the screen if no origin is set, though this case shouldn't be hit.
			translatedPosition = GrowlMiddleColumnPosition;
			break;
		case GrowlTopLeftCorner:
			translatedPosition = GrowlTopLeftPosition;
			break;
		case GrowlBottomRightCorner:
			translatedPosition = GrowlBottomRightPosition;
			break;
		case GrowlTopRightCorner:
			translatedPosition = GrowlTopRightPosition;
			break;
		case GrowlBottomLeftCorner:
			translatedPosition = GrowlBottomLeftPosition;
			break;
	}
	
	return translatedPosition;
}

//Return a rect suitable for the position and screen.
+ (NSRect) rectForPosition:(enum GrowlPosition)position inScreen:(NSScreen *)screen {
	NSRect screenFrame;
	NSSize areaSize;
	NSRect result = NSZeroRect;

	//Treat nil as the main screen
	if (!screen)
		screen = [NSScreen mainScreen];

	screenFrame = [screen visibleFrame];
	areaSize = NSMakeSize(screenFrame.size.width / 3.0, screenFrame.size.height / 3.0);	//We have 9 identical areas on each screen

	switch (position) {
			//Top left
		case GrowlTopLeftPosition:
			result = NSMakeRect(screenFrame.origin.x,
								screenFrame.origin.y + areaSize.height + areaSize.height,
								areaSize.width,
								areaSize.height);
			break;

			//Top middle
		case GrowlTopMiddlePosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width,
								screenFrame.origin.y + areaSize.height + areaSize.height,
								areaSize.width,
								areaSize.height);
			break;

			//Top right
		case GrowlTopRightPosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width + areaSize.width,
								screenFrame.origin.y + areaSize.height + areaSize.height,
								areaSize.width,
								areaSize.height);
			break;

			//Center left
		case GrowlCenterLeftPosition:
			result = NSMakeRect(screenFrame.origin.x,
								screenFrame.origin.y + areaSize.height,
								areaSize.width,
								areaSize.height);
			break;

			//Center middle
		case GrowlCenterMiddlePosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width,
								screenFrame.origin.y + areaSize.height,
								areaSize.width,
								areaSize.height);
			break;

			//Center right
		case GrowlCenterRightPosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width + areaSize.width,
								screenFrame.origin.y + areaSize.height,
								areaSize.width,
								areaSize.height);
			break;

			//Bottom left
		case GrowlBottomLeftPosition:
			result = NSMakeRect(screenFrame.origin.x,
								screenFrame.origin.y,
								areaSize.width,
								areaSize.height);
			break;

			//Bottom middle
		case GrowlBottomMiddlePosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width,
								screenFrame.origin.y,
								areaSize.width,
								areaSize.height);
			break;

			//Bottom right
		case GrowlBottomRightPosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width + areaSize.width,
								screenFrame.origin.y,
								areaSize.width,
								areaSize.height);
			break;

			//Top row
		case GrowlTopRowPosition:
			result = NSMakeRect(screenFrame.origin.x,
								screenFrame.origin.y + areaSize.height + areaSize.height,
								screenFrame.size.width,
								areaSize.height);
			break;

			//Center row
		case GrowlCenterRowPosition:
			result = NSMakeRect(screenFrame.origin.x,
								screenFrame.origin.y + areaSize.height,
								screenFrame.size.width,
								areaSize.height);
			break;

			//Bottom row
		case GrowlBottomRowPosition:
			result = NSMakeRect(screenFrame.origin.x,
								screenFrame.origin.y,
								screenFrame.size.width,
								areaSize.height);
			break;

			//Left column
		case GrowlLeftColumnPosition:
			result = NSMakeRect(screenFrame.origin.x,
								screenFrame.origin.y,
								areaSize.width,
								screenFrame.size.height);
			break;

			//Middle column
		case GrowlMiddleColumnPosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width,
								screenFrame.origin.y,
								areaSize.width,
								screenFrame.size.height);
			break;

			//Right column
		case GrowlRightColumnPosition:
			result = NSMakeRect(screenFrame.origin.x + areaSize.width + areaSize.width,
								screenFrame.origin.y,
								areaSize.width,
								screenFrame.size.height);
			break;
	}

	return result;
}

- (BOOL) positionDisplay:(GrowlDisplayWindowController *)displayController {
	GrowlLog *growlLog = [GrowlLog sharedController];
	
	GrowlApplicationTicket *displayTicket = [[GrowlTicketController sharedController] ticketForApplicationName:[[displayController notification] applicationName]];
	selectedPositionType = [displayTicket positionType];
	selectedCustomPosition = (enum GrowlPositionOrigin)[displayTicket selectedPosition];

	NSScreen *preferredScreen = [displayController screen];
	NSRect screenFrame = [preferredScreen visibleFrame];
	NSSize displaySize = [[displayController window] frame].size;
	CGFloat padding = [displayController requiredDistanceFromExistingDisplays];

	// Ask the display where it wants to be displayed in the first instance....
	NSPoint idealOrigin;
	NSRect idealFrame;

	enum GrowlExpansionDirection primaryDirection = [displayController primaryExpansionDirection];
	enum GrowlExpansionDirection secondaryDirection = [displayController secondaryExpansionDirection];
	
	if ([reservedRectsByController objectForKey:[NSValue valueWithPointer:displayController]]) {
		NSRect currentlyReservedRect = [[reservedRectsByController objectForKey:[NSValue valueWithPointer:displayController]] rectValue];
		idealOrigin = currentlyReservedRect.origin;
		
		//The expansion direction determines which origins should be kept constant
		switch (primaryDirection) {
			case GrowlDownExpansionDirection:
				idealOrigin.y += (currentlyReservedRect.size.height - displaySize.height);
				break;
			case GrowlUpExpansionDirection:
				break;
			case GrowlLeftExpansionDirection:
				idealOrigin.x += (currentlyReservedRect.size.width - displaySize.width);
				break;
			case GrowlRightExpansionDirection:
				break;
			case GrowlNoExpansionDirection:
				break;
		}

		idealFrame = NSMakeRect(idealOrigin.x, idealOrigin.y,
								displaySize.width, displaySize.height);

		if (!NSContainsRect(screenFrame,idealFrame)) {
			idealOrigin = [displayController idealOriginInRect:screenFrame];
			idealFrame = NSMakeRect(idealOrigin.x,idealOrigin.y,displaySize.width,displaySize.height);
		}
	} else {
		idealOrigin = [displayController idealOriginInRect:screenFrame];
		idealFrame = NSMakeRect(idealOrigin.x,idealOrigin.y,displaySize.width,displaySize.height);
	}
	
	// Try and reserve the rect
	NSRect displayFrame = idealFrame;
	if ([self reserveRect:displayFrame inScreen:preferredScreen forDisplayController:displayController]) {
		[[displayController window] setFrame:displayFrame display:YES animate:YES];		
		return YES;
	}

	// Something was blocking the display...try to find the next position for the display.

	[growlLog writeToLog:@"---"];
	[growlLog writeToLog:@"positionDisplay: could not reserve initial rect; looking for another one"];
	[growlLog writeToLog:@"primaryDirection: %@", NSStringFromGrowlExpansionDirection(primaryDirection)];
	[growlLog writeToLog:@"secondaryDirection: %@", NSStringFromGrowlExpansionDirection(secondaryDirection)];
	
	NSUInteger			numberOfRects;
	NSRectArray usedRects = [self copyRectsInSet:[self reservedRectsForScreen:preferredScreen] count:&numberOfRects padding:padding excludingDisplayController:displayController];

	/* This will loop until the display is placed or we run off the screen entirely
	 * A more 'efficient' implementation might sort all of the usedRects, then look at them iteratively.  I (evands) found it to be
	 * thoroughly nontrivial to do such a sort in a robust fashion. While the below code does loop more than an 'efficient' search,
	 * it ends up being a whole bunch of simple float comparisons in the worst case, which any modern computer can handle with ease. Let's
	 * not over-optimize unless this is an actual bottleneck. :)
	 */
	while (1) {
		BOOL haveBestSecondaryOrigin = NO;
		CGFloat bestSecondaryOrigin = 0.0;

		while (NSContainsRect(screenFrame,displayFrame)) {
			//Adjust in our primary direction
			switch (primaryDirection) {
				case GrowlDownExpansionDirection:
					displayFrame.origin.y -= 1;
					break;
				case GrowlUpExpansionDirection:
					displayFrame.origin.y += 1;
					break;
				case GrowlLeftExpansionDirection:
					displayFrame.origin.x -= 1;
					break;
				case GrowlRightExpansionDirection:
					displayFrame.origin.x += 1;
					break;
				case GrowlNoExpansionDirection:
					NSLog(@"This should never happen");
					free(usedRects);
					return NO;
					break;
			}
			
			BOOL intersects = NO;
			//Check to see if the proposed displayFrame intersects with any used rect
			for (NSUInteger i = 0; i < numberOfRects; i++) {
				if (NSIntersectsRect(displayFrame, usedRects[i])) {
					//We intersected. Sadness.
					intersects = YES;
					
					/* Determine, based on this intersection, how far we should shift if we end up moving in
					 * our secondary direction.
					 */
					switch (secondaryDirection) {
						case GrowlDownExpansionDirection:
						{
							if (!haveBestSecondaryOrigin ||
								NSMinY(usedRects[i]) > bestSecondaryOrigin) {
								haveBestSecondaryOrigin = YES;
								bestSecondaryOrigin = NSMinY(usedRects[i]) - NSHeight(displayFrame);
							}
							break;
						}
						case GrowlUpExpansionDirection:
						{
							if (!haveBestSecondaryOrigin ||
								NSMaxY(usedRects[i]) < bestSecondaryOrigin) {
								haveBestSecondaryOrigin = YES;
								bestSecondaryOrigin = NSMaxY(usedRects[i]);
							}
							break;
						}
						case GrowlLeftExpansionDirection:
						{
							if (!haveBestSecondaryOrigin ||
								NSMinX(usedRects[i]) < bestSecondaryOrigin) {
								haveBestSecondaryOrigin = YES;
								bestSecondaryOrigin = NSMinX(usedRects[i]) - NSWidth(displayFrame);
							}
							break;
						}
						case GrowlRightExpansionDirection:
						{
							if (!haveBestSecondaryOrigin ||
								NSMaxX(usedRects[i]) < bestSecondaryOrigin) {
								haveBestSecondaryOrigin = YES;
								bestSecondaryOrigin = NSMaxX(usedRects[i]);
							}
							break;
						}
						case GrowlNoExpansionDirection:
							NSLog(@"This should never happen");
							free(usedRects);
							return NO;
							break;
					}
				}
			}
			
			if (!intersects) break;
		}

		if (NSContainsRect(screenFrame,displayFrame)) {
			//The rect is on the screen! Try to reserve it.
			if ([self reserveRect:displayFrame inScreen:preferredScreen forDisplayController:displayController]) {
				[[displayController window] setFrame:displayFrame display:YES animate:YES];		
				free(usedRects);
				return YES;
			}
		}
		// If we've run offscreen or couldn't reserve that rect, use the secondary direction after resetting from our previous efforts
		switch (primaryDirection) {
			case GrowlDownExpansionDirection:
			case GrowlUpExpansionDirection:
				displayFrame.origin.y = idealFrame.origin.y;
				break;
			case GrowlLeftExpansionDirection:
			case GrowlRightExpansionDirection:
				displayFrame.origin.x = idealFrame.origin.x;
				break;
			case GrowlNoExpansionDirection:
				NSLog(@"This should never happen");
				free(usedRects);
				return NO;
				break;
		}
		
		switch (secondaryDirection) {
			case GrowlDownExpansionDirection:
			case GrowlUpExpansionDirection:
				displayFrame.origin.y = bestSecondaryOrigin;
				break;
			case GrowlLeftExpansionDirection:
			case GrowlRightExpansionDirection:
				displayFrame.origin.x = bestSecondaryOrigin;
				break;
			case GrowlNoExpansionDirection:
				NSLog(@"This should never happen");
				free(usedRects);
				return NO;
				break;
		}
		
		if (!NSContainsRect(screenFrame,displayFrame)) {
			NSLog(@"Could not display Growl notification; no screen space available.");
			break;
		}
	}
	
	free(usedRects);

	return NO;
}

//Reserve a rect in a specific screen.
- (BOOL) reserveRect:(NSRect)inRect inScreen:(NSScreen *)inScreen forDisplayController:(GrowlDisplayWindowController *)displayController {
	BOOL result = YES;
	NSValue *displayControllerValue = (displayController ? [NSValue valueWithPointer:displayController] : nil);

	//Treat nil as the main screen
	if (!inScreen) inScreen = [NSScreen mainScreen];

	NSMutableSet	*reservedRectsOfScreen = [self reservedRectsForScreen:inScreen];
	NSValue			*newRectValue = [NSValue valueWithRect:inRect];
	NSEnumerator	*rectValuesEnumerator;
	NSValue			*value;
	
	//Make sure the rect is not already reserved. However, if it is reserved by displayController, that's fine (it is just rerequesting its current space).
	if ([reservedRectsOfScreen member:newRectValue] &&
		(!displayController || (![[reservedRectsByController objectForKey:displayControllerValue] isEqual:newRectValue]))) {
		result = NO;
	} else {
		rectValuesEnumerator = [reservedRectsOfScreen objectEnumerator];
		
		// Loop through all the values in reservedRects and make sure
		// that the new rect does not intersect with any of the already
		// reserved rects, excepting if the displayController itself is reserving the rect.
		while ((value = [rectValuesEnumerator nextObject])) {	
			if ((NSIntersectsRect(inRect, [value rectValue])) && 
				(!displayController || (![[reservedRectsByController objectForKey:displayControllerValue] isEqual:value]))) {
				result = NO;
				break;
			}
		}
	}
	
	// Add the new rect if it passed the intersection test
	if (result) {
		[self clearReservedRectForDisplayController:displayController];
		[reservedRectsByController setObject:[NSValue valueWithRect:inRect]
									  forKey:displayControllerValue];
		[reservedRectsOfScreen addObject:newRectValue];
	}

	return result;
}

- (BOOL) reserveRect:(NSRect)inRect forDisplayController:(GrowlDisplayWindowController *)displayController {
	return [self reserveRect:inRect inScreen:[displayController screen] forDisplayController:displayController];
}

- (void) clearReservedRectForDisplayController:(GrowlDisplayWindowController *)displayController
{
	NSValue *controllerKey = [NSValue valueWithPointer:displayController];
	NSMutableSet *reservedRectsOfScreen = [self reservedRectsForScreen:[displayController screen]];
	NSValue *value = [reservedRectsByController objectForKey:controllerKey];

	if (value) {
		[reservedRectsOfScreen removeObject:value];
		[reservedRectsByController removeObjectForKey:controllerKey];
	}
}

/*!
 * @method copyRectsInSet:count:padding
 * @brief Returns a malloc'd array of NSRect structs which were contained as values in rectSet
 *
 * @param rectSet An NSSet which must contain only NSValues representing rects via -[NSValue rectValue]
 * @param outCount If non-NULL, on return will have the number of rects in the returned array
 * @param padding Padding to add to each returned rect in the rect array
 * @param displayController A display controller whose rect(s) should not be included. Pass nil to include all rects.
 * @result A malloc'd NSRectArray. This value should be freed after use.
 */
- (NSRectArray)copyRectsInSet:(NSSet *)rectSet count:(NSUInteger *)outCount padding:(CGFloat)padding excludingDisplayController:(GrowlDisplayWindowController *)displayController
{
	NSEnumerator *enumerator = [rectSet objectEnumerator];
	NSValue		 *value;
	NSValue		 *displayControllerValue = [NSValue valueWithPointer:displayController];
	NSUInteger	  count = [rectSet count];
	
	if (outCount) *outCount = count;

	NSRectArray gridRects = (NSRectArray)malloc(sizeof(NSRect) * count);
	int i = 0;
	while ((value = [enumerator nextObject])) {
		if (!displayController || (![[reservedRectsByController objectForKey:displayControllerValue] isEqual:value])) {
			gridRects[i++] = NSInsetRect([value rectValue], -padding, -padding);
		}
	}
	
	return gridRects;
}

//Returns the set of reserved rect for a specific screen. The return value *is* the storage!
- (NSMutableSet *)reservedRectsForScreen:(NSScreen *)screen {
	NSMutableSet *result = nil;

	//Treat nil as the main screen
	if (!screen)
		screen = [NSScreen mainScreen];

	//Get the set of reserved rects for our screen
	result = (NSMutableSet *)CFDictionaryGetValue(reservedRects, screen);

	//Make sure the set exists. If not, create it.
	if (!result) {
		result = [[NSMutableSet alloc] init];
		CFDictionarySetValue(reservedRects, screen, result);
		[result release];
	}

	return result;
}

- (enum GrowlPosition) originPosition {
	if (selectedPositionType == 1) {
		enum GrowlPosition translatedPosition;
		switch (selectedCustomPosition) {
			default:
			case GrowlNoOrigin:
				//Default to middle of the screen if no origin is set, though this case shouldn't be hit.
				translatedPosition = GrowlMiddleColumnPosition;
				break;
			case GrowlTopLeftCorner:
				translatedPosition = GrowlTopLeftPosition;
				break;
			case GrowlBottomRightCorner:
				translatedPosition = GrowlBottomRightPosition;
				break;
			case GrowlTopRightCorner:
				translatedPosition = GrowlTopRightPosition;
				break;
			case GrowlBottomLeftCorner:
				translatedPosition = GrowlBottomLeftPosition;
				break;
		}		
		return translatedPosition;
	}
	return [GrowlPositionController selectedOriginPosition];
}

@end

NSString *NSStringFromGrowlPosition(enum GrowlPosition pos) {
	NSString *str = nil;

	NSString *first;
	switch (pos) {
		case GrowlTopLeftPosition:
		case GrowlTopMiddlePosition:
		case GrowlTopRightPosition:
		case GrowlTopRowPosition:
			first = @"top";
			break;

		case GrowlCenterLeftPosition:
		case GrowlCenterMiddlePosition:
		case GrowlCenterRightPosition:
		case GrowlCenterRowPosition:
			first = @"center";
			break;

		case GrowlBottomLeftPosition:
		case GrowlBottomMiddlePosition:
		case GrowlBottomRightPosition:
		case GrowlBottomRowPosition:
			first = @"bottom";
			break;

		case GrowlLeftColumnPosition:
			first = @"left";
			break;

		case GrowlMiddleColumnPosition:
			first = @"middle";
			break;

		case GrowlRightColumnPosition:
			first = @"right";
			break;

		default:
			first = nil;
	};

	NSString *second;
	switch (pos) {
		case GrowlTopLeftPosition:
		case GrowlCenterLeftPosition:
		case GrowlBottomLeftPosition:
			second = @"left";
			break;

		case GrowlTopMiddlePosition:
		case GrowlBottomMiddlePosition:
			second = @"center";
			break;

		case GrowlCenterMiddlePosition:
			//just say 'center'
			second = @"";
			break;

		case GrowlTopRightPosition:
		case GrowlCenterRightPosition:
		case GrowlBottomRightPosition:
			second = @"right";
			break;

		case GrowlTopRowPosition:
		case GrowlCenterRowPosition:
		case GrowlBottomRowPosition:
			second = @"row";
			break;

		case GrowlLeftColumnPosition:
		case GrowlMiddleColumnPosition:
		case GrowlRightColumnPosition:
			second = @"column";
			break;
			
		default:
			second = nil;
	};

	if (first && second) {
		NSUInteger  firstLength = [first  length];
		NSUInteger secondLength = [second length];

		if (firstLength && secondLength) {
			NSUInteger capacity = firstLength + secondLength + 1U;
			NSMutableString *mutable = [[NSMutableString alloc] initWithCapacity:capacity];

			[mutable appendString:first];
			[mutable appendCharacter:'-'];
			[mutable appendString:second];

			str = [mutable autorelease];
		} else if (firstLength || secondLength) {
			str = firstLength ? first : second;
		}
	}

	return str;
}	

NSString *NSStringFromGrowlExpansionDirection(enum GrowlExpansionDirection dir) {
	switch (dir) {
		case GrowlNoExpansionDirection:
			return @"nowhere";
		case GrowlDownExpansionDirection:
			return @"down";
		case GrowlUpExpansionDirection:
			return @"up";
		case GrowlLeftExpansionDirection:
			return @"left";
		case GrowlRightExpansionDirection:
			return @"right";
		default:
			return nil;
	};
}
