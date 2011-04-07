//
//  RFTorrentList.m
//  Refract
//
//  Created by xiphux on 4/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RFTorrentList.h"

@interface RFTorrentList ()
- (NSString *)groupForTorrent:(RFTorrent *)torrent;
- (NSString *)statusGroupForTorrent:(RFTorrent *)torrent;
@end

@implementation RFTorrentList

@synthesize torrentGroups;
@synthesize grouping;

- (id)init
{
    return [self initWithGrouping:grStatus];
}

- (id)initWithGrouping:(RFTorrentGrouping)initGrouping
{
    self = [super init];
    if (self) {
        torrentGroups = [NSMutableArray array];
        grouping = initGrouping;
    }
    
    return self;   
}

- (void)dealloc
{
    [super dealloc];
}

- (NSUInteger)countOfTorrentGroups
{
    return [torrentGroups count];
}

- (id)objectInTorrentGroupsAtIndex:(NSUInteger)index
{
    return [torrentGroups objectAtIndex:index];
}

- (void)insertObject:(RFTorrentGroup *)group inTorrentGroupsAtIndex:(NSUInteger)index
{
    [torrentGroups insertObject:group atIndex:index];
}

- (void)removeObjectFromTorrentGroupsAtIndex:(NSUInteger)index
{
    [torrentGroups removeObjectAtIndex:index];
}

- (void)replaceObjectInTorrentGroupsAtIndex:(NSUInteger)index withObject:(RFTorrentGroup *)anObject
{
    [torrentGroups replaceObjectAtIndex:index withObject:anObject];
}

- (void)addTorrentGroupsObject:(RFTorrentGroup *)anObject
{
    [torrentGroups addObject:anObject];
}

- (void)removeTorrentGroupsObject:(RFTorrentGroup *)anObject
{
    [torrentGroups removeObject:anObject];
}


- (void)loadTorrents:(NSArray *)torrents
{
    // remove torrents no longer in the list
    for (RFTorrentGroup *group in torrentGroups) {
        NSMutableArray *prune = [NSMutableArray array];
        NSMutableArray *tList = [group torrents];
        for (RFTorrent *t in tList) {
            if ([torrents indexOfObject:t] == NSNotFound) {
                [prune addObject:t];
            } else if (![[self groupForTorrent:t] isEqualToString:[group name]]) {
                [prune addObject:t];
            }
        }
        for (RFTorrent *t in prune) {
            [group removeTorrentsObject:t];
        }
    }
    
    for (RFTorrent *t in torrents) {
        NSString *grpName = [self groupForTorrent:t];
        bool added = false;
        RFTorrentGroup *g = nil;
        for (RFTorrentGroup *group in torrentGroups) {
            if ([[group name] isEqualToString:grpName]) {
                g = group;
                break;
            }
        }
        if (g == nil) {
            added = true;
            g = [[RFTorrentGroup alloc] initWithName:grpName];
        } 
        
        NSUInteger index = [[g torrents] indexOfObject:t];
        if (index == NSNotFound) {
            [g addTorrentsObject:t];
        } else {
            if (![[[g torrents] objectAtIndex:index] dataEqual:t]) {
                [g replaceObjectInTorrentsAtIndex:index withObject:t];
            }
        }
        
        if (added) {
            [self addTorrentGroupsObject:g];
        }
    }
    
    NSMutableArray *prune = [NSMutableArray array];
    for (RFTorrentGroup *group in torrentGroups) {
        if ([group countOfTorrents] == 0) {
            [prune addObject:group];
        }
    }
    for (RFTorrentGroup *group in prune) {
        [self removeTorrentGroupsObject:group];
    }
}


- (NSString *)groupForTorrent:(RFTorrent *)torrent
{
    if (!torrent) {
        return nil;
    }
    
    switch (grouping) {
        case grStatus:
            return [self statusGroupForTorrent:torrent];
            break;
    }
    
    return nil;
}

- (NSString *)statusGroupForTorrent:(RFTorrent *)torrent
{
    if (!torrent) {
        return nil;
    }
    
    switch ([torrent status]) {
            
        case stWaiting:
            return @"Waiting";
            break;
            
        case stChecking:
            return @"Checking";
            break;
            
        case stDownloading:
            return @"Downloading";
            break;
            
        case stSeeding:
            return @"Seeding";
            break;
            
        case stStopped:
            return @"Stopped";
            break;
    }
    
    return nil;
}

@end
