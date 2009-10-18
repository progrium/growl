//
//  GrowlMusicVideoPrefs.m
//  Display Plugins
//
//  Created by Jorge Salvador Caffarena on 14/09/04.
//  Copyright 2004 Jorge Salvador Caffarena. All rights reserved.
//

#import "GrowlMusicVideoPrefs.h"
#import "GrowlDefinesInternal.h"

@implementation GrowlMusicVideoPrefs

- (NSString *) mainNibName {
	return @"GrowlMusicVideoPrefs";
}

- (void) mainViewDidLoad {
	[slider_opacity setAltIncrementValue:5.0];
}

- (void) didSelect {
	SYNCHRONIZE_GROWL_PREFS();
}

#pragma mark -

+ (NSColor *) loadColor:(NSString *)key defaultColor:(NSColor *)defaultColor {
	NSData *data = nil;
	NSColor *color;
	READ_GROWL_PREF_VALUE(key, GrowlMusicVideoPrefDomain, NSData *, &data);
	if(data)
		CFMakeCollectable(data);
	
	if (data && [data isKindOfClass:[NSData class]]) {
		color = [NSUnarchiver unarchiveObjectWithData:data];
	} else {
		color = defaultColor;
	}
	[data release];

	return color;
}

#pragma mark Accessors

- (CGFloat) duration {
	CGFloat value = GrowlMusicVideoDurationPrefDefault;
	READ_GROWL_PREF_FLOAT(MUSICVIDEO_DURATION_PREF, GrowlMusicVideoPrefDomain, &value);
	return value;
}
- (void) setDuration:(CGFloat)value {
	WRITE_GROWL_PREF_FLOAT(MUSICVIDEO_DURATION_PREF, value, GrowlMusicVideoPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (unsigned) effect {
	int effect = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_EFFECT_PREF, GrowlMusicVideoPrefDomain, &effect);
	switch (effect) {
		default:
			effect = MUSICVIDEO_EFFECT_SLIDE;
			
		case MUSICVIDEO_EFFECT_SLIDE:
		case MUSICVIDEO_EFFECT_WIPE:
		case MUSICVIDEO_EFFECT_FADING:
			;
		
	}
	return (unsigned)effect;
}
- (void) setEffect:(unsigned)newEffect {
	switch (newEffect) {
		default:
			NSLog(@"(Music Video) Invalid effect number %u (slide is %u; wipe is %u)", newEffect, MUSICVIDEO_EFFECT_SLIDE, MUSICVIDEO_EFFECT_WIPE);
			break;

		case MUSICVIDEO_EFFECT_SLIDE:
		case MUSICVIDEO_EFFECT_WIPE:
		case MUSICVIDEO_EFFECT_FADING:
			WRITE_GROWL_PREF_INT(MUSICVIDEO_EFFECT_PREF, newEffect, GrowlMusicVideoPrefDomain);
			UPDATE_GROWL_PREFS();
	}
}

- (CGFloat) opacity {
	CGFloat value = MUSICVIDEO_DEFAULT_OPACITY;
	READ_GROWL_PREF_FLOAT(MUSICVIDEO_OPACITY_PREF, GrowlMusicVideoPrefDomain, &value);
	return value;
}
- (void) setOpacity:(CGFloat)value {
	WRITE_GROWL_PREF_FLOAT(MUSICVIDEO_OPACITY_PREF, value, GrowlMusicVideoPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (int) size {
	int value = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, GrowlMusicVideoPrefDomain, &value);
	return value;
}
- (void) setSize:(int)value {
	WRITE_GROWL_PREF_INT(MUSICVIDEO_SIZE_PREF, value, GrowlMusicVideoPrefDomain);
	UPDATE_GROWL_PREFS();
}

#pragma mark Combo box support

- (NSInteger) numberOfItemsInComboBox:(NSComboBox *)aComboBox {
#pragma unused(aComboBox)
	return [[NSScreen screens] count];
}

- (id) comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)idx {
#pragma unused(aComboBox)
#ifdef __LP64__
	return [NSNumber numberWithInteger:idx];
#else
	return [NSNumber numberWithInt:idx];
#endif
}

- (int) screen {
	int value = 0;
	READ_GROWL_PREF_INT(MUSICVIDEO_SCREEN_PREF, GrowlMusicVideoPrefDomain, &value);
	return value;
}
- (void) setScreen:(int)value {
	WRITE_GROWL_PREF_INT(MUSICVIDEO_SCREEN_PREF, value, GrowlMusicVideoPrefDomain);
	UPDATE_GROWL_PREFS();
}

- (NSColor *) textColorVeryLow {
	return [GrowlMusicVideoPrefs loadColor:GrowlMusicVideoVeryLowTextColor
							  defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorVeryLow:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlMusicVideoVeryLowTextColor, theData, GrowlMusicVideoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) textColorModerate {
	return [GrowlMusicVideoPrefs loadColor:GrowlMusicVideoModerateTextColor
							  defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorModerate:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlMusicVideoModerateTextColor, theData, GrowlMusicVideoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) textColorNormal {
	return [GrowlMusicVideoPrefs loadColor:GrowlMusicVideoNormalTextColor
							  defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorNormal:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlMusicVideoNormalTextColor, theData, GrowlMusicVideoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) textColorHigh {
	return [GrowlMusicVideoPrefs loadColor:GrowlMusicVideoHighTextColor
							  defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorHigh:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlMusicVideoHighTextColor, theData, GrowlMusicVideoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) textColorEmergency {
	return [GrowlMusicVideoPrefs loadColor:GrowlMusicVideoEmergencyTextColor
							  defaultColor:[NSColor whiteColor]];
}

- (void) setTextColorEmergency:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlMusicVideoEmergencyTextColor, theData, GrowlMusicVideoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) backgroundColorVeryLow {
	return [GrowlMusicVideoPrefs loadColor:GrowlMusicVideoVeryLowBackgroundColor
							  defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorVeryLow:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlMusicVideoVeryLowBackgroundColor, theData, GrowlMusicVideoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) backgroundColorModerate {
	return [GrowlMusicVideoPrefs loadColor:GrowlMusicVideoModerateBackgroundColor
							  defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorModerate:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlMusicVideoModerateBackgroundColor, theData, GrowlMusicVideoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) backgroundColorNormal {
	return [GrowlMusicVideoPrefs loadColor:GrowlMusicVideoNormalBackgroundColor
						 defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorNormal:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlMusicVideoNormalBackgroundColor, theData, GrowlMusicVideoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) backgroundColorHigh {
	return [GrowlMusicVideoPrefs loadColor:GrowlMusicVideoHighBackgroundColor
							  defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorHigh:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlMusicVideoHighBackgroundColor, theData, GrowlMusicVideoPrefDomain);
    UPDATE_GROWL_PREFS();
}

- (NSColor *) backgroundColorEmergency {
	return [GrowlMusicVideoPrefs loadColor:GrowlMusicVideoEmergencyBackgroundColor
							  defaultColor:[NSColor blackColor]];
}

- (void) setBackgroundColorEmergency:(NSColor *)value {
	NSData *theData = [NSArchiver archivedDataWithRootObject:value];
    WRITE_GROWL_PREF_VALUE(GrowlMusicVideoEmergencyBackgroundColor, theData, GrowlMusicVideoPrefDomain);
    UPDATE_GROWL_PREFS();
}
@end
