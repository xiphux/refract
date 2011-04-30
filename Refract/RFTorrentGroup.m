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

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [[RFTorrentGroup alloc] init];
    if (self) {
        name = [aDecoder decodeObjectForKey:@"name"];
        gid = [aDecoder decodeIntForKey:@"gid"];
    }
    return self;
}

- (void)dealloc
{
    [name release];
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:name forKey:@"name"];
    [aCoder encodeInt:gid forKey:@"gid"];
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
