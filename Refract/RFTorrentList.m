//
//  RFTorrentList.m
//  Refract
//
//  Created by xiphux on 4/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RFTorrentList.h"

@interface RFTorrentList ()
- (void)updateList;
@end

@implementation RFTorrentList

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

@synthesize torrents;

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

- (void)replaceObjectInTorrentsAtIndex:(NSUInteger)index withObject:(RFTorrent *)anObject
{
    [torrents replaceObjectAtIndex:index withObject:anObject];
}

- (void)addTorrentsObject:(RFTorrent *)anObject
{
    [torrents addObject:anObject];
}

- (void)removeTorrentsObject:(RFTorrent *)anObject
{
    [torrents removeObject:anObject];
}


- (void)loadTorrents:(NSArray *)torrentList
{
    allTorrents = torrentList;
    [self updateList];
}

- (void)updateList
{
    if ([torrents count] == 0) {
        [self setTorrents:[NSMutableArray arrayWithArray:allTorrents]];
        return;
    }
    
    // prune torrents no longer matching
    NSMutableArray *prune = [NSMutableArray array];
    for (RFTorrent *t in torrents) {
        if (![allTorrents containsObject:t]) {
            [prune addObject:t];
        }
    }
    for (RFTorrent *t in prune) {
        [self removeTorrentsObject:t];
    }
    
    // update torrents that have changed
    for (RFTorrent *t in allTorrents) {
        NSUInteger index = [torrents indexOfObject:t];
        if (index != NSNotFound) {
            if (![[torrents objectAtIndex:index] dataEqual:t]) {
                [self replaceObjectInTorrentsAtIndex:index withObject:t];
            }
        } else {
            [self addTorrentsObject:t];
        }
    }
}

@end
