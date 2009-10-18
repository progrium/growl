//
//	GrowlApplicationNotification.m
//	Growl
//
//	Created by Mac-arena the Bored Zo on 2005-07-31.
//	Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlApplicationNotification.h"
#import "GrowlDefines.h"

@implementation GrowlApplicationNotification

+ (GrowlApplicationNotification *) notificationWithDictionary:(NSDictionary *)dict {
	return [[[self alloc] initWithDictionary:dict] autorelease];
}

- (GrowlApplicationNotification *) initWithDictionary:(NSDictionary *)dict {
	if ((self = [self initWithName:[dict objectForKey:GROWL_NOTIFICATION_NAME]
				   applicationName:[dict objectForKey:GROWL_APP_NAME]
							 title:[dict objectForKey:GROWL_NOTIFICATION_TITLE]
					   description:[dict objectForKey:GROWL_NOTIFICATION_DESCRIPTION]])) {
		NSMutableDictionary *mutableDict = [dict mutableCopy];
		[mutableDict removeObjectsForKeys:[[GrowlApplicationNotification standardKeys] allObjects]];
		if ([mutableDict count])
			[self setAuxiliaryDictionary:mutableDict];
		[mutableDict release];
	}
	return self;
}

//you can pass nil for description.
- (GrowlApplicationNotification *) initWithName:(NSString *)newName
                                applicationName:(NSString *)newAppName
                                          title:(NSString *)newTitle
                                    description:(NSString *)newDesc
{
	if ((self = [self init])) {
		name            = [newName      copy];
		applicationName = [newAppName   copy];

		title           = [newTitle     copy];
		description     = [newDesc      copy];
	}
	return self;
}

- (void) dealloc {
	[name            release];
	[applicationName release];
	[title           release];
	[description     release];

	[dictionary          release];
	[auxiliaryDictionary release];

	[super dealloc];
}

#pragma mark -

+ (NSSet *) standardKeys {
	static NSSet *standardKeys = nil;

	if (!standardKeys) {
		standardKeys = [[NSSet alloc] initWithObjects:
			GROWL_NOTIFICATION_NAME,
			GROWL_APP_NAME,
			GROWL_NOTIFICATION_TITLE,
			GROWL_NOTIFICATION_DESCRIPTION,
			nil];
	}

	return standardKeys;
}

- (NSDictionary *) dictionaryRepresentation {
	return [self dictionaryRepresentationWithKeys:nil];
}
- (NSDictionary *) dictionaryRepresentationWithKeys:(NSSet *)keys {
	NSMutableDictionary *dict = nil;

	if (!keys) {
		//try cache first.
		if (dictionary)
			return [[dictionary retain] autorelease];

		//no joy - create it.
		dict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
			name,            GROWL_NOTIFICATION_NAME,
			applicationName, GROWL_APP_NAME,
			title,           GROWL_NOTIFICATION_TITLE,
			description,     GROWL_NOTIFICATION_DESCRIPTION,
			nil];

		NSEnumerator *auxKeyEnum = [auxiliaryDictionary keyEnumerator];
		id key;
		while ((key = [auxKeyEnum nextObject]))
			if (![dict objectForKey:key])
				[dict setObject:[auxiliaryDictionary objectForKey:key] forKey:key];
	} else {
		//only include keys in the set.
		dict = [[NSMutableDictionary alloc] initWithCapacity:[keys count]];

		if ([keys containsObject:GROWL_NOTIFICATION_NAME])
			[dict setObject:name forKey:GROWL_NOTIFICATION_NAME];
		if ([keys containsObject:GROWL_APP_NAME])
			[dict setObject:applicationName forKey:GROWL_APP_NAME];
		if ([keys containsObject:GROWL_NOTIFICATION_TITLE])
			[dict setObject:title forKey:GROWL_NOTIFICATION_TITLE];
		if ([keys containsObject:GROWL_NOTIFICATION_DESCRIPTION])
			[dict setObject:description forKey:GROWL_NOTIFICATION_DESCRIPTION];

		NSEnumerator *auxKeyEnum = [auxiliaryDictionary keyEnumerator];
		id key;
		while ((key = [auxKeyEnum nextObject]))
			if ([keys containsObject:key] && ![dict objectForKey:key])
				[dict setObject:[auxiliaryDictionary objectForKey:key] forKey:key];
	}

	NSDictionary *result = [NSDictionary dictionaryWithDictionary:dict];
	[dict release];

	if (!keys) {
		//update our cache.
		[dictionary release];
		 dictionary = nil;

		dictionary = [result retain];
	}

	return result;
}

#pragma mark -

- (NSString *) name {
	return name;
}
- (NSString *) applicationName {
	return applicationName;
}

- (NSString *) title {
	return title;
}
- (NSAttributedString *) attributedTitle {
	return [[[NSAttributedString alloc] initWithString:title] autorelease];
}

- (NSString *) notificationDescription {
	return description;
}
- (NSAttributedString *) attributedDescription {
	return [[[NSAttributedString alloc] initWithString:[self notificationDescription]] autorelease];
}

- (NSDictionary *) auxiliaryDictionary {
	return auxiliaryDictionary;
}
- (void) setAuxiliaryDictionary:(NSDictionary *)newAuxDict {
	[auxiliaryDictionary release];
	 auxiliaryDictionary = [newAuxDict copy];

	/*-dictionaryRepresentationWithKeys:nil depends on the auxiliary dictionary.
	 *so if the auxiliary dictionary changes, we must dirty the cache used by
	 *	-dictionaryRepresentation.
	 */
	[dictionary release];
	 dictionary = nil;
}

@end
