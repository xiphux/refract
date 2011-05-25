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
    [upperLabel release];
    [lowerLabel release];
    [actionButton release];
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
        NSMenuItem *stop = [[[NSMenuItem alloc] initWithTitle:@"Stop" action:@selector(stopTorrent:) keyEquivalent:@""] autorelease];
        [stop setTarget:self];
        [menu addItem:stop];
    } else {
        NSMenuItem *start = [[[NSMenuItem alloc] initWithTitle:@"Start" action:@selector(startTorrent:) keyEquivalent:@""] autorelease];
        [start setTarget:self];
        [menu addItem:start];
    }
    
    NSMenuItem *remove = [[[NSMenuItem alloc] initWithTitle:@"Remove" action:@selector(removeTorrent:) keyEquivalent:@""] autorelease];
    [remove setTarget:self];
    [menu addItem:remove];
        
    NSMenuItem *delete = [[[NSMenuItem alloc] initWithTitle:@"Remove and Delete" action:@selector(deleteTorrent:) keyEquivalent:@""] autorelease];
    [delete setTarget:self];
    [delete setKeyEquivalentModifierMask:NSAlternateKeyMask];
    [delete setAlternate:true];
    [menu addItem:delete];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *verifyItem = [[[NSMenuItem alloc] initWithTitle:@"Verify" action:@selector(verifyTorrent:) keyEquivalent:@""] autorelease];
    [verifyItem setTarget:self];
    [menu addItem:verifyItem];
    
    NSMenuItem *reannounce = [[[NSMenuItem alloc] initWithTitle:@"Reannounce" action:@selector(reannounceTorrent:) keyEquivalent:@""] autorelease];
    [reannounce setTarget:self];
    [menu addItem:reannounce];
    
    if ([self delegate] && [[self delegate] respondsToSelector:@selector(torrentItemAvailableGroups:)]) {
    
        [menu addItem:[NSMenuItem separatorItem]];
        
        NSMenuItem *groupMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Group" action:nil keyEquivalent:@""] autorelease];
        [groupMenuItem setTitle:@"Group"];
        
        NSMenu *groupSubMenu = [[[NSMenu alloc] initWithTitle:@"Group"] autorelease];        
        [groupMenuItem setSubmenu:groupSubMenu];
        
        NSMenuItem *noGroup = [[[NSMenuItem alloc] initWithTitle:@"No Group" action:@selector(changeGroup:) keyEquivalent:@""] autorelease];
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
                NSMenuItem *groupItem = [[[NSMenuItem alloc] initWithTitle:[group name] action:@selector(changeGroup:) keyEquivalent:@""] autorelease];
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
    
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(torrentItem:torrent:changeGroup:)]) {
            [[self delegate] torrentItem:self torrent:[self representedObject] changeGroup:gid];
        }
    }
}

- (void)startTorrent:(id)sender
{
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(torrentItem:startTorrent:)]) {
            [[self delegate] torrentItem:self startTorrent:[self representedObject]];
        }
    }
}

- (void)stopTorrent:(id)sender
{  
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(torrentItem:stopTorrent:)]) {
            [[self delegate] torrentItem:self stopTorrent:[self representedObject]];
        }
    }
}

- (void)removeTorrent:(id)sender
{
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(torrentItem:removeTorrent:deleteData:)]) {
            [[self delegate] torrentItem:self removeTorrent:[self representedObject] deleteData:false];
        }
    }
}

- (void)deleteTorrent:(id)sender
{
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(torrentItem:removeTorrent:deleteData:)]) {
            [[self delegate] torrentItem:self removeTorrent:[self representedObject] deleteData:true];
        }
    }
}

- (void)verifyTorrent:(id)sender
{
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(torrentItem:verifyTorrent:)]) {
            [[self delegate] torrentItem:self verifyTorrent:[self representedObject]];
        }
    }
}

- (void)reannounceTorrent:(id)sender
{
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(torrentItem:reannounceTorrent:)]) {
            [[self delegate] torrentItem:self reannounceTorrent:[self representedObject]];;
        }
    }
}

@end
