//
//  RefractAppDelegate.m
//  Refract
//
//  Created by xiphux on 4/1/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import "RefractAppDelegate.h"

#import "RFUtils.h"
#import "RFTorrent.h"
#import "RFTorrentGroup.h"
#import "RFConstants.h"
#import "RFEngineTransmission.h"

@interface RefractAppDelegate ()
- (void)updateFilterPredicate;
- (void)updateStatsButton;
- (void)updateRateText;
- (void)updateDockBadge;
@end

@implementation RefractAppDelegate

- (void)dealloc
{
    [window release];
    [sourceListController release];
    [torrentListController release];
    [preferencesController release];   
    [searchField release];
    [statsButton release];
    [rateText release];
    [self destroyEngine];
    [torrentList release];
    [searchPredicate release];

    [super dealloc];
}

@synthesize window;
@synthesize sourceListController;
@synthesize torrentListController;
@synthesize searchField;
@synthesize rateText;
@synthesize statsButton;

@synthesize engine;
@synthesize torrentList;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self setDefaults];
    
    [torrentListController setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:true]]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sourceListSelectionChanged:) name:@"SourceListSelectionChanged" object:sourceListController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(afterRefresh) name:@"refresh" object:engine];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(afterStatsRefresh) name:@"stats" object:engine];
    
    showTotalStats = [[NSUserDefaults standardUserDefaults] boolForKey:REFRACT_USERDEFAULT_TOTAL_SIZE];
    
    RFTorrentList *tList = [[RFTorrentList alloc] init];
    
    [self setTorrentList:tList];
     
    if ([self initEngine]) {
        [self startEngine];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)setDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
    
    [appDefaults setObject:[NSNumber numberWithDouble:5.0] forKey:REFRACT_USERDEFAULT_UPDATE_FREQUENCY];
    
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
    
    [self updateDockBadge];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSTimeInterval update = [defaults doubleForKey:REFRACT_USERDEFAULT_UPDATE_FREQUENCY];
    [NSTimer scheduledTimerWithTimeInterval:update target:self selector:@selector(refresh) userInfo:nil repeats:false];
}

- (void)afterStatsRefresh
{
    [self updateStatsButton];
    [self updateRateText];
}

- (void)updateStatsButton
{
    NSString *label;
    if (showTotalStats) {
        label = [NSString stringWithFormat:@"Total D: %@ U: %@", [RFUtils readableBytesDecimal:[engine totalDownloadedBytes]], [RFUtils readableBytesDecimal:[engine totalUploadedBytes]]];
    } else {
        label = [NSString stringWithFormat:@"Session D: %@ U: %@", [RFUtils readableBytesDecimal:[engine sessionDownloadedBytes]], [RFUtils readableBytesDecimal:[engine sessionUploadedBytes]]];
    }
    [statsButton setTitle:label];
    [statsButton sizeToFit];
}

- (void)updateRateText
{
    NSString *label = [NSString stringWithFormat:@"D: %@ U: %@", [RFUtils readableRateDecimal:[engine downloadSpeed]], [RFUtils readableRateDecimal:[engine uploadSpeed]]];
    [rateText setStringValue:label];
}

- (void)updateDockBadge
{
    NSUInteger activeCount = [[[torrentList torrents] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status == %d", stDownloading]] count];
    
    if (activeCount > 0) {
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:[NSString stringWithFormat:@"%d", activeCount]];
    } else {
        [[[NSApplication sharedApplication] dockTile] setBadgeLabel:nil];
    }
}

- (IBAction)statsButtonClick:(id)sender
{
    showTotalStats = !showTotalStats;
    [[NSUserDefaults standardUserDefaults] setBool:showTotalStats forKey:REFRACT_USERDEFAULT_TOTAL_SIZE];
    [self updateStatsButton];
}

- (IBAction)openPreferences:(id)sender
{
    if (preferencesController == nil) {
        preferencesController = [[PreferencesController alloc] init];
    }
    [preferencesController showWindow:self];
}

- (void)settingsChanged:(NSNotification *)notification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    RFEngineType type = [defaults integerForKey:REFRACT_USERDEFAULT_ENGINE];
    if (type != [engine type]) {
        [self destroyEngine];
        [self initEngine];
    }
    
    if (!started) {
        [self startEngine];
    }
}

- (void)sourceListSelectionChanged:(NSNotification *)notification
{
    [self updateFilterPredicate];
}

- (IBAction)search:(id)sender
{
    [self updateFilterPredicate];
}

- (void)updateFilterPredicate
{
    NSMutableArray *allPredicates = [NSMutableArray array];
    
    NSString *searchText = [searchField stringValue];
    if ([searchText length] > 0) {
        NSArray *keywords = [searchText componentsSeparatedByString:@" "];
        if ([keywords count] > 0) {
            for (NSString *word in keywords) {
                if ([word length] > 0) {
                    [allPredicates addObject:[NSPredicate predicateWithFormat:@"name contains[cd] %@", word]];
                }
            }
        }
    }
    
    RFTorrentFilterType filtType = [[sourceListController filter] filterType];
    if (filtType == filtStatus) {
        NSPredicate *statusPredicate = [NSPredicate predicateWithFormat:@"status == %d", [[sourceListController filter] torrentStatus]];
        [allPredicates addObject:statusPredicate];
    }
    
    if ([allPredicates count] > 0) {
        NSPredicate *filterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:allPredicates];
        [torrentListController setFilterPredicate:filterPredicate];
    } else {
        [torrentListController setFilterPredicate:nil];
    }
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    NSView *sourceList = [[splitView subviews] objectAtIndex:0];
    return [subview isEqual:sourceList];
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
    return NO;
}

@end
