//
//  RFTorrentList.h
//  Refract
//
//  Created by xiphux on 4/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RFTorrent.h"

typedef enum {
    grNone,
    grStatus
} RFTorrentGrouping;

@interface RFTorrentList : NSObject {
@private
    NSArray *allTorrents;
    NSMutableArray *torrents;
    RFTorrentGrouping filterType;
    RFTorrentStatus filterStatus;
}

@property (retain) NSMutableArray *torrents;
@property (readonly) RFTorrentGrouping filterType;
@property (readonly) RFTorrentStatus filterStatus;

- (NSUInteger)countOfTorrents;
- (id)objectInTorrentsAtIndex:(NSUInteger)index;
- (void)insertObject:(RFTorrent *)torrent inTorrentsAtIndex:(NSUInteger)index;
- (void)removeObjectFromTorrentsAtIndex:(NSUInteger)index;
- (void)replaceObjectInTorrentsAtIndex:(NSUInteger)index withObject:(RFTorrent *)anObject;

- (void)loadTorrents:(NSArray *)torrentList;
- (void)filterAll;
- (void)filterByStatus:(RFTorrentStatus)status;

@end
