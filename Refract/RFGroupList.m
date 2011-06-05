//
//  RFGroupList.m
//  Refract
//
//  Created by xiphux on 4/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RFGroupList.h"
#import "RFConstants.h"

#define REFRACT_RFGROUPLIST_KEY_GROUPS @"groups"

@implementation RFGroupList

- (id)init
{
    self = [super init];
    if (self) {
        groups = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        groups = [[aDecoder decodeObjectForKey:REFRACT_RFGROUPLIST_KEY_GROUPS] retain];
    }
    return self;
}

- (void)dealloc
{
    [groups release];
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:groups forKey:REFRACT_RFGROUPLIST_KEY_GROUPS];
}

@synthesize groups;

- (RFTorrentGroup *)groupWithName:(NSString *)name
{
    for (RFTorrentGroup *g in groups) {
        if ([[g name] isEqualToString:name]) {
            return g;
        }
    }
    
    return nil;
}

- (bool)groupWithNameExists:(NSString *)name
{
    return ([self groupWithName:name] != nil);
}

- (RFTorrentGroup *)addGroup:(NSString *)name
{
    if ([name length] == 0) {
        return nil;
    }
    
    if ([self groupWithNameExists:name]) {
        return nil;
    }
    
    RFTorrentGroup *newGroup = [[[RFTorrentGroup alloc] init] autorelease];
    
    [newGroup setGid:[RFGroupList generateGroupId]];
    [newGroup setName:name];
    
    [groups addObject:newGroup];
    
    return newGroup;
}

- (void)removeGroup:(RFTorrentGroup *)group
{
    if (!group) {
        return;
    }
    
    [groups removeObject:group];
}


+ (NSUInteger)generateGroupId
{
    @synchronized (self) {
        NSInteger lastId = [[NSUserDefaults standardUserDefaults] integerForKey:REFRACT_USERDEFAULT_GROUP_ID];
        lastId++;
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLong:lastId] forKey:REFRACT_USERDEFAULT_GROUP_ID];
        return lastId;
    }
}

@end
