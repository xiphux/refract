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
@synthesize updateTimer;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setDefaults];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    
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
    
    if (!(engine && [engine connected])) {
        return false;
    }
    
    [self refresh];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSTimeInterval update = [defaults doubleForKey:@"UpdateFrequency"];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:update target:self selector:@selector(refresh) userInfo:nil repeats:true];
    self.updateTimer = timer;
    
    started = true;
    
    return true;
}

- (void)stopEngine
{
    if (!engine) {
        return;
    }
    
    [updateTimer invalidate];
    
    [updateTimer release];
    
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
    if (![engine connected]) {
        return;
    }
    
    [engine refresh];
    
    [[self torrentList] loadTorrents:[[engine torrents] allValues]];
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
    NSTimeInterval update = [[NSUserDefaults standardUserDefaults] doubleForKey:@"UpdateFrequency"];
    if (update != [updateTimer timeInterval]) {
        [self stopEngine];
        [self startEngine];
    }
}

@end
