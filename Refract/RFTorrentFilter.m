//
//  RFTorrentFilter.m
//  Refract
//
//  Created by xiphux on 4/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RFTorrentFilter.h"

#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))

@implementation RFTorrentFilter

- (id)init
{
    return [self initWithType:filtNone];
}

- (id)initWithStatus:(RFTorrentStatus)initStatus
{
    id obj = [self initWithType:filtStatus];
    if ([obj isKindOfClass:[RFTorrentFilter class]]) {
        torrentStatus = initStatus;
    }
    return obj;
}

- (id)initWithType:(RFTorrentFilterType)initType
{
    self = [super init];
    if (self) {
        filterType = initType;
    }
    
    return self;
}

- (id)initWithFilter:(RFTorrentFilter *)filter
{
    id obj = [self initWithType:[filter filterType]];
    if ([obj isKindOfClass:[RFTorrentFilter class]]) {
        if (filterType == filtStatus) {
            torrentStatus = [filter torrentStatus];
        } else if (filterType == filtGroup) {
            torrentGroup = [filter torrentGroup];
        }
    }
    return obj;
}

- (id)initwithGroup:(RFTorrentGroup *)initGroup
{
    id obj = [self initWithType:filtGroup];
    if ([obj isKindOfClass:[RFTorrentFilter class]]) {
        torrentGroup = initGroup;
    }
    return obj;
}

- (void)dealloc
{
    [super dealloc];
}

@synthesize filterType;
@synthesize torrentStatus;
@synthesize torrentGroup;

- (bool)isEqual:(id)other
{
    if (other == self) {
        return true;
    }
    if (!other || ![other isKindOfClass:[self class]]) {
        return false;
    }
    
    return ((filterType == [other filterType]) && (torrentStatus == [other torrentStatus]) && ([torrentGroup isEqual:[other torrentGroup]]));
}

- (NSUInteger)hash
{
    return NSUINTROTATE(torrentStatus, NSUINT_BIT/2) ^ (NSUInteger)filterType;
}

- (bool)checkTorrent:(RFTorrent *)t
{
    if (!t) {
        return true;
    }
    
    if (filterType == filtNone) {
        return true;
    }
    
    if (filterType == filtStatus) {
        if ([t status] == torrentStatus) {
            return true;
        }
    }
    
    return false;
}

@end
