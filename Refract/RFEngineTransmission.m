//
//  RFEngineTransmission.m
//  Refract
//
//  Created by xiphux on 4/2/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import "RFEngineTransmission.h"
#import "RFBase64.h"

@interface RFEngineTransmission ()
@property(retain) NSMutableURLRequest *request;
- (NSData *)rpcRequest:(NSData *)requestBody;
@end

@implementation RFEngineTransmission

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        url = @"http://127.0.0.1:9091/transmission/rpc";
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

@synthesize url;
@synthesize username;
@synthesize password;
@synthesize request;

- (bool)connect
{
    if ([url length] == 0) {
        return false;
    }
    
    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    //[request setValue:@"" forHTTPHeaderField:@"Accept-Language"];
    
    if (([username length] > 0) && ([password length] > 0)) {
        NSString *auth = [RFBase64 encodeBase64WithData:[[NSString stringWithFormat:@"%@:%@", username, password] dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:[NSString stringWithFormat:@"Basic %@", auth] forHTTPHeaderField:@"Authorization"];
    }
    
    [self rpcRequest:nil];
    
    return true;
}

- (bool)disconnect
{
    request = nil;
    return true;
}

- (bool)connected
{
    return (request);
}

- (bool)refresh
{
    return true;
}

- (NSData *)rpcRequest:(NSData *)requestBody
{
    if (!request) {
        return nil;
    }
    
    [request setHTTPBody:requestBody];
    
    NSHTTPURLResponse *responseData = nil;
    NSError *error = nil;
    
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseData error:&error];
    
    if (responseData) {
        if ([responseData statusCode] == 409) {
            // requires session token - get token and resubmit request
            NSDictionary *responseHeaders = [responseData allHeaderFields];
            
            NSString *sessionId = [responseHeaders valueForKey:@"X-Transmission-Session-Id"];
            if ([sessionId length] > 0) {
                [request setValue:sessionId forHTTPHeaderField:@"X-Transmission-Session-Id"];
                return [self rpcRequest:requestBody];
            }
        }
    }
    
    return response;
}

@end
