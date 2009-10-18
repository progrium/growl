//
//  GrowlSmokeDisplay.h
//  Display Plugins
//
//  Created by Matthew Walton on 09/09/2004.
//  Copyright 2004-2006 The Growl Project. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GrowlDisplayPlugin.h"

@interface GrowlSmokeDisplay : GrowlDisplayPlugin {
}

- (void) configureBridge:(GrowlNotificationDisplayBridge *)theBridge;

@end
