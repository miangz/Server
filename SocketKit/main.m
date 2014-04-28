//
//  main.m
//  SocketKit
//
//  Created by Alex Nichol on 5/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SKTCPSocket.h"
#import "SKTCPSocketServer.h"
#import "SKTCPSSLSocket.h"
#import "SSLServerTest.h"

void serverTestSSL () {
	SSLServerTest * serverTest = [[SSLServerTest alloc] init];
	[serverTest testServer];
	[serverTest release];
}

void googleTest () {
	NSLog(@"Connecting...");
	SKTCPSocket * socket = [[SKTCPSocket alloc] initWithRemoteHost:@"www.google.com" port:80];
	NSData * request = [@"GET / HTTP/1.1\r\nHost: www.google.com\r\nConnection: close\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
	[socket writeData:request];
	
	int length = 100;
	
	while (true) {
		@try {
			NSData * response = [socket readData:1];
			NSString * someText = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
			printf("%s", [someText UTF8String]);
			if (length-- == 0) {
				printf("...\n");
				break;
			}
		} @catch (NSException * e) {
			break;
		}
	}
	
	[socket close];
	[socket release];
}

int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	

		serverTestSSL();

	
	printf("\n");
	NSLog(@"Program done.");
	

	
	[pool drain];
    return 0;
}

