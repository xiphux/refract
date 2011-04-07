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
    
    if (![self initEngine]) {
        return;
    }
    
    RFTorrentList *tList = [[RFTorrentList alloc] init];
    
    [self setTorrentList:tList];
    
    [self refresh];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSTimeInterval update = [defaults doubleForKey:@"UpdateInterval"];
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:update target:self selector:@selector(refresh) userInfo:nil repeats:true];
    self.updateTimer = timer;
}

- (void)setDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
    
    [appDefaults setObject:[NSNumber numberWithDouble:5.0] forKey:@"UpdateInterval"];
    
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

@end
