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

@interface TorrentItem ()
- (void)updateUpperLabel;
- (void)updateLowerLabel;
- (void)torrentUpdated;
- (void)stopTorrent:(id)sender;
- (void)startTorrent:(id)sender;
- (void)removeTorrent:(id)sender;
- (void)deleteTorrent:(id)sender;
- (NSDictionary *)notificationData;
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

- (void)dealloc
{
    [super dealloc];
}

@synthesize upperLabel;
@synthesize lowerLabel;
@synthesize actionButton;

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
    
    NSMenuItem *groupMenu = [[NSMenuItem alloc] init];
    [groupMenu setTitle:@"Group"];
    
    [menu addItem:groupMenu];
}

- (NSDictionary *)notificationData
{
    return [NSDictionary dictionaryWithObject:[self representedObject] forKey:@"torrent"];
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

@end
