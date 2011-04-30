//
//  RFTorrentGroup.m
//  Refract
//
//  Created by xiphux on 4/3/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import "RFTorrentGroup.h"

@implementation RFTorrentGroup

@synthesize name;
@synthesize gid;

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    
    return self;
}

- (void)dealloc
{
    [name release];
    [super dealloc];
}

- (bool)isEqual:(id)other
{
    if (other == self) {
        return true;
    }
    if (!other || ![other isKindOfClass:[self class]]) {
        return false;
    }
    return gid == [other gid];
}

- (NSUInteger)hash
{
    return gid;
}

@end
