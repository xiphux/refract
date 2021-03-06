//
//  RFTorrentList.h
//  Refract
//
//  Created by xiphux on 4/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RFTorrent.h"
#import "RFTorrentFilter.h"

@protocol RFTorrentListDelegate;

@interface RFTorrentList : NSObject <NSCoding> {
@private
    NSArray *allTorrents;
    NSMutableArray *torrents;
    bool initialized;
    
    NSMutableDictionary *torrentGroups;
    bool saveGroups;
    
    id <RFTorrentListDelegate> delegate;
}

@property (retain) NSArray *torrents;
@property (nonatomic, assign) id <RFTorrentListDelegate> delegate;
@property bool initialized;
@property bool saveGroups;

- (NSUInteger)countOfTorrents;
- (id)objectInTorrentsAtIndex:(NSUInteger)index;
- (void)insertObject:(RFTorrent *)torrent inTorrentsAtIndex:(NSUInteger)index;
- (void)removeObjectFromTorrentsAtIndex:(NSUInteger)index;
- (void)replaceObjectInTorrentsAtIndex:(NSUInteger)index withObject:(RFTorrent *)anObject;

- (void)loadTorrents:(NSArray *)torrentList;
- (void)clearTorrents;

- (void)clearGroup:(RFTorrentGroup *)group;

- (void)setGroup:(NSUInteger)gid forTorrents:(NSArray *)list;

- (bool)containsStatus:(RFTorrentStatus)status;

- (bool)hasComplete;
- (bool)hasIncomplete;

@end


@protocol RFTorrentListDelegate <NSObject>
@optional
- (void)torrentListDidFinishLoading:(RFTorrentList *)list;
@end
