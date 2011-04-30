//
//  RFGroupList.m
//  Refract
//
//  Created by xiphux on 4/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RFGroupList.h"
#import "RFConstants.h"

@implementation RFGroupList

- (id)init
{
    self = [super init];
    if (self) {
        groups = [NSMutableArray array];
    }
    
    return self;
}

- (void)dealloc
{
    [groups release];
    [super dealloc];
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
    
    RFTorrentGroup *newGroup = [[RFTorrentGroup alloc] init];
    
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
