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

@interface RFTorrentList ()
- (void)updateList;
- (void)updateSavedGroups;
- (void)torrentGroupChanged:(NSNotification *)notification;
- (NSUInteger)groupForTorrent:(NSString *)hashString;
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
    allTorrents = torrentList;
    [self updateList];
    initialized = true;
    
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(torrentListDidFinishLoading:)]) {
            [[self delegate] torrentListDidFinishLoading:self];
        }
    }
}

- (void)updateList
{
    bool updateGroups = false;
    
    if (!torrents) {
        [self setTorrents:[NSMutableArray array]];
    }
    
    if (initialized) {
        [[NotificationController sharedNotificationController] startQueue];
    }
    
    @synchronized (self) {
        
        // prune torrents no longer matching
        NSMutableArray *prune = [NSMutableArray array];
        for (RFTorrent *t in torrents) {
            if (![allTorrents containsObject:t]) {
                updateGroups = true;
                [prune addObject:t];
            }
        }
        for (RFTorrent *t in prune) {
            [self removeTorrentsObject:t];
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
        
    }
    
    if ([[NotificationController sharedNotificationController] queueing]) {
        [[NotificationController sharedNotificationController] flushQueue];
    }
    
    if (saveGroups && updateGroups) {
        [self updateSavedGroups];
    }
}

- (void)torrentGroupChanged:(NSNotification *)notification
{
    [self updateSavedGroups];
}

- (void)updateSavedGroups
{
    if (!torrents) {
        return;
    }
    
    NSMutableDictionary *tGroups = [NSMutableDictionary dictionary];
    
    @synchronized (self) {
        for (RFTorrent *t in torrents) {
            if (([[t hashString] length] > 0) && ([t group] > 0)) {
                [tGroups setObject:[NSNumber numberWithUnsignedLong:[t group]] forKey:[t hashString]];
            }
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:tGroups forKey:REFRACT_USERDEFAULT_TORRENT_GROUPS];
}

- (NSUInteger)groupForTorrent:(NSString *)hashString
{
    if ([hashString length] == 0) {
        return 0;
    }
    
    NSDictionary *tGroups = [[NSUserDefaults standardUserDefaults] dictionaryForKey:REFRACT_USERDEFAULT_TORRENT_GROUPS];
    if (!tGroups) {
        return 0;
    }
    
    NSNumber *groupNum = [tGroups objectForKey:hashString];
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
    
    bool needsUpdate = false;
    
    @synchronized (self) {
        for (RFTorrent *t in torrents) {
            if ([t group] == gid) {
                [t setGroup:0];
                needsUpdate = true;
            }
        }
    }
    
    if (needsUpdate) {
        [self updateSavedGroups];
    }
}

@end
