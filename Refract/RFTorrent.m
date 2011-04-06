//
//  RFTorrent.m
//  Refract
//
//  Created by xiphux on 4/2/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import "RFTorrent.h"


@implementation RFTorrent

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [name release];
    [tid release];
    [super dealloc];
}

@synthesize name;
@synthesize tid;
@synthesize currentSize;
@synthesize doneSize;
@synthesize totalSize;
@synthesize uploadRate;
@synthesize downloadRate;
@synthesize status;

- (unsigned int)percent
{
    if (doneSize == 0) {
        return 0;
    }
    
    return (unsigned int)((currentSize / doneSize) * 100);
}

- (bool)isEqual:(id)other
{
    if (other == self) {
        return true;
    }
    if (!other || ![other isKindOfClass:[self class]]) {
        return false;
    }
    return [[self tid] isEqualToString:[other tid]];
}

- (NSUInteger)hash
{
    return [[self tid] hash];
}

- (bool)dataEqual:(RFTorrent *)other
{
    if (other == self) {
        return true;
    }
    if (!other) {
        return false;
    }
    return (
            [[self name] isEqualToString:[other name]] &&
            [[self tid] isEqualToString:[other tid]] &&
            ([self currentSize] == [other currentSize]) &&
            ([self doneSize] == [other doneSize]) &&
            ([self totalSize] == [other totalSize]) &&
            ([self uploadRate] == [other uploadRate]) &&
            ([self downloadRate] == [other downloadRate]) &&
            ([self status] == [other status])
            );
}

@end
