//
//  GrowlLog.h
//  Growl
//
//  Created by Ingmar Stein on 17.04.05.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#ifndef GROWL_LOG_H
#define GROWL_LOG_H

#include <CoreFoundation/CoreFoundation.h>
#include "CFGrowlAdditions.h"

void GrowlLog_log(STRING_TYPE format, ...);
void GrowlLog_logNotificationDictionary(DICTIONARY_TYPE noteDict);
void GrowlLog_logRegistrationDictionary(DICTIONARY_TYPE regDict);

#ifdef __OBJC__

@interface GrowlLog: NSObject
{
}

+ (GrowlLog *) sharedController;

- (void) writeToLog:(NSString *)format, ...;
- (void) writeToLog:(NSString *)format withArguments:(va_list)args;

- (void) writeNotificationDictionaryToLog:(NSDictionary *)noteDict;
- (void) writeRegistrationDictionaryToLog:(NSDictionary *)regDict;

@end

#endif //__OBJC__

#endif
