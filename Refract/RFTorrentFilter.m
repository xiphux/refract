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
        torrentGroup = [initGroup retain];
    }
    return obj;
}

- (id)initWithState:(RFTorrentState)initState
{
    id obj = [self initWithType:filtState];
    if ([obj isKindOfClass:[RFTorrentFilter class]]) {
        torrentState = initState;
    }
    return obj;
}

- (void)dealloc
{
    [torrentGroup release];
    [super dealloc];
}

@synthesize filterType;
@synthesize torrentStatus;
@synthesize torrentGroup;
@synthesize torrentState;

- (bool)isEqual:(id)other
{
    if (other == self) {
        return true;
    }
    if (!other || ![other isKindOfClass:[self class]]) {
        return false;
    }
    
    return ((filterType == [other filterType]) && (torrentStatus == [other torrentStatus]) && ([torrentGroup isEqual:[other torrentGroup]]) && (torrentState == [other torrentState]));
}

- (NSUInteger)hash
{
    if (filterType == filtStatus) {
        return NSUINTROTATE(torrentStatus, NSUINT_BIT/2) ^ (NSUInteger)filterType;
    } else if (filterType == filtState) {
        return NSUINTROTATE(torrentState, NSUINT_BIT/2) ^ (NSUInteger)filterType;
    } else if (filterType == filtGroup) {
        return NSUINTROTATE([torrentGroup hash], NSUINT_BIT/2) ^ (NSUInteger)filterType;
    }
    return (NSUInteger)filterType;
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
    
    if (filterType == filtState) {
        if (torrentState == stateComplete) {
            return [t complete];
        } else if (torrentState == stateIncomplete) {
            return ![t complete];
        }
    }
    
    return false;
}

- (NSPredicate *)predicate
{
    if (filterType == filtNone) {
        return nil;
    }
    
    if (filterType == filtStatus) {
        return [NSPredicate predicateWithFormat:@"status == %d", torrentStatus];
    }
    
    if (filterType == filtGroup) {
        if (torrentGroup) {
            return [NSPredicate predicateWithFormat:@"group == %d", [torrentGroup gid]];
        } else {
            // no group
            return [NSPredicate predicateWithFormat:@"group == 0"];
        }
    }
    
    if (filterType == filtState) {
        if (torrentState == stateComplete) {
            return [NSPredicate predicateWithFormat:@"complete == TRUE"];
        } else if (torrentState == stateIncomplete) {
            return [NSPredicate predicateWithFormat:@"complete == FALSE"];
        }
    }
    
    return nil;
}

@end
