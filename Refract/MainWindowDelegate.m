//
//  MainWindowDelegate.m
//  Refract
//
//  Created by xiphux on 4/1/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import "MainWindowDelegate.h"

#import "RFUtils.h"
#import "RFTorrent.h"
#import "RFTorrentGroup.h"
#import "RFConstants.h"
#import "RFEngineTransmission.h"
#import "NotificationController.h"

@interface MainWindowDelegate ()

- (void)setDefaults;

- (void)updateStatsButton;
- (void)updateDockBadge;

- (void)settingsChanged:(NSNotification *)notification;

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode
        contextInfo:(void *)contextInfo;

- (void)changeGroup:(id)sender;

- (void)startTorrentNotified:(NSNotification *)notification;
- (void)stopTorrentNotified:(NSNotification *)notification;
- (void)removeTorrentNotified:(NSNotification *)notification;
- (void)deleteTorrentNotified:(NSNotification *)notification;
- (void)verifyTorrentNotified:(NSNotification *)notification;
- (void)reannounceTorrentNotified:(NSNotification *)notification;
- (void)sleepNotified:(NSNotification *)notification;
- (void)wakeNotified:(NSNotification *)notification;

- (void)tryRemoveTorrents:(NSArray *)torrents;
- (void)tryDeleteTorrents:(NSArray *)torrents;

- (void)startTorrents:(NSArray *)torrents;
- (void)stopTorrents:(NSArray *)torrents;
- (void)startAllTorrents;
- (void)stopAllTorrents;
- (void)removeTorrents:(NSArray *)torrents;
- (void)deleteTorrents:(NSArray *)torrents;
- (void)addTorrents:(NSArray *)files;
- (void)verifyTorrents:(NSArray *)torrents;
- (void)reannounceTorrents:(NSArray *)torrents;

- (bool)addTorrentFile:(NSURL *)url;

@end

@implementation MainWindowDelegate

- (id)init
{
    self = [super init];
    if (self) {
        updateQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [window unregisterDraggedTypes];
    [window release];
    [sourceListController release];
    [torrentListController release]; 
    [statsButton release];
    [self destroyEngine];
    [torrentList release];
    [groupList release];
    [updateQueue release];

    [super dealloc];
}

@synthesize window;
@synthesize sourceListController;
@synthesize torrentListController;
@synthesize statsButton;
@synthesize removeMenu;
@synthesize removeButton;
@synthesize actionMenu;
@synthesize actionButton;
@synthesize startMenu;
@synthesize stopMenu;
@synthesize startStopButton;

@synthesize engine;
@synthesize torrentList;
@synthesize groupList;

- (void)awakeFromNib
{
    [self setDefaults];
    
    [window registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    
    [removeButton setMenu:removeMenu forSegment:0];
    
    [actionButton setMenu:actionMenu forSegment:0];
    
    [startStopButton setMenu:stopMenu forSegment:0];
    [startStopButton setMenu:startMenu forSegment:1];
    
    [sourceListController setDelegate:self];
    
    statusButtonType = [[NSUserDefaults standardUserDefaults] integerForKey:REFRACT_USERDEFAULT_STAT_TYPE];
    
    RFTorrentList *tList = [[RFTorrentList alloc] init];
    [tList setDelegate:self];
    [self setTorrentList:tList];
    
    [self setGroupList:[[RFGroupList alloc] init]];
    [groupList load];
    [sourceListController initGroups:[groupList groups]];
    
    bool initialized = [self initEngine];
    [torrentList setSaveGroups:true];
    
    if (initialized) {
        [self startEngine];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(sleepNotified:) name: NSWorkspaceWillSleepNotification object: nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(wakeNotified:) name: NSWorkspaceDidWakeNotification object: nil];

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startTorrentNotified:) name:REFRACT_NOTIFICATION_TORRENT_START object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopTorrentNotified:) name:REFRACT_NOTIFICATION_TORRENT_STOP object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeTorrentNotified:) name:REFRACT_NOTIFICATION_TORRENT_REMOVE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteTorrentNotified:) name:REFRACT_NOTIFICATION_TORRENT_DELETE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verifyTorrentNotified:) name:REFRACT_NOTIFICATION_TORRENT_VERIFY object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reannounceTorrentNotified:) name:REFRACT_NOTIFICATION_TORRENT_REANNOUNCE object:nil];
}

