//
//  TestGrowlAppAppDelegate.m
//  TestGrowlApp
//
//  Created by awixted on 10/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TestGrowlAppAppDelegate.h"
#import "JSON.h"

@interface TestGrowlAppAppDelegate ()
// Private methods
- (void)initRemoteHost:(NSString *)path;
@end



@implementation TestGrowlAppAppDelegate

@synthesize window, growlData;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	
	NSLog(@"did finish launching");
	
	
	NSBundle *myBundle = [NSBundle bundleForClass:[self class]];
	NSString *growlPath = [[myBundle privateFrameworksPath]
						   stringByAppendingPathComponent:@"Growl.framework"];
	NSBundle *growlBundle = [NSBundle bundleWithPath:growlPath];
	if ([growlBundle load]) {
		// Register ourselves as a Growl delegate
		[GrowlApplicationBridge setGrowlDelegate:self];
		NSLog(@"loaded, bitches");
	} else {
		NSLog(@"Could not load Growl.framework");
	}
	NSLog(@"about to initRemoteHost");
	[self initRemoteHost:nil];
	
}


- (void)initRemoteHost:(NSString *)path
{
	NSString *filepath = [NSString stringWithFormat:@"%@/.growlURL", NSHomeDirectory()];
	NSError *error;
	NSString *stringFromFileAtPath = [[NSString alloc]
                                      initWithContentsOfFile:filepath
                                      encoding:NSASCIIStringEncoding
                                      error:&error];
	NSLog(@"contents of file: %@", stringFromFileAtPath);

	if([stringFromFileAtPath length] == 0)
	{
		NSLog(@"the file at path %@ is empty", filepath);
		return;
	}
	
	NSString *urlString = [stringFromFileAtPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	
	NSURL *url = [NSURL URLWithString:urlString];
	[stringFromFileAtPath release];

	
	
	NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
	//[urlRequest setValue:@"notify-io-client" forHTTPHeaderField:@"user-agent"];
	
	notifyConn = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES];

}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"did fail with error: %@", error);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"received");
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if([connection isEqualTo:notifyConn])
	{
			
		NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSLog(@"data: %@", string);
		
		// Parse the json
		SBJSON *jsonParser = [[SBJSON alloc] init];
		
		// Keep the data in case we need it to stick around because we won't be posting the growl notif
		// until we get the icon
		
		self.growlData = [jsonParser objectWithString:string];
		
		// Get the icon from the json data
		NSString *iconURLStr = [growlData objectForKey:@"icon"];
		if(!iconURLStr)
		{
			
			[GrowlApplicationBridge notifyWithTitle:[growlData objectForKey:@"title"] 
										description:[growlData objectForKey:@"text"] 
								   notificationName:@"name1" 
										   iconData:nil 
										   priority:1 
										   isSticky:[[growlData objectForKey:@"sticky"] isEqualToString:@"true"] 
									   clickContext:[growlData objectForKey:@"link"]];
			
			self.growlData = nil;
		}
		else {
			// Get the icon from the url
			
			NSURL *url = [NSURL URLWithString:iconURLStr];
			
			NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
						
			iconConn = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES];
		}

	}
	else if([connection isEqualTo:iconConn])
	{
		// Make an image out of the received data
		NSImage *image = [[NSImage alloc] initWithData:data];
		
		
		[GrowlApplicationBridge notifyWithTitle:[growlData objectForKey:@"title"] 
									description:[growlData objectForKey:@"text"] 
							   notificationName:@"name1" 
									   iconData:[image TIFFRepresentation]
									   priority:1 
									   isSticky:[[growlData objectForKey:@"sticky"] isEqualToString:@"true"]
								   clickContext:[growlData objectForKey:@"link"]];
		
		[iconConn release];
		iconConn = nil;
		self.growlData = nil;
	}
}




#pragma mark GrowlApplicationBridgeDelegate method 

- (NSDictionary *)registrationDictionaryForGrowl;
{
	NSMutableDictionary *regDictionary = [[[NSMutableDictionary alloc] initWithCapacity:5] autorelease];
	
	// An NSArray of all possible names of notifications.
	NSMutableArray *notificationNames = [[[NSMutableArray alloc] initWithCapacity:1] autorelease];
	[notificationNames addObject:@"name1"];
	[regDictionary setObject:notificationNames forKey:GROWL_NOTIFICATIONS_ALL];
	
	// An NSArray of notifications enabled by default (either by name, or by index into the GROWL_NOTIFICATIONS_ALL array).
	NSMutableArray *defaultEnabledNotifications = [[NSMutableArray alloc] initWithCapacity:1];
	[defaultEnabledNotifications addObject:@"name1"];
	[regDictionary setObject:defaultEnabledNotifications forKey:GROWL_NOTIFICATIONS_DEFAULT];
	
	return regDictionary;
}

- (void) growlNotificationWasClicked:(id)clickContext;
{
	NSLog(@"growlNotificationWasClicked:%@", clickContext);
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:clickContext]];
}

@end
