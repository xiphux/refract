//
//  TorrentItem.m
//  Refract
//
//  Created by xiphux on 4/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TorrentItem.h"
#import "RFTorrent.h"
#import "RFUtils.h"
#import "RFConstants.h"
#import "RFTorrentGroup.h"

@interface TorrentItem ()
- (void)updateUpperLabel;
- (void)updateLowerLabel;
- (void)torrentUpdated;
- (void)stopTorrent:(id)sender;
- (void)startTorrent:(id)sender;
- (void)removeTorrent:(id)sender;
- (void)deleteTorrent:(id)sender;
- (void)verifyTorrent:(id)sender;
- (void)reannounceTorrent:(id)sender;
- (NSMutableDictionary *)notificationData;
- (void)changeGroup:(id)sender;
@end

@implementation TorrentItem

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    id result = [super copyWithZone:zone];
    
    [result setDelegate:[self delegate]];
    return result;
}

- (void)dealloc
{
    [super dealloc];
}

@synthesize upperLabel;
@synthesize lowerLabel;
@synthesize actionButton;
@synthesize delegate;

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionButton:) name:NSPopUpButtonWillPopUpNotification object:actionButton];
    
    [self updateUpperLabel];
    [self updateLowerLabel];
}

- (void)setRepresentedObject:(id)newObject
{
    if ([self representedObject]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"TorrentUpdated" object:[self representedObject]];
    }
    
    [super setRepresentedObject:newObject];
    
    if ([self representedObject]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(torrentUpdated) name:@"TorrentUpdated" object:[self representedObject]];
    }
    
    [self torrentUpdated];
}

- (void)torrentUpdated
{
    [self updateUpperLabel];
    [self updateLowerLabel];
}

- (void)updateUpperLabel
{
    NSString *label = @"";
    
    if ([self representedObject]) {
        RFTorrent *t = [self representedObject];
        switch ([t status]) {
            case stDownloading:
                label = [NSString stringWithFormat:@"%@ of %@ (%.2f%%) - %@ remaining", [RFUtils readableBytesDecimal:[t currentSize]], [RFUtils readableBytesDecimal:[t doneSize]], [t percent], [RFUtils readableDuration:[t eta]]];
                break;
            case stSeeding:
                label = [NSString stringWithFormat:@"%@, uploaded %@ (Ratio: %.2f) - %@ remaining", [RFUtils readableBytesDecimal:[t doneSize]], [RFUtils readableBytesDecimal:[t uploadedSize]], [t ratio], [RFUtils readableDuration:[t eta]]];
                break;
            case stStopped:
                label = [NSString stringWithFormat:@"%@, uploaded %@ (Ratio: %.2f)", [RFUtils readableBytesDecimal:[t doneSize]], [RFUtils readableBytesDecimal:[t uploadedSize]], [t ratio]];
                break;
        }
    }
    
    [upperLabel setStringValue:label];
}

- (void)updateLowerLabel
{
    NSString *label = @"";
    
    if ([self representedObject]) {
        RFTorrent *t = [self representedObject];
        switch ([t status]) {
            case stDownloading:
                label = [NSString stringWithFormat:@"Downloading from %d of %d peers - DL: %@, UL: %@", [t peersDownload], [t peersConnected], [RFUtils readableRateDecimal:[t downloadRate]], [RFUtils readableRateDecimal:[t uploadRate]]];
                break;
            case stSeeding:
                label = [NSString stringWithFormat:@"Seeding to %d of %d peers - UL: %@", [t peersUpload], [t peersConnected], [RFUtils readableRateDecimal:[t uploadRate]]];
                break;
            case stStopped:
                label = [NSString stringWithFormat:@"Stopped"];
                break;
        }
    }
    
    [lowerLabel setStringValue:label];
}

