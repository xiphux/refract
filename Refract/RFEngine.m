//
//  RFEngine.m
//  Refract
//
//  Created by xiphux on 4/2/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import "RFEngine.h"
#import "RFEngineTransmission.h"

@implementation RFEngine

- (id)init
{
    self = [super init];
    if (self) {
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

@synthesize delegate;

- (bool)connect
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (bool)disconnect
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (bool)connected
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (bool)refresh
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (bool)startTorrents:(NSArray *)list
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (bool)stopTorrents:(NSArray *)list
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (bool)removeTorrents:(NSArray *)list deleteData:(bool)del
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (bool)addTorrent:(NSData *)data
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSMutableDictionary *)torrents
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (unsigned long)uploadSpeed
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (unsigned long)downloadSpeed
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (unsigned long)sessionUploadedBytes
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (unsigned long)sessionDownloadedBytes
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (unsigned long)totalUploadedBytes
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (unsigned long)totalDownloadedBytes
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (RFEngineType)type
{
    return 0;
}

+ (id)engineOfType:(RFEngineType)type
{
    switch (type) {
        case engTransmission:
            return [[RFEngineTransmission alloc] init];
            break;
    }
}

+ (id)engine
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int defEngine = (int)engTransmission;
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:defEngine] forKey:@"Engine"];
    [defaults registerDefaults:appDefaults];
    
    RFEngineType userType = (int)[[defaults objectForKey:@"Engine"] intValue];
    return [RFEngine engineOfType:userType];
}

@end
