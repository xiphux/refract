//
//  TorrentItem.h
//  Refract
//
//  Created by xiphux on 4/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFTorrent.h"

@protocol TorrentItemDelegate;

@interface TorrentItem : NSCollectionViewItem {
@private
    NSTextField IBOutlet *upperLabel;
    NSTextField IBOutlet *lowerLabel;
    NSPopUpButton IBOutlet *actionButton;
    
    NSObject <TorrentItemDelegate> IBOutlet *delegate;
}

@property (nonatomic, assign) NSObject <TorrentItemDelegate> *delegate;

- (void)actionButton:(NSNotification *)notification;

@end


@protocol TorrentItemDelegate <NSObject>
@optional
- (NSArray *)torrentItemAvailableGroups:(TorrentItem *)item;

- (void)torrentItem:(TorrentItem *)item startTorrent:(RFTorrent *)torrent;
- (void)torrentItem:(TorrentItem *)item stopTorrent:(RFTorrent *)torrent;
- (void)torrentItem:(TorrentItem *)item removeTorrent:(RFTorrent *)torrent deleteData:(bool)del;
- (void)torrentItem:(TorrentItem *)item verifyTorrent:(RFTorrent *)torrent;
- (void)torrentItem:(TorrentItem *)item reannounceTorrent:(RFTorrent *)torrent;
- (void)torrentItem:(TorrentItem *)item torrent:(RFTorrent *)torrent changeGroup:(NSUInteger)gid;
@end