//
//  RFURLConnection.m
//  Refract
//
//  Created by xiphux on 4/13/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RFURLConnection.h"


@implementation RFURLConnection

- (id)initWithRequest:(NSURLRequest *)initRequest delegate:(id)delegate startImmediately:(BOOL)startImmediately 
{
    self = [super initWithRequest:initRequest delegate:delegate startImmediately:startImmediately];
    if (self) {
        userInfo = nil;
        requestData = nil;
        response = nil;
        responseData = nil;
    }
    return self;
}

- (void)dealloc
{
    [requestData release];
    [userInfo release];
    [response release];
    [responseData release];
    [super dealloc];
}

@synthesize userInfo;
@synthesize requestData;
@synthesize response;
@synthesize responseData;

@end
