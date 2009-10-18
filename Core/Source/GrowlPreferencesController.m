//
//  GrowlPreferencesController.m
//  Growl
//
//  Created by Nelson Elhage on 8/24/04.
//  Renamed from GrowlPreferences.m by Mac-arena the Bored Zo on 2005-06-27.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details


#import "GrowlPreferencesController.h"
#import "GrowlDefinesInternal.h"
#import "GrowlDefines.h"
#import "GrowlPathUtilities.h"
#import "NSStringAdditions.h"
#include "CFURLAdditions.h"
#include "CFDictionaryAdditions.h"
#include <Security/SecKeychain.h>
#include <Security/SecKeychainItem.h>

#define keychainServiceName "Growl"
#define keychainAccountName "Growl"

CFTypeRef GrowlPreferencesController_objectForKey(CFTypeRef key) {
	return [[GrowlPreferencesController sharedController] objectForKey:(id)key];
}

CFIndex GrowlPreferencesController_integerForKey(CFTypeRef key) {
	Boolean keyExistsAndHasValidFormat;
	return CFPreferencesGetAppIntegerValue((CFStringRef)key, (CFStringRef)GROWL_HELPERAPP_BUNDLE_IDENTIFIER, &keyExistsAndHasValidFormat);
}

Boolean GrowlPreferencesController_boolForKey(CFTypeRef key) {
	Boolean keyExistsAndHasValidFormat;
	return CFPreferencesGetAppBooleanValue((CFStringRef)key, (CFStringRef)GROWL_HELPERAPP_BUNDLE_IDENTIFIER, &keyExistsAndHasValidFormat);
}

unsigned short GrowlPreferencesController_unsignedShortForKey(CFTypeRef key)
{
	CFIndex theIndex = GrowlPreferencesController_integerForKey(key);
	
	if (theIndex > USHRT_MAX)
		return USHRT_MAX;
	else if (theIndex < 0)
		return 0;
	return (unsigned short)theIndex;
}

@implementation GrowlPreferencesController

+ (GrowlPreferencesController *) sharedController {
	return [self sharedInstance];
}

- (id) initSingleton {
	if ((self = [super initSingleton])) {
		[[NSDistributedNotificationCenter defaultCenter] addObserver:self
															selector:@selector(growlPreferencesChanged:)
																name:GrowlPreferencesChanged
															  object:nil];
		loginItems = LSSharedFileListCreate(kCFAllocatorDefault, kLSSharedFileListSessionLoginItems, /*options*/ NULL);
	}
	return self;
}

- (void) destroy {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	CFRelease(loginItems);

	[super destroy];
}

#pragma mark -

- (void) registerDefaults:(NSDictionary *)inDefaults {
	NSUserDefaults *helperAppDefaults = [[NSUserDefaults alloc] init];
	[helperAppDefaults addSuiteNamed:GROWL_HELPERAPP_BUNDLE_IDENTIFIER];
	NSDictionary *existing = [helperAppDefaults persistentDomainForName:GROWL_HELPERAPP_BUNDLE_IDENTIFIER];
	if (existing) {
		NSMutableDictionary *domain = [inDefaults mutableCopy];
		[domain addEntriesFromDictionary:existing];
		[helperAppDefaults setPersistentDomain:domain forName:GROWL_HELPERAPP_BUNDLE_IDENTIFIER];
		[domain release];
	} else {
		[helperAppDefaults setPersistentDomain:inDefaults forName:GROWL_HELPERAPP_BUNDLE_IDENTIFIER];
	}
	[helperAppDefaults release];
	SYNCHRONIZE_GROWL_PREFS();
}

- (id) objectForKey:(NSString *)key {
	id value = (id)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)GROWL_HELPERAPP_BUNDLE_IDENTIFIER);
	if(value)
		CFMakeCollectable(value);
	return [value autorelease];
}