- (void)setDefaults
{
    NSMutableDictionary *def = [NSMutableDictionary dictionary];
    
    [def setObject:[NSNumber numberWithInt:(int)statRate] forKey:REFRACT_USERDEFAULT_STAT_TYPE];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:def];
}


#pragma mark engine functions

- (bool)initEngine
{
    [self destroyEngine];
    
    engine = [RFEngine engine];
    
    if (!engine) {
        return false;
    }
    
    [engine setDelegate:self];
    
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
    if (updateTimer) {
        [updateTimer invalidate];
        [updateTimer release];
    }
    
    if (!started) {
        return;
    }
    
    [engine refresh];
}
 

#pragma mark engine delegate

- (void)engineDidRefreshTorrents:(RFEngine *)eng
{    
    NSArray *allTorrents = [[eng torrents] allValues];
    
    [[self torrentList] loadTorrents:allTorrents];
}

- (void)engineDidRefreshStats:(RFEngine *)engine
{
    [self updateStatsButton];
}


#pragma mark torrent list delegate

- (void)torrentListDidFinishLoading:(RFTorrentList *)list
{
    [torrentListController rearrangeObjects];
    
    bool downloading = false;
    bool stopped = false;
    bool waiting = false;
    bool checking = false;
    bool seeding = false;
    for (RFTorrent *t in [list torrents]) {
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
    [self updateStatsButton];
    
    if (!sleeping) {
    
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSTimeInterval update = [defaults doubleForKey:REFRACT_USERDEFAULT_UPDATE_FREQUENCY];
        updateTimer = [NSTimer scheduledTimerWithTimeInterval:update target:self selector:@selector(refresh) userInfo:nil repeats:false];
        
    }
}


#pragma mark source list delegate

- (void)sourceList:(SourceListController *)list filterDidChange:(RFTorrentFilter *)newFilter
{
    if ([list isEqual:sourceListController]) {
        RFTorrentFilterType filtType = [[sourceListController filter] filterType];
        if (filtType == filtStatus) {
            [torrentListController setStatusFilter:[[sourceListController filter] torrentStatus]];
        } else if (filtType == filtGroup) {
            if ([[sourceListController filter] torrentGroup] != nil) {
                [torrentListController setGroupFilter:[[[sourceListController filter] torrentGroup] gid]];
            } else {
                // no group
                [torrentListController setGroupFilter:0];
            }
        } else {
            [torrentListController clearFilter];
        }
        
        [self updateStatsButton];
    }
}

- (NSUInteger)sourceList:(SourceListController *)list torrentsInGroup:(RFTorrentGroup *)group
{
    if (!group) {
        return 0;
    }
    
    if ([group gid] < 1) {
        return 0;
    }
    
    if (!torrentList) {
        return 0;
    }
    
    NSArray *torrents = [[torrentList torrents] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"group == %d", [group gid]]];
    return [torrents count];
}

- (BOOL)sourceList:(SourceListController *)list canAddGroup:(NSString *)name
{
    if (!groupList) {
        return true;
    }
    
    if ([name length] == 0) {
        return false;
    }
    
    return ![groupList groupWithNameExists:name];
}

- (RFTorrentGroup *)sourceList:(SourceListController *)list didAddGroup:(NSString *)name
{
    if (!groupList) {
        return nil;
    }
    
    RFTorrentGroup *newGroup = [groupList addGroup:name];
    
    if (newGroup) {
        [groupList save];
    }
    
    return newGroup;
}

- (BOOL)sourceList:(SourceListController *)list canRemoveGroup:(RFTorrentGroup *)group
{
    return true;
}

- (void)sourceList:(SourceListController *)list didRemoveGroup:(RFTorrentGroup *)group
{
    if (!groupList) {
        return;
    }
    
    [torrentList clearGroup:group];
    
    [groupList removeGroup:group];
    
    [groupList save];
}

- (BOOL)sourceList:(SourceListController *)list canRenameGroup:(RFTorrentGroup *)group toName:(NSString *)newName
{
    if (!group) {
        return true;
    }
    
    if ([newName length] == 0) {
        return false;
    }
    
    if ([[group name] isEqualToString:newName]) {
        return true;
    }
    
    if (!groupList) {
        return true;
    }
    
    RFTorrentGroup *existing = [groupList groupWithName:newName];
    if (existing && ![existing isEqual:group]) {
        return false;
    }
    
    return true;
}

