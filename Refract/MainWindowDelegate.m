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
- (void)updateFilterPredicate;
- (void)updateStatsButton;
- (void)updateRateText;
- (void)updateDockBadge;
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode
        contextInfo:(void *)contextInfo;
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
    [searchField release];
    [statsButton release];
    [rateText release];
    [self destroyEngine];
    [torrentList release];
    [groupList release];
    [searchPredicate release];
    [updateQueue release];

    [super dealloc];
}

@synthesize window;
@synthesize sourceListController;
@synthesize torrentListController;
@synthesize searchField;
@synthesize rateText;
@synthesize statsButton;
@synthesize removeMenu;
@synthesize removeButton;

@synthesize engine;
@synthesize torrentList;
@synthesize groupList;

- (void)awakeFromNib
{
    [window registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    
    [removeButton setMenu:removeMenu forSegment:0];
    
    [torrentListController setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:true]]];
    
    [sourceListController setDelegate:self];
    
    showTotalStats = [[NSUserDefaults standardUserDefaults] boolForKey:REFRACT_USERDEFAULT_TOTAL_SIZE];
    
    RFTorrentList *tList = [[RFTorrentList alloc] init];
    [tList setDelegate:self];
    [self setTorrentList:tList];
    
    [self setGroupList:[[RFGroupList alloc] init]];
    
    if ([self initEngine]) {
        [self startEngine];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
}

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
    if (!started) {
        return;
    }
    
    [engine refresh];
}
     
- (void)engineDidRefreshTorrents:(RFEngine *)eng
{    
    NSArray *allTorrents = [[eng torrents] allValues];
    
    [[self torrentList] loadTorrents:allTorrents];
}

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
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSTimeInterval update = [defaults doubleForKey:REFRACT_USERDEFAULT_UPDATE_FREQUENCY];
    [NSTimer scheduledTimerWithTimeInterval:update target:self selector:@selector(refresh) userInfo:nil repeats:false];
}

- (void)engineDidRefreshStats:(RFEngine *)engine
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

- (void)sourceList:(SourceListController *)list filterDidChange:(RFTorrentFilter *)newFilter
{
    if ([list isEqual:sourceListController]) {
        [searchField setStringValue:@""];
        [self updateFilterPredicate];
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
    
    return [groupList addGroup:name];
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
    
    [groupList removeGroup:group];
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
}

- (IBAction)search:(id)sender
{
    [self updateFilterPredicate];
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
            [engine stopTorrents:selected];
        }
    } else if (clickedSegmentTag == 1) {
        // start
        if (started) {
            [engine startTorrents:selected];
        }
    }
}

- (IBAction)removeClicked:(id)sender
{
    NSArray *selected = [torrentListController selectedObjects];
    if ([selected count] < 1) {
        return;
    }
    
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Remove"];
    if ([selected count] > 1) {
        [alert setMessageText:@"Are you sure you want to remove these torrents?"];
    } else {
        [alert setMessageText:@"Are you sure you want to remove this torrent?"];
    }
    NSMutableArray *names = [NSMutableArray array];
    for (RFTorrent *t in selected) {
        [names addObject:[t name]];
    }
    [alert setInformativeText:[names componentsJoinedByString:@"\n"]];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSDictionary *context = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSArray arrayWithArray:selected], @"remove", nil] forKeys:[NSArray arrayWithObjects:@"selected", @"type", nil]];
    
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:context];
}

- (IBAction)removeAndDeleteClicked:(id)sender
{
    NSArray *selected = [torrentListController selectedObjects];
    if ([selected count] < 1) {
        return;
    }
    
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Remove and Delete"];
    if ([selected count] > 1) {
        [alert setMessageText:@"Are you sure you want to remove and delete these torrents?"];
    } else {
        [alert setMessageText:@"Are you sure you want to remove and delete this torrent?"];
    }
    NSMutableArray *names = [NSMutableArray array];
    for (RFTorrent *t in selected) {
        [names addObject:[t name]];
    }
    [alert setInformativeText:[names componentsJoinedByString:@"\n"]];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSDictionary *context = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSArray arrayWithArray:selected], @"removedelete", nil] forKeys:[NSArray arrayWithObjects:@"selected", @"type", nil]];
    
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:context];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode
        contextInfo:(void *)contextInfo
{
    NSDictionary *context = (NSDictionary *)contextInfo;
    
    NSString *type = [context objectForKey:@"type"];
    
    if ([type isEqualToString:@"remove"]) {
        
        if (returnCode == NSAlertSecondButtonReturn) {
            NSArray *selected = [context objectForKey:@"selected"];
            [engine removeTorrents:selected deleteData:false];
        }
        
    } else if ([type isEqualToString:@"removedelete"]) {
        
        if (returnCode == NSAlertSecondButtonReturn) {
            NSArray *selected = [context objectForKey:@"selected"];
            [engine removeTorrents:selected deleteData:true];
        }
        
    } else if ([type isEqualToString:@"add"]) {
        if (returnCode == NSAlertSecondButtonReturn) {
            NSArray *paths = [context objectForKey:@"paths"];
            for (NSString *path in paths) {
                NSURL *pathUrl = [NSURL fileURLWithPath:path];
                NSInvocationOperation *op = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(addTorrentFile:) object:pathUrl] autorelease];
                [updateQueue addOperation:op];
            }
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
    } else if (filtType == filtGroup) {
        NSPredicate *groupPredicate;
        if ([[sourceListController filter] torrentGroup] != nil) {
            groupPredicate = [NSPredicate predicateWithFormat:@"group == %d", [[[sourceListController filter] torrentGroup] gid]];
        } else {
            // no group
            groupPredicate = [NSPredicate predicateWithFormat:@"group == 0"];
        }
        [allPredicates addObject:groupPredicate];
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
    
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Add"];
    if ([torrentFiles count] > 1) {
        [alert setMessageText:@"Are you sure you want to add these torrents?"];
    } else {
        [alert setMessageText:@"Are you sure you want to add this torrent?"];
    }
    NSMutableArray *displayNames = [NSMutableArray array];
    for (NSString *path in torrentFiles) {
        [displayNames addObject:[[NSFileManager defaultManager] displayNameAtPath:path]];
    }
    [alert setInformativeText:[displayNames componentsJoinedByString:@"\n"]];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSDictionary *context = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSArray arrayWithArray:torrentFiles], @"add", nil] forKeys:[NSArray arrayWithObjects:@"paths", @"type", nil]];
    
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:context];
    
    return YES;
}

@end