- (void) setObject:(id)object forKey:(NSString *)key {
	CFPreferencesSetAppValue((CFStringRef)key,
							 (CFPropertyListRef)object,
							 (CFStringRef)GROWL_HELPERAPP_BUNDLE_IDENTIFIER);

	SYNCHRONIZE_GROWL_PREFS();

	int pid = getpid();
	CFNumberRef pidValue = CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &pid);
	CFStringRef pidKey = CFSTR("pid");
	CFDictionaryRef userInfo = CFDictionaryCreate(kCFAllocatorDefault, (const void **)&pidKey, (const void **)&pidValue, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	CFRelease(pidValue);
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
										 (CFStringRef)GrowlPreferencesChanged,
										 /*object*/ key,
										 /*userInfo*/ userInfo,
										 /*deliverImmediately*/ false);
	CFRelease(userInfo);
}

- (BOOL) boolForKey:(NSString *)key {
	return GrowlPreferencesController_boolForKey((CFTypeRef)key);
}

- (void) setBool:(BOOL)value forKey:(NSString *)key {
	NSNumber *object = [[NSNumber alloc] initWithBool:value];
	[self setObject:object forKey:key];
	[object release];
}

- (CFIndex) integerForKey:(NSString *)key {
	return GrowlPreferencesController_integerForKey((CFTypeRef)key);
}

- (void) setInteger:(CFIndex)value forKey:(NSString *)key {
#ifdef __LP64__
	NSNumber *object = [[NSNumber alloc] initWithInteger:value];
#else
	NSNumber *object = [[NSNumber alloc] initWithInt:value];
#endif
	[self setObject:object forKey:key];
	[object release];
}

- (unsigned short)unsignedShortForKey:(NSString *)key
{
	return GrowlPreferencesController_unsignedShortForKey((CFTypeRef)key);
}


- (void)setUnsignedShort:(unsigned short)theShort forKey:(NSString *)key
{
	[self setObject:[NSNumber numberWithUnsignedShort:theShort] forKey:key];
}

- (void) synchronize {
	SYNCHRONIZE_GROWL_PREFS();
}

#pragma mark -
#pragma mark Start-at-login control

- (BOOL) shouldStartGrowlAtLogin {
	Boolean    foundIt = false;

	//get the prefpane bundle and find GHA within it.
	NSBundle *prefPaneBundle = [NSBundle bundleWithIdentifier:GROWL_PREFPANE_BUNDLE_IDENTIFIER];
	NSString *pathToGHA      = [prefPaneBundle pathForResource:@"GrowlHelperApp" ofType:@"app"];
	if(pathToGHA) {
		//get the file url to GHA.
		CFURLRef urlToGHA = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)pathToGHA, kCFURLPOSIXPathStyle, true);
		
		UInt32 seed = 0U;
		NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
		for (id itemObject in currentLoginItems) {
			LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;
			
			UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
			CFURLRef URL = NULL;
			OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
			if (err == noErr) {
				foundIt = CFEqual(URL, urlToGHA);
				CFRelease(URL);
				
				if (foundIt)
					break;
			}
		}
		
		CFRelease(urlToGHA);
	}
	else {
		NSLog(@"Growl: your install is corrupt, you will need to reinstall\nyour prefpane bundle is:%@\n your pathToGHA is:%@", prefPaneBundle, pathToGHA);
	}
	
	return foundIt;
}

- (void) setShouldStartGrowlAtLogin:(BOOL)flag {
	//get the prefpane bundle and find GHA within it.
	NSString *pathToGHA = [[NSBundle bundleWithIdentifier:GROWL_PREFPANE_BUNDLE_IDENTIFIER] pathForResource:@"GrowlHelperApp" ofType:@"app"];
	[self setStartAtLogin:pathToGHA enabled:flag];
}