- (void)sourceList:(SourceListController *)list didRenameGroup:(RFTorrentGroup *)group toName:(NSString *)newName
{
    [group setName:newName];
    
    [groupList save];
}


#pragma mark ui actions

- (IBAction)statsButtonClick:(id)sender
{
    statusButtonType = statusButtonType + 1;
    if (statusButtonType > statTotal) {
        statusButtonType = 1;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:statusButtonType forKey:REFRACT_USERDEFAULT_STAT_TYPE];
    [self updateStatsButton];
}

- (IBAction)startStopClicked:(id)sender
{
    NSInteger clickedSegment = [sender selectedSegment];
    NSInteger clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
    
    NSArray *selected = [torrentListController selectedObjects];
    if ([selected count] < 1) {
        return;
    }
    
    if (clickedSegmentTag == 0) {
        // stop
        if (started) {
            [self stopTorrents:selected];
        }
    } else if (clickedSegmentTag == 1) {
        // start
        if (started) {
            [self startTorrents:selected];
        }
    }
}

- (IBAction)startClicked:(id)sender
{    
    NSArray *selected = [torrentListController selectedObjects];
    if ([selected count] < 1) {
        return;
    }
    
    if (started) {
        [self startTorrents:selected];
    }
}

- (IBAction)startAllClicked:(id)sender
{
    [self startAllTorrents];
}

- (IBAction)stopClicked:(id)sender
{    
    NSArray *selected = [torrentListController selectedObjects];
    if ([selected count] < 1) {
        return;
    }
    
    if (started) {
        [self stopTorrents:selected];
    }
}

- (IBAction)stopAllClicked:(id)sender
{
    [self stopAllTorrents];
}

- (IBAction)removeClicked:(id)sender
{
    NSArray *selected = [torrentListController selectedObjects];
    if ([selected count] < 1) {
        return;
    }
    
    [self tryRemoveTorrents:selected];
}

- (IBAction)removeAndDeleteClicked:(id)sender
{
    NSArray *selected = [torrentListController selectedObjects];
    if ([selected count] < 1) {
        return;
    }
    
    [self tryDeleteTorrents:selected];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode
        contextInfo:(void *)contextInfo
{
    NSDictionary *context = (NSDictionary *)contextInfo;
    
    NSString *type = [context objectForKey:@"type"];
    
    if ([type isEqualToString:@"remove"]) {
        
        if (returnCode == NSAlertSecondButtonReturn) {
            [self removeTorrents:[context objectForKey:@"selected"]];
        }
        
    } else if ([type isEqualToString:@"removedelete"]) {
        
        if (returnCode == NSAlertSecondButtonReturn) {
            [self deleteTorrents:[context objectForKey:@"selected"]];
        }
        
    } else if ([type isEqualToString:@"add"]) {
        if (returnCode == NSAlertSecondButtonReturn) {
            NSArray *paths = [context objectForKey:@"paths"];
            [self addTorrents:paths];
        }
    }
}

- (IBAction)addClicked:(id)sender
{
    NSArray *fileTypes = [NSArray arrayWithObject:@"torrent"];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    
    [oPanel setAllowsMultipleSelection:YES];
    NSInteger result = [oPanel runModalForDirectory:NSHomeDirectory()
                                     file:nil types:fileTypes];
    if (result == NSOKButton) {
        NSArray *urlsToOpen = [oPanel URLs];
        NSUInteger i, count = [urlsToOpen count];
        for (i=0; i<count; i++) {
            NSURL *url = [urlsToOpen objectAtIndex:i];
            NSInvocationOperation *op = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(addTorrentFile:) object:url] autorelease];
            [updateQueue addOperation:op];
        }
    }
}

- (void)changeGroup:(id)sender
{
    if ([[torrentListController selectedObjects] count] == 0) {
        return;
    }
    
    NSUInteger gid = [sender tag];
    [torrentList setGroup:gid forTorrents:[torrentListController selectedObjects]];
}

- (IBAction)verifyClicked:(id)sender
{
    NSArray *selected = [torrentListController selectedObjects];
    if ([selected count] < 1) {
        return;
    }
    
    [self verifyTorrents:selected];
}

- (IBAction)reannounceClicked:(id)sender
{
    NSArray *selected = [torrentListController selectedObjects];
    if ([selected count] < 1) {
        return;
    }
    
    [self reannounceTorrents:selected];
}


