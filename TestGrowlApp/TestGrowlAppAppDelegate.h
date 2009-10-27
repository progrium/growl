//
//  TestGrowlAppAppDelegate.h
//  TestGrowlApp
//
//  Created by awixted on 10/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>

@interface TestGrowlAppAppDelegate : NSObject < GrowlApplicationBridgeDelegate> {
    NSWindow *window;
	NSURLConnection *notifyConn;
	NSURLConnection *iconConn;
	
	NSDictionary *growlData;
	
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, retain) NSDictionary *growlData;

@end


