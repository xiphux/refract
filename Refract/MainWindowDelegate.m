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
#import "NotificationController.h"
#import "RFServerList.h"
#import "RFAlert.h"

#import "RFEngineTransmission.h"

@interface MainWindowDelegate ()

- (void)setDefaults;

- (void)updateStatsButton;
- (void)updateDockBadge;

- (void)settingsChanged:(NSNotification *)notification;

- (void)alertDidEnd:(RFAlert *)alert returnCode:(NSInteger)returnCode
        contextInfo:(void *)contextInfo;

- (void)changeGroup:(id)sender;

- (void)sleepNotified:(NSNotification *)notification;
- (void)wakeNotified:(NSNotification *)notification;

- (void)tryRemoveTorrents:(NSArray *)torrents;
- (void)tryDeleteTorrents:(NSArray *)torrents;

@end

@implementation MainWindowDelegate

- (id)init
{
    self = [super init];
    if (self) {
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
    
    [activeServer release];

    [super dealloc];
}

- (RFServer *)activeServer
{
    return activeServer;
}

- (void)setActiveServer:(RFServer *)newActiveServer
{
    if (activeServer) {
        if ([[activeServer engine] type] == engTransmission) {
            [[activeServer engine] removeObserver:self forKeyPath:@"speedLimit"];
        }
    }
    
    [activeServer release];
    
    activeServer = [newActiveServer retain];
    
    if (activeServer) {
        if ([[activeServer engine] type] == engTransmission) {
            [[activeServer engine] addObserver:self forKeyPath:@"speedLimit" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:NULL];
            [speedLimitButton setHidden:false];
            if ([(RFEngineTransmission *)[activeServer engine] speedLimit]) {
                [speedLimitButton setSelectedSegment:1];
            } else {
                [speedLimitButton setSelectedSegment:0];
            }
        } else {
            [speedLimitButton setHidden:true];
        }
    }
}

- (void)awakeFromNib
{
    [self setDefaults];
    
    [[RFServerList sharedServerList] addObserver:self forKeyPath:@"servers" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:NULL];
    
    for (RFServer *srv in [[RFServerList sharedServerList] servers]) {
        [srv setDelegate:self];
    }
    
    [window registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    
    [removeButton setMenu:removeMenu forSegment:0];
    
    [actionButton setMenu:actionMenu forSegment:0];
    
    [startStopButton setMenu:stopMenu forSegment:0];
    [startStopButton setMenu:startMenu forSegment:1];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(sleepNotified:) name: NSWorkspaceWillSleepNotification object: nil];
    
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self selector: @selector(wakeNotified:) name: NSWorkspaceDidWakeNotification object: nil];
}

- (void)setDefaults
{
    NSMutableDictionary *def = [NSMutableDictionary dictionary];
    
    [def setObject:[NSNumber numberWithInt:(int)statRate] forKey:REFRACT_USERDEFAULT_STAT_TYPE];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:def];
}


#pragma mark server delegate

- (void)serverDidRefreshTorrents:(RFServer *)srv
{
    [sourceListController updateServer:srv];
    
    if ([activeServer isEqual:srv]) {
        [torrentListController rearrangeObjects];
        
        [self updateDockBadge];
        [self updateStatsButton];
    }
}

- (void)serverDidRefreshStats:(RFServer *)server
{
    [self updateStatsButton];
}


#pragma mark source list delegate

- (void)sourceList:(SourceListController *)list server:(RFServer *)server filterDidChange:(RFTorrentFilter *)newFilter
{
    if ([list isEqual:sourceListController]) {
        
        if (![server isEqual:activeServer]) {
            [self setActiveServer:server];
        }
        
        [torrentListController setFilter:newFilter];
        
        [self updateStatsButton];
    }
}


#pragma mark ui actions

- (IBAction)statsButtonClick:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setInteger:[sender tag] forKey:REFRACT_USERDEFAULT_STAT_TYPE];
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
        [activeServer stopTorrents:selected];
    } else if (clickedSegmentTag == 1) {
        // start
        [activeServer startTorrents:selected];
    }
}

- (IBAction)startClicked:(id)sender
{    
    NSArray *selected = [torrentListController selectedObjects];
    if ([selected count] < 1) {
        return;
    }
    
    [activeServer startTorrents:selected];
}

- (IBAction)startAllClicked:(id)sender
{
    [activeServer startAllTorrents];
}

- (IBAction)stopClicked:(id)sender
{    
    NSArray *selected = [torrentListController selectedObjects];
    if ([selected count] < 1) {
        return;
    }
    
    [activeServer stopTorrents:selected];
}

