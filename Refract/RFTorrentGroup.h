//
//  RFTorrentGroup.h
//  Refract
//
//  Created by xiphux on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFTorrent.h"

@interface RFTorrentGroup : NSObject {
@private
    NSString *name;
    NSMutableArray *torrents;
}

@property (copy) NSString *name;
@property (retain) NSMutableArray *torrents;

- (id)initWithName:(NSString *)initName;

- (bool)isEqual:(id)other;
- (NSUInteger)hash;

- (NSUInteger)countOfTorrents;
- (id)objectInTorrentsAtIndex:(NSUInteger)index;
- (void)insertObject:(RFTorrent *)torrent inTorrentsAtIndex:(NSUInteger)index;
- (void)removeObjectFromTorrentsAtIndex:(NSUInteger)index;
- (void)replaceObjectInTorrentsAtIndex:(NSUInteger)index withObject:(RFTorrent *)torrent;
- (void)addTorrentsObject:(RFTorrent *)torrent;
- (void)removeTorrentsObject:(RFTorrent *)torrent;

@end
