//
//  SSLServerTest.m
//  SocketKit
//
//  Created by Alex Nichol on 5/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SSLServerTest.h"


@implementation SSLServerTest

- (void)testServer {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	SKTCPSocket * aSocket = nil;
	SKTCPSocketServer * server = [[SKTCPSocketServer alloc] initListeningOnPort:1337];
	@try {
		[server listen];
		while ((aSocket = (SKTCPSocket *)[server acceptConnection]) != nil) {
			NSLog(@"Connected from %@:%d", [aSocket remoteHost], [aSocket remotePort]);
			@try {
				NSString * combo = @"/Users/miang/Desktop/untitled folder/SocketKit-master/SocketKit/mycert.pem";
				SKTCPSSLSocket * sslSocket = [[[SKTCPSSLSocket alloc] initWithServerTCPSocket:aSocket publicKey:combo privateKey:combo] autorelease];
				[self handleSocket:sslSocket];
				[sslSocket close];
			} @catch (NSException * sslExc) {
				NSLog(@"SSL exception: %@", sslExc);
			}
		}
	} @catch (NSException * e) {
		NSLog(@"Exception : %@", e);
	}
	[server stopServer];
	[server release];
	
	[pool drain];
}
- (void)handleSocket:(SKTCPSSLSocket *)sslSocket {
    
	[sslSocket writeData:[@"Welcome to the fancy SSL server!\n" dataUsingEncoding:NSASCIIStringEncoding]];
	NSMutableString * message = [NSMutableString string];
	
    while (true) {
        NSData * aByte = [sslSocket readData:1];
        NSString * pStr = [[NSString alloc] initWithData:aByte encoding:NSASCIIStringEncoding];
        NSLog(@"pStr :%@",pStr);
        if ([pStr isEqual:@"\n"]) {
            [pStr release];
            break;
        }
        [message appendFormat:@"%@", pStr];
        [pStr release];
    }
	
    
	NSLog(@"Message: %@", message);
    if ([message rangeOfString:@":"].location == NSNotFound) {
        NSLog(@"not contain :");
        return;
    }
    NSArray *separate = [message componentsSeparatedByString:@":"];
    if ([separate count]<1) {
        NSLog(@"can't separate");
        [sslSocket writeData:[@"Wrong format!!!!!!\n" dataUsingEncoding:NSASCIIStringEncoding]];
        return;
    }
    NSString *stockName = [separate objectAtIndex:0];
    NSLog(@"%@",stockName);
    NSString *s = [separate objectAtIndex:1];
    NSString *str;
    if ([s isEqualToString:@"full"]) {
        NSLog(@"FULL");
        str =[NSString stringWithFormat:@"http://download.finance.yahoo.com/d/quotes.csv?s=%@&f=snl1c1p2vp0o0m0w0m3&e=.csv",stockName];
    }else if ([s isEqualToString:@"some"]) {
        NSLog(@"SOME");
        str = [NSString stringWithFormat:@"http://download.finance.yahoo.com/d/quotes.csv?s=%@&f=snl1c1p2v&e=.csv",stockName];
    }else if ([s isEqualToString:@"graph"]){
        NSLog(@"SOME");
        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDateComponents *components = [cal components:(  NSDayCalendarUnit | NSMonthCalendarUnit) fromDate:[NSDate date]];
        int end = (int)[components day];
        [components setMonth:([components month] - 1)];
        int start = (int)[components day];
        str = [NSString stringWithFormat:@"http://ichart.finance.yahoo.com/table.csv?s=%@&a=02&b=%d&c=2014&d=03&e=%d&f=2014&g=d&ignore=.csv",stockName,start,end];
    }
    
//    dispatch_async(dispatch_get_main_queue(), ^{
    NSURL *url = [NSURL URLWithString:str];
    NSMutableString *reply = [NSMutableString stringWithContentsOfURL:url encoding:NSASCIIStringEncoding error:nil];
    NSArray *result = [reply componentsSeparatedByString:@","];
//
////    NSArray *result = [[NSArray alloc]initWithObjects:@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J", nil];
    NSLog(@"result :%@",result);
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:result];
    NSLog(@"data[%lu] :%@ ",(unsigned long)data.length,data);
    
    [sslSocket writeData:data];
//    });
}

@end
