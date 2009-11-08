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
#import "GrowlApplicationBridge.h"

@interface GrowlNotifyioPathway (PRIVATE)
- (void)initRemoteHost;
@end


@implementation GrowlNotifyioPathway

@synthesize messageData;

- (void) dealloc
{
	[notifyConn release], notifyConn = nil;
	[iconConn release], iconConn = nil;
	[messageData release], messageData = nil;
	
	[super dealloc];
}

- (BOOL) setEnabled:(BOOL)flag {
	NSLog(@"GrowlNotifyioPathway>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
	
	[self initRemoteHost];
	
	// Register for notifications about clicks so we can open links
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self 
														selector:@selector(growlNotificationWasClicked:) 
															name:@"GrowlGrowlClicked!" 
														  object:nil];
	 
	
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
	
	notifyConn = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES];
	
	NSLog(@"notifyConn: %@", notifyConn);
	
	// TODO: release urlRequest here?
}


#pragma mark NSDistributedNotificationCenter callback method

- (void)growlNotificationWasClicked:(id)context
{
	NSLog(@"context! %@", context);
	if(![context isKindOfClass:[NSNotification class]])
	{
		NSLog(@"the parameter isn't a NSNotification");
		return;
	}
	
	NSNotification *notification = (NSNotification *)context;
	NSDictionary *userInfo = [notification userInfo];
	NSString *urlString = [userInfo objectForKey:@"ClickedContext"];
	
	// open the url
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlString]];
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"did fail with error: %@ on connection: %@", error, connection);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"received response: %@ for connection %@", response, connection);
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
		[jsonString release], jsonString = nil;
		
		NSError *error = nil;
		NSDictionary *messageDict = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:&error];
		
		
		// Change the keys in this dict into ones growl understands 
		self.messageData = [[NSMutableDictionary alloc] initWithCapacity:3];
		
		[messageData setObject:@"Growl" forKey:GROWL_APP_NAME];
		[messageData setObject:@"Notifyio message received" forKey:GROWL_NOTIFICATION_NAME];
		
		id piece;
		if(piece = [messageDict objectForKey:@"title"])
			[messageData setObject:piece forKey:GROWL_NOTIFICATION_TITLE];
		if(piece = [messageDict objectForKey:@"text"])
			[messageData setObject:piece forKey:GROWL_NOTIFICATION_DESCRIPTION];
		if(piece = [messageDict objectForKey:@"link"])
			[messageData setObject:piece forKey:GROWL_NOTIFICATION_CLICK_CONTEXT];
		
		
		// TODO: handle sticky and link
		
		// Keep the data in case we need it to stick around because we won't be posting the growl notif
		// until we get the icon
		
		
		// Get the icon from the json data
		NSString *iconURLStr = [messageDict objectForKey:@"icon"];
		if(!iconURLStr)
		{
			[self postNotificationWithDictionary:self.messageData];
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
		
		
		
		// add the image data to the dictionary we're going to pass
		//[messageData setObject:[image TIFFRepresentation] forKey:GROWL_NOTIFICATION_ICON];
		[messageData setObject:image forKey:GROWL_NOTIFICATION_ICON];
		
		[self postNotificationWithDictionary:self.messageData];

		//TODO: release image here?
		
		[iconConn release], iconConn = nil;	
		
		self.messageData = nil;
	}
	
}



@end
