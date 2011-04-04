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

@implementation RefractAppDelegate

@synthesize window;
@synthesize engine;
@synthesize torrentGroups;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if (![self initEngine]) {
        return;
    }
    
    [engine refresh];
    
    NSMutableArray *checkingList = [NSMutableArray array];
    NSMutableArray *waitingList = [NSMutableArray array];
    NSMutableArray *downloadingList = [NSMutableArray array];
    NSMutableArray *seedingList = [NSMutableArray array];
    NSMutableArray *stoppedList = [NSMutableArray array];
    
    if ([[engine torrents] count] > 0) {
        for (id key in engine.torrents) {
            RFTorrent *t = [engine.torrents objectForKey:key];
        
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

- (bool)initEngine
{
    [self destroyEngine];
    
    engine = [RFEngine engine];
    
    if (!engine) {
        return false;
    }
    
    return [engine connect];
}

- (void)destroyEngine
{
    if (!engine) {
        return;
    }
    
    if ([engine connected]) {
        [engine disconnect];
    }
    
    [engine release];
}

- (IBAction)openPreferences:(id)sender
{
    if (![NSBundle loadNibNamed:@"Preferences" owner:self])
    {
        NSLog(@"Could not load preferences nib");
    }
}

@end
