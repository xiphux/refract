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
@synthesize torrents;

- (id)init
{
    return [self initWithName:@""];
}

- (id)initWithName:(NSString *)initName
{
    self = [super init];
    if (self) {
        name = initName;
        torrents = [NSMutableArray array];
    }
    
    return self;
}

- (void)dealloc
{
    [torrents release];
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
    return [[self name] isEqualToString:[other name]];
}

- (NSUInteger)hash
{
    return [[self name] hash];
}


- (NSUInteger)countOfTorrents
{
    return [torrents count];
}

- (id)objectInTorrentsAtIndex:(NSUInteger)index
{
    return [torrents objectAtIndex:index];
}

- (void)insertObject:(RFTorrent *)torrent inTorrentsAtIndex:(NSUInteger)index
{
    [torrents insertObject:torrent atIndex:index];
}

- (void)removeObjectFromTorrentsAtIndex:(NSUInteger)index
{
    [torrents removeObjectAtIndex:index];
}

- (void)replaceObjectInTorrentsAtIndex:(NSUInteger)index withObject:(RFTorrent *)torrent
{
    [torrents replaceObjectAtIndex:index withObject:torrent];
}

- (void)addTorrentsObject:(RFTorrent *)torrent
{
    [torrents addObject:torrent];
}

- (void)removeTorrentsObject:(RFTorrent *)torrent
{
    [torrents removeObject:torrent];
}

@end
