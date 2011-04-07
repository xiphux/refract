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
@synthesize torrentList;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if (![self initEngine]) {
        return;
    }
    
    [engine refresh];
    
    RFTorrentList *tList = [[RFTorrentList alloc] init];
    
    [tList loadTorrents:[[engine torrents] allValues]];
    
    [self setTorrentList:tList];
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