#pragma mark notifications

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

- (void)sleepNotified:(NSNotification *)notification
{
    sleeping = true;
    
    if (updateTimer) {
        [updateTimer invalidate];
        [updateTimer release];
    }
}

- (void)wakeNotified:(NSNotification *)notification
{
    sleeping = false;
    
    if (started) {
        [self performSelector:@selector(refresh) withObject:self afterDelay:0];
    }
}

- (void)startTorrentNotified:(NSNotification *)notification
{
    NSDictionary *data = [notification userInfo];
    if (!data) {
        return;
    }
    
    RFTorrent *torrent = [data objectForKey:@"torrent"];
    if (!torrent) {
        return;
    }
    
    [self startTorrents:[NSArray arrayWithObject:torrent]];
}

- (void)stopTorrentNotified:(NSNotification *)notification
{
    NSDictionary *data = [notification userInfo];
    if (!data) {
        return;
    }
    
    RFTorrent *torrent = [data objectForKey:@"torrent"];
    if (!torrent) {
        return;
    }
    
    [self stopTorrents:[NSArray arrayWithObject:torrent]];
}

- (void)removeTorrentNotified:(NSNotification *)notification
{
    NSDictionary *data = [notification userInfo];
    if (!data) {
        return;
    }
    
    RFTorrent *torrent = [data objectForKey:@"torrent"];
    if (!torrent) {
        return;
    }
    
    [self tryRemoveTorrents:[NSArray arrayWithObject:torrent]];
}

- (void)deleteTorrentNotified:(NSNotification *)notification
{
    NSDictionary *data = [notification userInfo];
    if (!data) {
        return;
    }
    
    RFTorrent *torrent = [data objectForKey:@"torrent"];
    if (!torrent) {
        return;
    }
    
    [self tryDeleteTorrents:[NSArray arrayWithObject:torrent]];
}

- (void)verifyTorrentNotified:(NSNotification *)notification
{
    NSDictionary *data = [notification userInfo];
    if (!data) {
        return;
    }
    
    RFTorrent *torrent = [data objectForKey:@"torrent"];
    if (!torrent) {
        return;
    }
    
    [self verifyTorrents:[NSArray arrayWithObject:torrent]];
}

- (void)reannounceTorrentNotified:(NSNotification *)notification
{
    NSDictionary *data = [notification userInfo];
    if (!data) {
        return;
    }
    
    RFTorrent *torrent = [data objectForKey:@"torrent"];
    if (!torrent) {
        return;
    }
    
    [self reannounceTorrents:[NSArray arrayWithObject:torrent]];
}



#pragma mark utility functions

- (bool)addTorrentFile:(NSURL *)url
{
    NSFileWrapper *file = [[NSFileWrapper alloc] initWithURL:url options:0 error:nil];
    
    if (!file) {
        return false;
    }
    
    NSData *fileContent = [file regularFileContents];
    [engine addTorrent:fileContent];
    
    [file release];
    
    return true;
}

- (void)updateStatsButton
{
    NSString *label;
    switch (statusButtonType) {
        case statCount:
            label = [NSString stringWithFormat:@"%d torrents", [[torrentListController arrangedObjects] count]];
            break;
        case statRate:
            label = [NSString stringWithFormat:@"D: %@ U: %@", [RFUtils readableRateDecimal:[engine downloadSpeed]], [RFUtils readableRateDecimal:[engine uploadSpeed]]];
            break;
        case statSession:
            label = [NSString stringWithFormat:@"Session D: %@ U: %@", [RFUtils readableBytesDecimal:[engine sessionDownloadedBytes]], [RFUtils readableBytesDecimal:[engine sessionUploadedBytes]]];
            break;
        case statTotal:
            label = [NSString stringWithFormat:@"Total D: %@ U: %@", [RFUtils readableBytesDecimal:[engine totalDownloadedBytes]], [RFUtils readableBytesDecimal:[engine totalUploadedBytes]]];
            break;
    }
    [statsButton setTitle:label];
    [statsButton sizeToFit];
    
    NSRect torrentListRect = [[statsButton superview] frame];
    NSRect statButtonRect = [statsButton frame];
    statButtonRect.origin.x = (torrentListRect.size.width / 2) - (statButtonRect.size.width / 2);
    [statsButton setFrame:statButtonRect];
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

- (void)tryRemoveTorrents:(NSArray *)torrents
{
    if (!torrents) {
        return;
    }
    
    if ([torrents count] == 0) {
        return;
    }
    
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Remove"];
    if ([torrents count] > 1) {
        [alert setMessageText:@"Are you sure you want to remove these torrents?"];
    } else {
        [alert setMessageText:@"Are you sure you want to remove this torrent?"];
    }
    NSMutableArray *names = [NSMutableArray array];
    for (RFTorrent *t in torrents) {
        [names addObject:[t name]];
    }
    [alert setInformativeText:[names componentsJoinedByString:@"\n"]];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSDictionary *context = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSArray arrayWithArray:torrents], @"remove", nil] forKeys:[NSArray arrayWithObjects:@"selected", @"type", nil]];
    
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:context];
}