- (void) setStartAtLogin:(NSString *)path enabled:(BOOL)enabled {
	OSStatus status;
	CFURLRef URLToToggle = (CFURLRef)[NSURL fileURLWithPath:path];
	LSSharedFileListItemRef existingItem = NULL;

	UInt32 seed = 0U;
	NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
	for (id itemObject in currentLoginItems) {
		LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;

		UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
		CFURLRef URL = NULL;
		OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
		if (err == noErr) {
			Boolean foundIt = CFEqual(URL, URLToToggle);
			CFRelease(URL);

			if (foundIt) {
				existingItem = item;
				break;
			}
		}
	}

	if (enabled && (existingItem == NULL)) {
		NSString *displayName = [[NSFileManager defaultManager] displayNameAtPath:path];
		IconRef icon = NULL;
		FSRef ref;
		Boolean gotRef = CFURLGetFSRef(URLToToggle, &ref);
		if (gotRef) {
			status = GetIconRefFromFileInfo(&ref,
											/*fileNameLength*/ 0, /*fileName*/ NULL,
											kFSCatInfoNone, /*catalogInfo*/ NULL,
											kIconServicesNormalUsageFlag,
											&icon,
											/*outLabel*/ NULL);
			if (status != noErr)
				icon = NULL;
		}

		LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst, (CFStringRef)displayName, icon, URLToToggle, /*propertiesToSet*/ NULL, /*propertiesToClear*/ NULL);
	} else if (!enabled && (existingItem != NULL))
		LSSharedFileListItemRemove(loginItems, existingItem);
}

#pragma mark -
#pragma mark GrowlMenu running state

- (void) enableGrowlMenu {
	NSBundle *bundle = [NSBundle bundleForClass:[GrowlPreferencesController class]];
	NSString *growlMenuPath = [bundle pathForResource:@"GrowlMenu" ofType:@"app"];
	NSURL *growlMenuURL = [NSURL fileURLWithPath:growlMenuPath];
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:growlMenuURL]
	                withAppBundleIdentifier:nil
	                                options:NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync
	         additionalEventParamDescriptor:nil
	                      launchIdentifiers:NULL];
}

- (void) disableGrowlMenu {
	// Ask GrowlMenu to shutdown via the DNC
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
										 CFSTR("GrowlMenuShutdown"),
										 /*object*/ NULL,
										 /*userInfo*/ NULL,
										 /*deliverImmediately*/ false);
}

#pragma mark -
#pragma mark Growl running state

- (void) setGrowlRunning:(BOOL)flag noMatterWhat:(BOOL)nmw {
	// Store the desired running-state of the helper app for use by GHA.
	[self setBool:flag forKey:GrowlEnabledKey];

	//now launch or terminate as appropriate.
	if (flag)
		[self launchGrowl:nmw];
	else
		[self terminateGrowl];
}

- (BOOL) isRunning:(NSString *)theBundleIdentifier {
	BOOL isRunning = NO;
	ProcessSerialNumber PSN = { kNoProcess, kNoProcess };

	while (GetNextProcess(&PSN) == noErr) {
		NSDictionary *infoDict = (NSDictionary *)ProcessInformationCopyDictionary(&PSN, kProcessDictionaryIncludeAllInformationMask);
		if(infoDict) {
			NSString *bundleID = [infoDict objectForKey:(NSString *)kCFBundleIdentifierKey];
			isRunning = bundleID && [bundleID isEqualToString:theBundleIdentifier];
			CFMakeCollectable(infoDict);
			[infoDict release];
		}
		if (isRunning)
			break;
	}

	return isRunning;
}

- (BOOL) isGrowlRunning {
	return [self isRunning:@"com.Growl.GrowlHelperApp"];
}

- (void) launchGrowl:(BOOL)noMatterWhat {
	NSString *helperPath = [[GrowlPathUtilities helperAppBundle] bundlePath];
	NSURL *helperURL = [NSURL fileURLWithPath:helperPath];

	unsigned options = NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync;
	if (noMatterWhat)
		options |= NSWorkspaceLaunchNewInstance;
	[[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:helperURL]
	                withAppBundleIdentifier:nil
	                                options:options
	         additionalEventParamDescriptor:nil
	                      launchIdentifiers:NULL];
}

- (void) terminateGrowl {
	// Ask the Growl Helper App to shutdown via the DNC
	CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(),
										 (CFStringRef)GROWL_SHUTDOWN,
										 /*object*/ NULL,
										 /*userInfo*/ NULL,
										 /*deliverImmediately*/ false);
}

#pragma mark -
//Simplified accessors

#pragma mark UI

