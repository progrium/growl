//
//  GrowlUDPServer.h
//  Growl
//
//  Created by Ingmar Stein on 18.11.04.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//
// This file is under the BSD License, refer to License.txt for details

#import <Foundation/Foundation.h>
#import "GrowlRemotePathway.h"

@interface GrowlUDPPathway: GrowlRemotePathway {
	CFSocketRef cfSocket;
	NSImage     *notificationIcon;
}

- (NSImage *) notificationIcon;
@end
