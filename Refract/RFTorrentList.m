//
//  RFTorrentList.m
//  Refract
//
//  Created by xiphux on 4/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RFTorrentList.h"

@interface RFTorrentList ()
- (void)rebuildList;
- (void)updateList;
- (NSMutableArray *)filteredList;
- (bool)torrentMatches:(RFTorrent *)t;
@end

@implementation RFTorrentList

- (id)init
{
    self = [super init];
    if (self) {
        filterType = grNone;
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

@synthesize torrents;
@synthesize filterType;
@synthesize filterStatus;

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

- (void)filterAll
{
    if (filterType != grNone) {
        filterType = grNone;
        [self rebuildList];
    }
}

- (void)filterByStatus:(RFTorrentStatus)status
{
    if ((filterType != grStatus) || (filterStatus != status)) {
        filterType = grStatus;
        filterStatus = status;
        [self rebuildList];
    }
}

- (NSMutableArray *)filteredList
{
    NSMutableArray *list = [NSMutableArray array];
    
    for (RFTorrent *t in allTorrents) {
        if ([self torrentMatches:t]) {
            [list addObject:t];
        }
    }
    
    return list;
}

- (void)rebuildList
{
    [self setTorrents:[self filteredList]];
}

- (void)updateList
{
    NSMutableArray *matchlist = [self filteredList];
    
    if ([torrents count] == 0) {
        [self setTorrents:matchlist];
        return;
    }
    
    // prune torrents no longer matching
    NSMutableArray *prune = [NSMutableArray array];
    for (RFTorrent *t in torrents) {
        if (![matchlist containsObject:t]) {
            [prune addObject:t];
        }
    }
    for (RFTorrent *t in prune) {
        [self removeTorrentsObject:t];
    }
    
    // update torrents that have changed
    for (RFTorrent *t in matchlist) {
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

- (bool)torrentMatches:(RFTorrent *)t
{
    if (filterType == grNone) {
        return true;
    }
    
    if (filterType == grStatus) {
        if ([t status] == filterStatus) {
            return true;
        }
    }
    
    return false;
}

@end