- (void)actionButton:(NSNotification *)notification
{
    NSMenu *menu = [actionButton menu];
    
    NSMenuItem *title = [menu itemAtIndex:0];
    
    [menu removeAllItems];
    
    [menu addItem:title];
    
    RFTorrent *t = [self representedObject];
    
    if ([t status] != stStopped) {
        NSMenuItem *stop = [[NSMenuItem alloc] initWithTitle:@"Stop" action:@selector(stopTorrent:) keyEquivalent:@""];
        [stop setTarget:self];
        [menu addItem:stop];
    } else {
        NSMenuItem *start = [[NSMenuItem alloc] initWithTitle:@"Start" action:@selector(startTorrent:) keyEquivalent:@""];
        [start setTarget:self];
        [menu addItem:start];
    }
    
    NSMenuItem *remove = [[NSMenuItem alloc] initWithTitle:@"Remove" action:@selector(removeTorrent:) keyEquivalent:@""];
    [remove setTarget:self];
    [menu addItem:remove];
        
    NSMenuItem *delete = [[NSMenuItem alloc] initWithTitle:@"Remove and Delete" action:@selector(deleteTorrent:) keyEquivalent:@""];
    [delete setTarget:self];
    [delete setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [delete setAlternate:true];
    [menu addItem:delete];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *verifyItem = [[NSMenuItem alloc] initWithTitle:@"Verify" action:@selector(verifyTorrent:) keyEquivalent:@""];
    [verifyItem setTarget:self];
    [menu addItem:verifyItem];
    
    NSMenuItem *reannounce = [[NSMenuItem alloc] initWithTitle:@"Reannounce" action:@selector(reannounceTorrent:) keyEquivalent:@""];
    [reannounce setTarget:self];
    [menu addItem:reannounce];
    
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(torrentItemAvailableGroups:)]) {
    
        [menu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *groupMenuItem = [[NSMenuItem alloc] initWithTitle:@"Group" action:nil keyEquivalent:@""];
        [groupMenuItem setTitle:@"Group"];
        
        NSMenu *groupSubMenu = [[NSMenu alloc] initWithTitle:@"Group"];        
        [groupMenuItem setSubmenu:groupSubMenu];
        
        NSMenuItem *noGroup = [[NSMenuItem alloc] initWithTitle:@"No Group" action:@selector(changeGroup:) keyEquivalent:@""];
        [noGroup setTag:0];
        [noGroup setTarget:self];
        if ([[self representedObject] group] == 0) {
            [noGroup setState:NSOnState];
        }
        [groupSubMenu addItem:noGroup];
        
        NSArray *groups = [[self delegate] torrentItemAvailableGroups:self];
        if (groups && ([groups count] > 0)) {
            [groupSubMenu addItem:[NSMenuItem separatorItem]];
            NSArray *sortedGroups = [groups sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"name" ascending:true] autorelease]]];
            for (NSUInteger i = 0; i < [sortedGroups count]; i++) {
                RFTorrentGroup *group = [sortedGroups objectAtIndex:i];
                NSMenuItem *groupItem = [[NSMenuItem alloc] initWithTitle:[group name] action:@selector(changeGroup:) keyEquivalent:@""];
                [groupItem setTag:[group gid]];
                [groupItem setTarget:self];
                if ([group gid] == [[self representedObject] group]) {
                    [groupItem setState:NSOnState];
                }
                [groupSubMenu addItem:groupItem];
            }
        }
        [menu addItem:groupMenuItem];
    }
}

- (void)changeGroup:(id)sender
{
    NSUInteger gid = [sender tag];
    
    if ([[self representedObject] group] == gid) {
        return;
    }
    
    [[self representedObject] setGroup:gid];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRACT_NOTIFICATION_TORRENT_GROUP_CHANGED object:self userInfo:[self notificationData]];
}

- (NSMutableDictionary *)notificationData
{
    return [NSMutableDictionary dictionaryWithObject:[self representedObject] forKey:@"torrent"];
}

- (void)startTorrent:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRACT_NOTIFICATION_TORRENT_START object:self userInfo:[self notificationData]];
}

- (void)stopTorrent:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRACT_NOTIFICATION_TORRENT_STOP object:self userInfo:[self notificationData]];   
}

- (void)removeTorrent:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRACT_NOTIFICATION_TORRENT_REMOVE object:self userInfo:[self notificationData]];
}

- (void)deleteTorrent:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRACT_NOTIFICATION_TORRENT_DELETE object:self userInfo:[self notificationData]];
}

- (void)verifyTorrent:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRACT_NOTIFICATION_TORRENT_VERIFY object:self userInfo:[self notificationData]];
}

- (void)reannounceTorrent:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRACT_NOTIFICATION_TORRENT_REANNOUNCE object:self userInfo:[self notificationData]];
}

@end
