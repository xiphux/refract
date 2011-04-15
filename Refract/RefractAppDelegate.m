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
@synthesize sourceListController;
@synthesize torrentListController;
@synthesize engine;
@synthesize torrentList;
@synthesize updateTimer;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setDefaults];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    
    [torrentListController setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:true]]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceListSelectionChanged:) name:@"SourceListSelectionChanged" object:sourceListController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(afterRefresh) name:@"refresh" object:engine];
     
    if (![self initEngine]) {
        return;
    }
    
    RFTorrentList *tList = [[RFTorrentList alloc] init];
    
    [self setTorrentList:tList];
    
    [self startEngine];
}

- (void)setDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
    
    [appDefaults setObject:[NSNumber numberWithDouble:5.0] forKey:@"UpdateFrequency"];
    
    [defaults registerDefaults:appDefaults];
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

- (bool)startEngine
{
    if (started) {
        return true;
    }
    
    if (!engine) {
        return false;
    }
    
    started = true;
    
    [self refresh];
    
    return true;
}

- (void)stopEngine
{
    if (!engine) {
        return;
    }
    
    started = false;
}

- (void)destroyEngine
{
    if (!engine) {
        return;
    }
    
    if (started) {
        [self stopEngine];
    }
    
    if ([engine connected]) {
        [engine disconnect];
    }
    
    [engine release];
}

- (void)refresh
{
    if (!started) {
        return;
    }
    
    [engine refresh];
}
     
- (void)afterRefresh
{    
    NSArray *allTorrents = [[engine torrents] allValues];
    
    [[self torrentList] loadTorrents:allTorrents];
    
    [torrentListController rearrangeObjects];
    
    bool downloading = false;
    bool stopped = false;
    bool waiting = false;
    bool checking = false;
    bool seeding = false;
    for (RFTorrent *t in allTorrents) {
        switch ([t status]) {
            case stDownloading:
                downloading = true;
                break;
            case stSeeding:
                seeding = true;
                break;
            case stStopped:
                stopped = true;
                break;
            case stWaiting:
                waiting = true;
                break;
            case stChecking:
                checking = true;
                break;
        }
    }
    
    if (downloading) {
        [sourceListController addStatusGroup:stDownloading];
    } else {
        [sourceListController removeStatusGroup:stDownloading];
    }
    if (stopped) {
        [sourceListController addStatusGroup:stStopped];
    } else {
        [sourceListController removeStatusGroup:stStopped];
    }
    if (waiting) {
        [sourceListController addStatusGroup:stWaiting];
    } else {
        [sourceListController removeStatusGroup:stWaiting];
    }
    if (checking) {
        [sourceListController addStatusGroup:stChecking];
    } else {
        [sourceListController removeStatusGroup:stChecking];
    }
    if (seeding) {
        [sourceListController addStatusGroup:stSeeding];
    } else {
        [sourceListController removeStatusGroup:stSeeding];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSTimeInterval update = [defaults doubleForKey:@"UpdateFrequency"];
    [NSTimer scheduledTimerWithTimeInterval:update target:self selector:@selector(refresh) userInfo:nil repeats:false];
}

- (IBAction)openPreferences:(id)sender
{
    if (![NSBundle loadNibNamed:@"Preferences" owner:self])
    {
        NSLog(@"Could not load preferences nib");
    }
}

- (void)settingsChanged:(NSNotification *)notification
{
//    NSTimeInterval update = [[NSUserDefaults standardUserDefaults] doubleForKey:@"UpdateFrequency"];
//    if (update != [updateTimer timeInterval]) {
//        [self stopEngine];
//        [self startEngine];
//    }
}

- (void)sourceListSelectionChanged:(NSNotification *)notification
{
    if ([[sourceListController filter] filterType] == filtNone) {
        [torrentListController setFilterPredicate:nil];
    } else if ([[sourceListController filter] filterType] == filtStatus) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"status == %d", [[sourceListController filter] torrentStatus]];
        [torrentListController setFilterPredicate:pred];
    }
}

@end
