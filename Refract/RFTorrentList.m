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
- (void)removeSavedGroupsForTorrents:(NSArray *)removedTorrents;
- (void)updateSavedGroupForTorrent:(RFTorrent *)torrent;
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
        
        if (saveGroups) {
            [self removeSavedGroupsForTorrents:prune];
        }
    }
    
    if ([[NotificationController sharedNotificationController] queueing]) {
        [[NotificationController sharedNotificationController] flushQueue];
    }
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
    
    [self updateSavedGroupForTorrent:torrent];
}

- (void)updateSavedGroupForTorrent:(RFTorrent *)torrent
{
    if (!torrent) {
        return;
    }
    
    NSDictionary *tGroups = [[NSUserDefaults standardUserDefaults] dictionaryForKey:REFRACT_USERDEFAULT_TORRENT_GROUPS];
    
    NSUInteger group = [torrent group];
    
    NSMutableDictionary *mutableGroups = nil;
    if (group == 0) {
        
        if (tGroups) {
            mutableGroups = [NSMutableDictionary dictionaryWithDictionary:tGroups];
            [mutableGroups removeObjectForKey:[torrent hashString]];
            
            if ([mutableGroups count] > 0) {
                [[NSUserDefaults standardUserDefaults] setObject:mutableGroups forKey:REFRACT_USERDEFAULT_TORRENT_GROUPS];
            } else {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:REFRACT_USERDEFAULT_TORRENT_GROUPS];
            }
        }
        
    } else {
        
        if (tGroups) {
            mutableGroups = [NSMutableDictionary dictionaryWithDictionary:tGroups];
        } else {
            mutableGroups = [NSMutableDictionary dictionary];
        }
        
        [mutableGroups setObject:[NSNumber numberWithUnsignedLong:group] forKey:[torrent hashString]];
        
        [[NSUserDefaults standardUserDefaults] setObject:mutableGroups forKey:REFRACT_USERDEFAULT_TORRENT_GROUPS];
        
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
    
    NSDictionary *tGroups = [[NSUserDefaults standardUserDefaults] dictionaryForKey:REFRACT_USERDEFAULT_TORRENT_GROUPS];
    
    if (tGroups) {
        NSMutableDictionary *mutableGroups = [NSMutableDictionary dictionaryWithDictionary:tGroups];
        
        for (RFTorrent *t in removedTorrents) {
            [mutableGroups removeObjectForKey:[t hashString]];
        }
        
        if ([mutableGroups count] > 0) {
            [[NSUserDefaults standardUserDefaults] setObject:mutableGroups forKey:REFRACT_USERDEFAULT_TORRENT_GROUPS];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:REFRACT_USERDEFAULT_TORRENT_GROUPS];
        }
        
    }
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
    
    NSMutableArray *clear = [NSMutableArray array];
    for (RFTorrent *t in torrents) {
        if ([t group] == gid) {
            [t setGroup:0];
            [clear addObject:t];
        }
    }
    
    if (saveGroups && ([clear count] > 0)) {
        [self removeSavedGroupsForTorrents:clear];
    }
}

@end
