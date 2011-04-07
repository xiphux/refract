//
//  RFTorrentList.h
//  Refract
//
//  Created by xiphux on 4/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFTorrentGroup.h"

typedef enum {
    grStatus
} RFTorrentGrouping;

@interface RFTorrentList : NSObject {
@private
    NSMutableArray *torrentGroups;
    RFTorrentGrouping grouping;
}

@property (retain) NSMutableArray *torrentGroups;
@property RFTorrentGrouping grouping;

- (id)initWithGrouping:(RFTorrentGrouping)initGrouping;

- (NSUInteger)countOfTorrentGroups;
- (id)objectInTorrentGroupsAtIndex:(NSUInteger)index;
- (void)insertObject:(RFTorrentGroup *)group inTorrentGroupsAtIndex:(NSUInteger)index;
- (void)removeObjectFromTorrentGroupsAtIndex:(NSUInteger)index;
- (void)replaceObjectInTorrentGroupsAtIndex:(NSUInteger)index withObject:(RFTorrentGroup *)anObject;
- (void)addTorrentGroupsObject:(RFTorrentGroup *)anObject;
- (void)removeTorrentGroupsObject:(RFTorrentGroup *)anObject;

- (void)loadTorrents:(NSArray *)torrents;

@end
