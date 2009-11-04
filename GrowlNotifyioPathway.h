//
//  GrowlNotifyioPathway.h
//  Growl
//
//  Created by awixted on 10/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "GrowlRemotePathway.h"


@interface GrowlNotifyioPathway : GrowlRemotePathway {
	NSURLConnection *notifyConn;
	NSURLConnection *iconConn;
	
	NSMutableDictionary *messageData;
}


@property (nonatomic, retain) NSMutableDictionary *messageData;

@end
