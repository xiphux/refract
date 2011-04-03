//
//  RefractAppDelegate.m
//  Refract
//
//  Created by xiphux on 4/1/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import "RefractAppDelegate.h"

#import "RFTorrent.h"
#import "RFTorrentGroup.h"
#import "RFEngineTransmission.h"

@implementation RefractAppDelegate

@synthesize window;
@synthesize engine;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    RFEngineTransmission *tengine = [[RFEngineTransmission alloc] init];
    [tengine connect];
    [tengine refresh];
    [self setEngine:tengine];
    
    NSMutableArray *checkingList = [NSMutableArray array];
    NSMutableArray *waitingList = [NSMutableArray array];
    NSMutableArray *downloadingList = [NSMutableArray array];
    NSMutableArray *seedingList = [NSMutableArray array];
    NSMutableArray *stoppedList = [NSMutableArray array];
    
    for (id key in tengine.torrents) {
        RFTorrent *t = [tengine.torrents objectForKey:key];
        
        switch (t.status) {
                
            case stChecking:
                [checkingList addObject:t];
                break;
                
            case stWaiting:
                [waitingList addObject:t];
                break;
                
            case stDownloading:
                [downloadingList addObject:t];
                break;
                
            case stSeeding:
                [seedingList addObject:t];
                break;
                
            case stStopped:
                [stoppedList addObject:t];
                break;
                
        }
    }

    RFTorrentGroup *checking = [[RFTorrentGroup alloc] initWithName:@"Checking"];
    RFTorrentGroup *waiting = [[RFTorrentGroup alloc] initWithName:@"Waiting"];
    RFTorrentGroup *downloading = [[RFTorrentGroup alloc] initWithName:@"Downloading"];
    RFTorrentGroup *seeding = [[RFTorrentGroup alloc] initWithName:@"Seeding"];
    RFTorrentGroup *stopped = [[RFTorrentGroup alloc] initWithName:@"Stopped"];
    
    NSMutableArray *groups = [NSMutableArray array];
    if ([checkingList count] > 0) {
        [groups addObject:checking];
    }
    if ([waitingList count] > 0) {
        [groups addObject:waiting];
    }
    if ([downloadingList count] > 0) {
        [groups addObject:downloading];
    }
    if ([seedingList count] > 0) {
        [groups addObject:seeding];
    }
    if ([stoppedList count] > 0) {
        [groups addObject:stopped];
    }
    
    if ([checkingList count] > 0) {
        [checking setTorrents:checkingList];
    }
    if ([waitingList count] > 0) {
        [waiting setTorrents:waitingList];
    }
    if ([downloadingList count] > 0) {
        [downloading setTorrents:downloadingList];
    }
    if ([seedingList count] > 0) {
        [seeding setTorrents:seedingList];
    }
    if ([stoppedList count] > 0) {
        [stopped setTorrents:stoppedList];
    }
    
    [self setTorrentGroups:groups];
}

@synthesize torrentGroups;

@end
