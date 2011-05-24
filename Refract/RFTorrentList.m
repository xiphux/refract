//
//  RFTorrentList.m
//  Refract
//
//  Created by xiphux on 4/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RFTorrentList.h"
#import "NotificationController.h"
#import "RFConstants.h"

#define REFRACT_RFTORRENTLIST_KEY_TORRENTGROUPS @"torrentGroups"

@interface RFTorrentList ()
- (void)updateList;
- (void)cleanStaleGroups;
- (void)removeSavedGroupsForTorrents:(NSArray *)removedTorrents;
- (void)updateSavedGroupsForTorrents:(NSArray *)list;
- (void)torrentGroupChanged:(NSNotification *)notification;
- (NSUInteger)groupForTorrent:(NSString *)hashString;
@end

@implementation RFTorrentList


- (id)init
{
    self = [super init];
    if (self) {
        torrentGroups = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        torrentGroups = [[aDecoder decodeObjectForKey:REFRACT_RFTORRENTLIST_KEY_TORRENTGROUPS] retain];
    }
    return self;
}

- (void)dealloc
{
    [allTorrents release];
    [torrents release];
    [torrentGroups release];
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:torrentGroups forKey:REFRACT_RFTORRENTLIST_KEY_TORRENTGROUPS];
}

@synthesize torrents;
@synthesize delegate;
@synthesize initialized;

- (bool)saveGroups
{
    return saveGroups;
}

- (void)setSaveGroups:(bool)newSaveGroups
{
    if (saveGroups == newSaveGroups) {
        return;
    }
    
    saveGroups = newSaveGroups;
    
    if (saveGroups) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(torrentGroupChanged:) name:REFRACT_NOTIFICATION_TORRENT_GROUP_CHANGED object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:REFRACT_NOTIFICATION_TORRENT_GROUP_CHANGED object:nil];
    }
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
    [allTorrents release];
    allTorrents = [[NSArray alloc] initWithArray:torrentList];
    [self updateList];
    if (!initialized) {
        if (saveGroups) {
            [self cleanStaleGroups];
        }
        initialized = true;
    }
    
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(torrentListDidFinishLoading:)]) {
            [[self delegate] torrentListDidFinishLoading:self];
        }
    }
}

- (void)updateList
{
    if (!torrents) {
        [self setTorrents:[NSMutableArray array]];
    }
    
    if (initialized) {
        [[NotificationController sharedNotificationController] startQueue];
    }
    
    @synchronized (self) {
        
        // prune torrents no longer matching
        NSMutableArray *prune = [NSMutableArray array];
        NSMutableArray *pruneGroups = [NSMutableArray array];
        for (RFTorrent *t in torrents) {
            if (![allTorrents containsObject:t]) {
                [prune addObject:t];
            }
        }
        for (RFTorrent *t in prune) {
            [self removeTorrentsObject:t];
            if ([t group] > 0) {
                [pruneGroups addObject:t];
            }
            if (initialized) {
                [[NotificationController sharedNotificationController] notifyDownloadRemoved:t];
            }
        }
        
        // update torrents that have changed
        for (RFTorrent *t in allTorrents) {
            NSUInteger index = [torrents indexOfObject:t];
            
            if ((!initialized) && saveGroups) {
                [t setGroup:[self groupForTorrent:[t hashString]]];
            }
            
            if (index != NSNotFound) {
                if (![[torrents objectAtIndex:index] dataEqual:t]) {
                    [self replaceObjectInTorrentsAtIndex:index withObject:t];
                }
            } else {
                [self addTorrentsObject:t];
                if (initialized) {
                    [[NotificationController sharedNotificationController] notifyDownloadAdded:t];
                }
            }
        }
        
        if (saveGroups && ([pruneGroups count] > 0)) {
            [self removeSavedGroupsForTorrents:pruneGroups];
        }
    }
    
    if ([[NotificationController sharedNotificationController] queueing]) {
        [[NotificationController sharedNotificationController] flushQueue];
    }
}

- (void)clearTorrents
{
    [allTorrents release];
    [self setTorrents:[NSMutableArray array]];
    initialized = false;
}

- (void)torrentGroupChanged:(NSNotification *)notification
{    
    NSDictionary *data = [notification userInfo];
    if (!data) {
        return;
    }
    
    RFTorrent *torrent = [data objectForKey:@"torrent"];
    if (!torrent) {
        return;
    }
    
    [self updateSavedGroupsForTorrents:[NSArray arrayWithObject:torrent]];
}

- (void)updateSavedGroupsForTorrents:(NSArray *)list
{
    if (!list) {
        return;
    }
    
    if ([list count] == 0) {
        return;
    }
    
    for (RFTorrent *t in list) {
        if ([t group] > 0) {
            [torrentGroups setObject:[NSNumber numberWithUnsignedLong:[t group]] forKey:[t hashString]];
        } else {
            [torrentGroups removeObjectForKey:[t hashString]];
        }
    }
}

- (void)removeSavedGroupsForTorrents:(NSArray *)removedTorrents
{
    if (!removedTorrents) {
        return;
    }
    
    if ([removedTorrents count] == 0) {
        return;
    }
        
    for (RFTorrent *t in removedTorrents) {
        [torrentGroups removeObjectForKey:[t hashString]];
    }
}

- (NSUInteger)groupForTorrent:(NSString *)hashString
{
    if ([hashString length] == 0) {
        return 0;
    }
    
    NSNumber *groupNum = [torrentGroups objectForKey:hashString];
    if (!groupNum) {
        return 0;
    }
    
    return [groupNum unsignedLongValue];
}

- (void)clearGroup:(RFTorrentGroup *)group
{
    if (!group) {
        return;
    }
    
    NSUInteger gid = [group gid];
    if (gid < 1) {
        return;
    }
    
    NSMutableArray *clear = [NSMutableArray array];
    for (RFTorrent *t in torrents) {
        if ([t group] == gid) {
            [t setGroup:0];
            [clear addObject:t];
        }
    }
    
    if (saveGroups && ([clear count] > 0)) {
        [self updateSavedGroupsForTorrents:clear];
    }
}

- (void)setGroup:(NSUInteger)gid forTorrents:(NSArray *)list
{
    if (!list) {
        return;
    }
    
    if ([list count] == 0) {
        return;
    }
    
    NSMutableArray *update = [NSMutableArray array];
    for (RFTorrent *t in list) {
        if ([t group] != gid) {
            [t setGroup:gid];
            [update addObject:t];
        }
    }
    
    if (saveGroups && ([update count] > 0)) {
        [self updateSavedGroupsForTorrents:update];
    }
}

- (void)cleanStaleGroups
{
    NSMutableArray *prune = [NSMutableArray array];
    
    for (NSString *hashString in torrentGroups) {
        bool found = false;
        for (RFTorrent *t in torrents) {
            if ([[t hashString] isEqualToString:hashString]) {
                found = true;
                break;
            }
        }
        if (!found) {
            [prune addObject:hashString];
        }
    }
    
    if ([prune count] == 0) {
        return;
    }
    
    for (NSString *hashString in prune) {
        [torrentGroups removeObjectForKey:hashString];
    }
}

@end
