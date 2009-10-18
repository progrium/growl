//
//  GrowlPlugin.m
//  Growl
//
//  Created by Mac-arena the Bored Zo on 2005-06-01.
//  Copyright 2005-2006 The Growl Project. All rights reserved.
//

#import "GrowlPlugin.h"


@interface GrowlPlugin (PRIVATE)
- (void) setDescription:(NSString *)newDesc;
@end


@implementation GrowlPlugin

//designated initialiser.
- (id) initWithName:(NSString *)name author:(NSString *)author version:(NSString *)version pathname:(NSString *)pathname {
	if ((self = [super init])) {
		pluginName     = [name     copy];
		pluginAuthor   = [author   copy];
		pluginVersion  = [version  copy];
		pluginPathname = [pathname copy];
		prefDomain     = nil;
	}
	return self;
}
/*use this initialiser for plug-ins in bundles. the name, author, version, and
 *	pathname will be obtained from the bundle.
 */
- (id) initWithBundle:(NSBundle *)bundle {
	NSDictionary *infoDict = [bundle infoDictionary];
	self = [self initWithName:[infoDict objectForKey:(NSString *)kCFBundleNameKey]
					   author:[infoDict objectForKey:@"GrowlPluginAuthor"]
					  version:[infoDict objectForKey:(NSString *)kCFBundleVersionKey]
					 pathname:[bundle bundlePath]];
	if (self) {
		[self setDescription:[infoDict objectForKey:@"GrowlPluginDescription"]];
		pluginBundle = [bundle retain];
	}
	return self;
}

- (id) init {
	return [self initWithBundle:[NSBundle bundleForClass:[self class]]];
}

- (void) dealloc {
	[pluginName release];
	[pluginAuthor release];
	[pluginVersion release];
	[pluginDesc release];

	[pluginBundle release];
	[pluginPathname release];

	[prefDomain release];

	[super dealloc];
}

#pragma mark -

- (NSString *) name {
	return pluginName;
}
- (NSString *) author {
	return pluginAuthor;
}
- (NSString *) version {
	return pluginVersion;
}
- (NSString *) pluginDescription {
	return pluginDesc;
}
- (void) setDescription:(NSString *)newDesc {
	[pluginDesc release];
	pluginDesc = [newDesc copy];
}

- (NSBundle *) bundle {
	return pluginBundle;
}
- (NSString *) pathname {
	return pluginPathname;
}

#pragma mark -

- (NSString *) prefDomain {
    return prefDomain;
}

- (NSPreferencePane *) preferencePane {
	return preferencePane;
}

@end