- (CFIndex)selectedPosition {
	return [self integerForKey:GROWL_POSITION_PREFERENCE_KEY];
}

- (BOOL) isBackgroundUpdateCheckEnabled {
	return [self boolForKey:GrowlUpdateCheckKey];
}
- (void) setIsBackgroundUpdateCheckEnabled:(BOOL)flag {
	[self setBool:flag forKey:GrowlUpdateCheckKey];
}

- (NSString *) defaultDisplayPluginName {
	return [self objectForKey:GrowlDisplayPluginKey];
}
- (void) setDefaultDisplayPluginName:(NSString *)name {
	[self setObject:name forKey:GrowlDisplayPluginKey];
}

- (BOOL) squelchMode {
	return [self boolForKey:GrowlSquelchModeKey];
}
- (void) setSquelchMode:(BOOL)flag {
	[self setBool:flag forKey:GrowlSquelchModeKey];
}

- (BOOL) stickyWhenAway {
	return [self boolForKey:GrowlStickyWhenAwayKey];
}
- (void) setStickyWhenAway:(BOOL)flag {
	[self setBool:flag forKey:GrowlStickyWhenAwayKey];
}

- (NSNumber*) idleThreshold {
#ifdef __LP64__
	return [NSNumber numberWithInteger:[self integerForKey:GrowlStickyIdleThresholdKey]];
#else
	return [NSNumber numberWithInt:[self integerForKey:GrowlStickyIdleThresholdKey]];
#endif
}

- (void) setIdleThreshold:(NSNumber*)value {
	[self setInteger:[value intValue] forKey:GrowlStickyIdleThresholdKey];
}
#pragma mark Status Item

- (BOOL) isGrowlMenuEnabled {
	return [self boolForKey:GrowlMenuExtraKey];
}

- (void) setGrowlMenuEnabled:(BOOL)state {
	if (state != [self isGrowlMenuEnabled]) {
		[self setBool:state forKey:GrowlMenuExtraKey];
		if (state)
			[self enableGrowlMenu];
		else
			[self disableGrowlMenu];
	}
}

#pragma mark Logging

- (BOOL) loggingEnabled {
	return [self boolForKey:GrowlLoggingEnabledKey];
}

- (void) setLoggingEnabled:(BOOL)flag {
	[self setBool:flag forKey:GrowlLoggingEnabledKey];
}

- (BOOL) isGrowlServerEnabled {
	return [self boolForKey:GrowlStartServerKey];
}

- (void) setGrowlServerEnabled:(BOOL)enabled {
	[self setBool:enabled forKey:GrowlStartServerKey];
}

#pragma mark Remote Growling

- (BOOL) isRemoteRegistrationAllowed {
	return [self boolForKey:GrowlRemoteRegistrationKey];
}

- (void) setRemoteRegistrationAllowed:(BOOL)flag {
	[self setBool:flag forKey:GrowlRemoteRegistrationKey];
}

- (NSString *) remotePassword {
	unsigned char *password;
	UInt32 passwordLength;
	OSStatus status;
	status = SecKeychainFindGenericPassword(NULL,
											(UInt32)strlen(keychainServiceName), keychainServiceName,
											(UInt32)strlen(keychainAccountName), keychainAccountName,
											&passwordLength, (void **)&password, NULL);

	NSString *passwordString;
	if (status == noErr) {
		passwordString = (NSString *)CFStringCreateWithBytes(kCFAllocatorDefault, password, passwordLength, kCFStringEncodingUTF8, false);
		if(passwordString) {
			CFMakeCollectable(passwordString);
			[passwordString autorelease];
			SecKeychainItemFreeContent(NULL, password);
		}
	} else {
		if (status != errSecItemNotFound)
			NSLog(@"Failed to retrieve password from keychain. Error: %d", status);
		passwordString = @"";
	}

	return passwordString;
}