- (IBAction)stopAllClicked:(id)sender
{
    [activeServer stopAllTorrents];
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

- (void)alertDidEnd:(RFAlert *)alert returnCode:(NSInteger)returnCode
        contextInfo:(void *)contextInfo
{
    switch ([alert type]) {
        case alertConfirmRemove:
            if (returnCode == NSAlertSecondButtonReturn) {
                [activeServer removeTorrents:[alert torrents] deleteData:false];
            }
            break;
            
        case alertConfirmDelete:
            if (returnCode == NSAlertSecondButtonReturn) {
                [activeServer removeTorrents:[alert torrents] deleteData:true];
            }
            break;
            
        case alertConfirmAdd:
            if (returnCode == NSAlertSecondButtonReturn) {
                [activeServer addTorrents:[alert paths]];
            }
            break;
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
            [activeServer addTorrentFile:url];
        }
    }
}

- (void)changeGroup:(id)sender
{
    if ([[torrentListController selectedObjects] count] == 0) {
        return;
    }
    
    NSUInteger gid = [sender tag];
    [[activeServer torrentList] setGroup:gid forTorrents:[torrentListController selectedObjects]];
    [torrentListController rearrangeObjects];
}

- (IBAction)verifyClicked:(id)sender
{
    NSArray *selected = [torrentListController selectedObjects];
    if ([selected count] < 1) {
        return;
    }
    
    [activeServer verifyTorrents:selected];
}

- (IBAction)reannounceClicked:(id)sender
{
    NSArray *selected = [torrentListController selectedObjects];
    if ([selected count] < 1) {
        return;
    }
    
    [activeServer reannounceTorrents:selected];
}


- (IBAction)speedLimitClicked:(id)sender
{
    NSInteger clickedSegment = [sender selectedSegment];
    
    if (!([[activeServer engine] type] == engTransmission)) {
        return;
    }
    
    if (clickedSegment == 0) {
        // disable speed limit
        [(RFEngineTransmission *)[activeServer engine] setSpeedLimit:false];
    } else {
        // enable speed limit
        [(RFEngineTransmission *)[activeServer engine] setSpeedLimit:true];
    }
}


#pragma mark notifications

- (void)settingsChanged:(NSNotification *)notification
{

}

- (void)sleepNotified:(NSNotification *)notification
{
}

- (void)wakeNotified:(NSNotification *)notification
{
}


#pragma mark key change observations

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:[RFServerList sharedServerList]]) {
        if ([keyPath isEqualToString:@"servers"]) {
            NSKeyValueChange changeKind = [[change objectForKey:NSKeyValueChangeKindKey] intValue];
            if (changeKind == NSKeyValueChangeRemoval || changeKind == NSKeyValueChangeReplacement) {
                NSArray *removedList = [change objectForKey:NSKeyValueChangeOldKey];
                if (removedList) {
                    for (RFServer *oldServer in removedList) {
                        [oldServer setDelegate:nil];
                    }
                }
            }
            if (changeKind == NSKeyValueChangeInsertion || changeKind == NSKeyValueChangeReplacement) {
                NSArray *addedList = [change objectForKey:NSKeyValueChangeNewKey];
                if (addedList) {
                    for (RFServer *newServer in addedList) {
                        [newServer setDelegate:self];
                    }
                }
            }
        }
    } else if ([object isEqual:[activeServer engine]]) {
        if ([keyPath isEqualToString:@"speedLimit"]) {
            if ([(RFEngineTransmission *)[activeServer engine] speedLimit]) {
                [speedLimitButton setSelectedSegment:1];
            } else {
                [speedLimitButton setSelectedSegment:0];
            }
        }
    }
}


#pragma mark utility functions

- (void)updateStatsButton
{
    NSString *label;
    switch ([[NSUserDefaults standardUserDefaults] integerForKey:REFRACT_USERDEFAULT_STAT_TYPE]) {
        case statRate:
            label = [NSString stringWithFormat:@"D: %@ U: %@", [RFUtils readableRateDecimal:[[activeServer engine] downloadSpeed]], [RFUtils readableRateDecimal:[[activeServer engine] uploadSpeed]]];
            break;
        case statSession:
            label = [NSString stringWithFormat:@"Session D: %@ U: %@", [RFUtils readableBytesDecimal:[[activeServer engine] sessionDownloadedBytes]], [RFUtils readableBytesDecimal:[[activeServer engine] sessionUploadedBytes]]];
            break;
        case statTotal:
            label = [NSString stringWithFormat:@"Total D: %@ U: %@", [RFUtils readableBytesDecimal:[[activeServer engine] totalDownloadedBytes]], [RFUtils readableBytesDecimal:[[activeServer engine] totalUploadedBytes]]];
        case statCount:
        default:
            label = [NSString stringWithFormat:@"%d torrents", [[torrentListController arrangedObjects] count]];
            break;
    }
    NSMenuItem *statsTitle = [[statsButton menu] itemAtIndex:0];
    [statsTitle setTitle:label];
    [statsButton sizeToFit];
    
    NSRect torrentListRect = [[statsButton superview] frame];
    NSRect statButtonRect = [statsButton frame];
    statButtonRect.origin.x = (torrentListRect.size.width / 2) - (statButtonRect.size.width / 2);
    [statsButton setFrame:statButtonRect];
}

