//
//  RFEngine.m
//  Refract
//
//  Created by xiphux on 4/2/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import "RFEngine.h"


@implementation RFEngine

- (id)init
{
    self = [super init];
    if (self) {
        torrents = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

@synthesize torrents;

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

- (bool)refresh
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