- (void) setRemotePassword:(NSString *)value {
	const char *password = value ? [value UTF8String] : "";
	size_t length = strlen(password);
	OSStatus status;
	SecKeychainItemRef itemRef = nil;
	status = SecKeychainFindGenericPassword(NULL,
											(UInt32)strlen(keychainServiceName), keychainServiceName,
											(UInt32)strlen(keychainAccountName), keychainAccountName,
											NULL, NULL, &itemRef);
	if (status == errSecItemNotFound) {
		// add new item
		status = SecKeychainAddGenericPassword(NULL,
											   (UInt32)strlen(keychainServiceName), keychainServiceName,
											   (UInt32)strlen(keychainAccountName), keychainAccountName,
											   (UInt32)length, password, NULL);
		if (status)
			NSLog(@"Failed to add password to keychain.");
	} else {
		// change existing password
		SecKeychainAttribute attrs[] = {
			{ kSecAccountItemAttr, (UInt32)strlen(keychainAccountName), (char *)keychainAccountName },
			{ kSecServiceItemAttr, (UInt32)strlen(keychainServiceName), (char *)keychainServiceName }
		};
		const SecKeychainAttributeList attributes = { (UInt32)sizeof(attrs) / (UInt32)sizeof(attrs[0]), attrs };
		status = SecKeychainItemModifyAttributesAndData(itemRef,		// the item reference
														&attributes,	// no change to attributes
														(UInt32)length,			// length of password
														password		// pointer to password data
														);
		if (itemRef)
			CFRelease(itemRef);
		if (status)
			NSLog(@"Failed to change password in keychain.");
	}
}

- (unsigned short) UDPPort {
	return [self unsignedShortForKey:GrowlUDPPortKey];
}
- (void) setUDPPort:(unsigned short)value {
	[self setUnsignedShort:value forKey:GrowlUDPPortKey];
}

- (BOOL) isForwardingEnabled {
	return [self boolForKey:GrowlEnableForwardKey];
}
- (void) setForwardingEnabled:(BOOL)enabled {
	[self setBool:enabled forKey:GrowlEnableForwardKey];
}

#pragma mark -
/*
 * @brief Growl preferences changed
 *
 * Synchronize our NSUserDefaults to immediately get any changes from the disk
 */
- (void) growlPreferencesChanged:(NSNotification *)notification {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSString *object = [notification object];
//	NSLog(@"%s: %@\n", __func__, object);
	SYNCHRONIZE_GROWL_PREFS();
	if (!object || [object isEqualToString:GrowlDisplayPluginKey]) {
		[self willChangeValueForKey:@"defaultDisplayPluginName"];
		[self didChangeValueForKey:@"defaultDisplayPluginName"];
	}
	if (!object || [object isEqualToString:GrowlSquelchModeKey]) {
		[self willChangeValueForKey:@"squelchMode"];
		[self didChangeValueForKey:@"squelchMode"];
	}
	if (!object || [object isEqualToString:GrowlMenuExtraKey]) {
		[self willChangeValueForKey:@"growlMenuEnabled"];
		[self didChangeValueForKey:@"growlMenuEnabled"];
	}
	if (!object || [object isEqualToString:GrowlEnableForwardKey]) {
		[self willChangeValueForKey:@"forwardingEnabled"];
		[self didChangeValueForKey:@"forwardingEnabled"];
	}
	if (!object || [object isEqualToString:GrowlUpdateCheckKey]) {
		[self willChangeValueForKey:@"backgroundUpdateCheckEnabled"];
		[self didChangeValueForKey:@"backgroundUpdateCheckEnabled"];
	}
	if (!object || [object isEqualToString:GrowlStickyWhenAwayKey]) {
		[self willChangeValueForKey:@"stickyWhenAway"];
		[self didChangeValueForKey:@"stickyWhenAway"];
	}
	if (!object || [object isEqualToString:GrowlStickyIdleThresholdKey]) {
		[self willChangeValueForKey:@"idleThreshold"];
		[self didChangeValueForKey:@"idleThreshold"];
	}
	if (!object || [object isEqualToString:GrowlRemoteRegistrationKey]) {
		[self willChangeValueForKey:@"remoteRegistrationAllowed"];
		[self didChangeValueForKey:@"remoteRegistrationAllowed"];
	}
	
	[pool release];
}

@end