- (void)tryDeleteTorrents:(NSArray *)torrents
{
    if (!torrents) {
        return;
    }
    
    if ([torrents count] == 0) {
        return;
    }
    
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Remove and Delete"];
    if ([torrents count] > 1) {
        [alert setMessageText:@"Are you sure you want to remove and delete these torrents?"];
    } else {
        [alert setMessageText:@"Are you sure you want to remove and delete this torrent?"];
    }
    NSMutableArray *names = [NSMutableArray array];
    for (RFTorrent *t in torrents) {
        [names addObject:[t name]];
    }
    [alert setInformativeText:[names componentsJoinedByString:@"\n"]];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSDictionary *context = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSArray arrayWithArray:torrents], @"removedelete", nil] forKeys:[NSArray arrayWithObjects:@"selected", @"type", nil]];
    
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:context];
}

- (void)tryAddTorrents:(NSArray *)files
{
    if (!files) {
        return;
    }
    
    if ([files count] == 0) {
        return;
    }
    
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Add"];
    if ([files count] > 1) {
        [alert setMessageText:@"Are you sure you want to add these torrents?"];
    } else {
        [alert setMessageText:@"Are you sure you want to add this torrent?"];
    }
    NSMutableArray *displayNames = [NSMutableArray array];
    for (NSString *path in files) {
        [displayNames addObject:[[NSFileManager defaultManager] displayNameAtPath:path]];
    }
    [alert setInformativeText:[displayNames componentsJoinedByString:@"\n"]];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSDictionary *context = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSArray arrayWithArray:files], @"add", nil] forKeys:[NSArray arrayWithObjects:@"paths", @"type", nil]];
    
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:context];
}

- (void)startTorrents:(NSArray *)torrents
{
    if (!torrents) {
        return;
    }
    
    if ([torrents count] == 0) {
        return;
    }
    
    [engine startTorrents:torrents];
}

- (void)stopTorrents:(NSArray *)torrents
{
    if (!torrents) {
        return;
    }
    
    if ([torrents count] == 0) {
        return;
    }
    
    [engine stopTorrents:torrents];
}

- (void)startAllTorrents
{
    [engine startAllTorrents];
}

- (void)stopAllTorrents
{
    [engine stopAllTorrents];
}

- (void)removeTorrents:(NSArray *)torrents
{
    if (!torrents) {
        return;
    }
    
    if ([torrents count] == 0) {
        return;
    }
    
    [engine removeTorrents:torrents deleteData:false];
}

- (void)deleteTorrents:(NSArray *)torrents
{
    if (!torrents) {
        return;
    }
    
    if ([torrents count] == 0) {
        return;
    }
    
    [engine removeTorrents:torrents deleteData:true];
}

- (void)addTorrents:(NSArray *)files
{
    if (!files) {
        return;
    }
    
    if ([files count] == 0) {
        return;
    }
    
    for (NSString *path in files) {
        NSURL *pathUrl = [NSURL fileURLWithPath:path];
        NSInvocationOperation *op = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(addTorrentFile:) object:pathUrl] autorelease];
        [updateQueue addOperation:op];
    }
}

- (void)verifyTorrents:(NSArray *)torrents
{
    if (!torrents) {
        return;
    }
    
    if ([torrents count] == 0) {
        return;
    }
    
    [engine verifyTorrents:torrents];
}

- (void)reannounceTorrents:(NSArray *)torrents
{
    if (!torrents) {
        return;
    }
    
    if ([torrents count] == 0) {
        return;
    }
    
    [engine reannounceTorrents:torrents];
}


