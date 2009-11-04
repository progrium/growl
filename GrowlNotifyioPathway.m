//
//  GrowlNotifyioPathway.m
//  Growl
//
//  Created by awixted on 10/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "GrowlNotifyioPathway.h"
#import "CJSONDeserializer.h"
#import "GrowlDefines.h"

@interface GrowlNotifyioPathway (PRIVATE)
- (void)initRemoteHost;
@end


@implementation GrowlNotifyioPathway

@synthesize messageData;

- (BOOL) setEnabled:(BOOL)flag {
	NSLog(@"GrowlNotifyioPathway>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
	
	[self initRemoteHost];
	
	
	
	return [super setEnabled:flag];
}



- (void)initRemoteHost
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
	
	NSLog(@"notifyConn: %@", notifyConn);
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
	NSLog(@"connection did receive data");
	if([connection isEqualTo:notifyConn])
	{
		
		NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSLog(@"data: %@", jsonString);
		
		// Parse the json

		NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
		NSError *error = nil;
		NSDictionary *messageDict = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:&error];
		
		
		// Change the keys in this dict into ones growl understands 
		self.messageData = [[NSMutableDictionary alloc] initWithCapacity:3];
		
		[messageData setObject:@"GrowlMenu" forKey:GROWL_APP_NAME];
		
		if ([messageDict objectForKey:@"title"]) {
			[messageData setObject:[messageDict objectForKey:@"title"] forKey:GROWL_NOTIFICATION_TITLE];
		}
		if ([messageDict objectForKey:@"text"]) {
			[messageData setObject:[messageDict objectForKey:@"text"] forKey:GROWL_NOTIFICATION_DESCRIPTION];
		}
		
		// TODO: handle sticky and link
		
		// Keep the data in case we need it to stick around because we won't be posting the growl notif
		// until we get the icon
			
		//NSString *title             = [args objectForKey:KEY_TITLE];
		//NSString *desc              = [args objectForKey:KEY_DESC];
//		NSNumber *sticky            = [args objectForKey:KEY_STICKY];
//		NSNumber *priority          = [args objectForKey:KEY_PRIORITY];
//		NSString *imageUrl          = [args objectForKey:KEY_IMAGE_URL];
//		NSString *iconOfFile        = [args objectForKey:KEY_ICON_FILE];
//		NSString *iconOfApplication = [args objectForKey:KEY_ICON_APP_NAME];
//		NSData   *imageData         = [args objectForKey:KEY_IMAGE];
//		NSData   *pictureData       = [args objectForKey:KEY_PICTURE];
//		NSString *appName           = [args objectForKey:KEY_APP_NAME];
//		NSString *notifName         = [args objectForKey:KEY_NOTIFICATION_NAME];
//		NSString *notifIdentifier   = [args objectForKey:KEY_NOTIFICATION_IDENTIFIER];
		
		
		// Get the icon from the json data
		NSString *iconURLStr = [self.messageData objectForKey:@"icon"];
		if(!iconURLStr)
		{
			[self postNotificationWithDictionary:self.messageData];
			//[GrowlApplicationBridge notifyWithTitle:[growlData objectForKey:@"title"] 
//										description:[growlData objectForKey:@"text"] 
//								   notificationName:@"name1" 
//										   iconData:nil 
//										   priority:1 
//										   isSticky:[[growlData objectForKey:@"sticky"] isEqualToString:@"true"] 
//									   clickContext:[growlData objectForKey:@"link"]];
//			 
			NSLog(@"would make a growl here without an icon");
			self.messageData = nil;
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
		
		[self postNotificationWithDictionary:self.messageData];
		//
//		[GrowlApplicationBridge notifyWithTitle:[growlData objectForKey:@"title"] 
//									description:[growlData objectForKey:@"text"] 
//							   notificationName:@"name1" 
//									   iconData:[image TIFFRepresentation]
//									   priority:1 
//									   isSticky:[[growlData objectForKey:@"sticky"] isEqualToString:@"true"]
//								   clickContext:[growlData objectForKey:@"link"]];
//		
		NSLog(@"would make a growl here with an icon");
		[iconConn release];
		iconConn = nil;	
		
		self.messageData = nil;
	}
	
}



@end