- (void)updateDockBadge
{
    NSUInteger activeCount = [[[[activeServer torrentList] torrents] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"status == %d", stDownloading]] count];
    
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
    
    RFAlert *alert = [[[RFAlert alloc] init] autorelease];
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
    
    [alert setType:alertConfirmRemove];
    [alert setTorrents:torrents];
    
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)tryDeleteTorrents:(NSArray *)torrents
{
    if (!torrents) {
        return;
    }
    
    if ([torrents count] == 0) {
        return;
    }
    
    RFAlert *alert = [[[RFAlert alloc] init] autorelease];
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
    
    [alert setType:alertConfirmDelete];
    [alert setTorrents:torrents];
    
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)tryAddTorrents:(NSArray *)files
{
    if (!files) {
        return;
    }
    
    if ([files count] == 0) {
        return;
    }
    
    RFAlert *alert = [[[RFAlert alloc] init] autorelease];
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
    
    [alert setType:alertConfirmAdd];
    [alert setPaths:files];
    
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
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
    if (activeServer && [activeServer started]) {
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
    if (![activeServer groupList]) {
        return nil;
    }
    
    return [[activeServer groupList] groups];
}

- (void)torrentItem:(TorrentItem *)item startTorrent:(RFTorrent *)torrent
{
    if (!torrent) {
        return;
    }
    
    [activeServer startTorrents:[NSArray arrayWithObject:torrent]];
}

- (void)torrentItem:(TorrentItem *)item stopTorrent:(RFTorrent *)torrent
{
    if (!torrent) {
        return;
    }
    
    [activeServer stopTorrents:[NSArray arrayWithObject:torrent]];
}

- (void)torrentItem:(TorrentItem *)item removeTorrent:(RFTorrent *)torrent deleteData:(bool)del
{
    if (!torrent) {
        return;
    }
    
    if (del) {
        [self tryDeleteTorrents:[NSArray arrayWithObject:torrent]];
    } else {
        [self tryRemoveTorrents:[NSArray arrayWithObject:torrent]];
    }
}

- (void)torrentItem:(TorrentItem *)item verifyTorrent:(RFTorrent *)torrent
{
    if (!torrent) {
        return;
    }
    
    [activeServer verifyTorrents:[NSArray arrayWithObject:torrent]];
}

- (void)torrentItem:(TorrentItem *)item reannounceTorrent:(RFTorrent *)torrent
{
    if (!torrent) {
        return;
    }
    
    [activeServer reannounceTorrents:[NSArray arrayWithObject:torrent]];
}

- (void)torrentItem:(TorrentItem *)item torrent:(RFTorrent *)torrent changeGroup:(NSUInteger)gid
{
    if (!torrent) {
        return;
    }
    
    [[activeServer torrentList] setGroup:gid forTorrents:[NSArray arrayWithObject:torrent]];
    [torrentListController rearrangeObjects];
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
        NSMenu *groupSubMenu = [[[NSMenu alloc] initWithTitle:@"Group"] autorelease];
        
        [menu setSubmenu:groupSubMenu forItem:groupMenuItem];
        
        NSMenuItem *noGroup = [[[NSMenuItem alloc] initWithTitle:@"No Group" action:@selector(changeGroup:) keyEquivalent:@""] autorelease];
        [noGroup setTag:0];
        [noGroup setTarget:self];
        [groupSubMenu addItem:noGroup];
        
        if ([[[activeServer groupList] groups] count] > 0) {
            [groupSubMenu addItem:[NSMenuItem separatorItem]];
            NSArray *sortedGroups = [[[activeServer groupList] groups] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:true] autorelease]]];
            for (NSUInteger i = 0; i < [sortedGroups count]; i++) {
                RFTorrentGroup *group = [sortedGroups objectAtIndex:i];
                NSMenuItem *groupItem = [[[NSMenuItem alloc] initWithTitle:[group name] action:@selector(changeGroup:) keyEquivalent:@""] autorelease];
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
    
    if ([menu isEqual:statsMenu]) {
        StatType type = [[NSUserDefaults standardUserDefaults] integerForKey:REFRACT_USERDEFAULT_STAT_TYPE];
        for (NSUInteger i = 1; i <= 4; i++) {
            NSMenuItem *item = [menu itemAtIndex:i];
            if (i == type) {
                [item setState:NSOnState];
            } else {
                [item setState:NSOffState];
            }
        }
    }
}

@end