#pragma mark splitview delegate

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    NSView *sourceList = [[splitView subviews] objectAtIndex:0];
    return [subview isEqual:sourceList];
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
    return NO;
}



#pragma mark drag and drop delegate

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    if ((NSDragOperationCopy & [sender draggingSourceOperationMask]) == NSDragOperationCopy) {
        return NSDragOperationCopy;
    }
    
    return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender
{
    if (engine && [engine connected] && started) {
        return YES;
    }
    
    return NO;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    NSPasteboard *paste = [sender draggingPasteboard];
    
    if (![[paste types] containsObject:NSFilenamesPboardType]) {
        return NO;
    }
    
    NSArray *files = [paste propertyListForType:NSFilenamesPboardType];
    NSMutableArray *torrentFiles = [NSMutableArray array];
    for (NSString *path in files) {
        if ([[path pathExtension] isEqualToString:@"torrent"]) {
            [torrentFiles addObject:path];
        }
    }
    
    if ([torrentFiles count] < 1) {
        return NO;
    }

    [self tryAddTorrents:torrentFiles];
    
    return YES;
}


#pragma mark torrent item delegate

- (NSArray *)torrentItemAvailableGroups:(TorrentItem *)item
{
    if (!groupList) {
        return nil;
    }
    
    return [groupList groups];
}


#pragma mark menu delegate

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    if ([menu isEqual:actionMenu]) {
        
        bool selected = ([[torrentListController selectedObjects] count] > 0);      
        
        NSMenuItem *verifyMenuItem = [menu itemAtIndex:0];
        [verifyMenuItem setEnabled:selected];
        
        NSMenuItem *reannounceMenuItem = [menu itemAtIndex:1];
        [reannounceMenuItem setEnabled:selected];
        
        NSMenuItem *groupMenuItem = [menu itemAtIndex:3];  
        NSMenu *groupSubMenu = [[NSMenu alloc] initWithTitle:@"Group"];
        
        [menu setSubmenu:groupSubMenu forItem:groupMenuItem];
        
        NSMenuItem *noGroup = [[NSMenuItem alloc] initWithTitle:@"No Group" action:@selector(changeGroup:) keyEquivalent:@""];
        [noGroup setTag:0];
        [noGroup setTarget:self];
        [groupSubMenu addItem:noGroup];
        
        if ([[groupList groups] count] > 0) {
            [groupSubMenu addItem:[NSMenuItem separatorItem]];
            NSArray *sortedGroups = [[groupList groups] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:true] autorelease]]];
            for (NSUInteger i = 0; i < [sortedGroups count]; i++) {
                RFTorrentGroup *group = [sortedGroups objectAtIndex:i];
                NSMenuItem *groupItem = [[NSMenuItem alloc] initWithTitle:[group name] action:@selector(changeGroup:) keyEquivalent:@""];
                [groupItem setTag:[group gid]];
                [groupItem setTarget:self];
                [groupItem setEnabled:selected];
                [groupSubMenu addItem:groupItem];
            }
            
        }
        
        [groupMenuItem setEnabled:selected];

    }
    
    if ([menu isEqual:removeMenu]) {
        bool selected = ([[torrentListController selectedObjects] count] > 0);
        NSMenuItem *removeItem = [menu itemAtIndex:0];
        [removeItem setEnabled:selected];
        NSMenuItem *removeDeleteItem = [menu itemAtIndex:1];
        [removeDeleteItem setEnabled:selected];
    }
    
    if ([menu isEqual:startMenu]) {
        bool selected = ([[torrentListController selectedObjects] count] > 0);
        NSMenuItem *startItem = [menu itemAtIndex:0];
        [startItem setEnabled:selected];
        NSMenuItem *startAllItem = [menu itemAtIndex:1];
        [startAllItem setEnabled:[[torrentListController arrangedObjects] count] > 0];
    }
    
    if ([menu isEqual:stopMenu]) {
        bool selected = ([[torrentListController  selectedObjects] count] > 0);
        NSMenuItem *stopItem = [menu itemAtIndex:0];
        [stopItem setEnabled:selected];
        NSMenuItem *stopAllItem = [menu itemAtIndex:1];
        [stopAllItem setEnabled:[[torrentListController arrangedObjects] count] > 0];
    }
}

@end
