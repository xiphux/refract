//
//  RFTorrentFilter.h
//  Refract
//
//  Created by xiphux on 4/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RFTorrent.h"
#import "RFTorrentGroup.h"

typedef enum {
    filtNone,
    filtStatus,
    filtGroup,
    filtState
} RFTorrentFilterType;

typedef enum {
    stateComplete = 1,
    stateIncomplete = 2
} RFTorrentState;

@interface RFTorrentFilter : NSObject {
@private
    RFTorrentFilterType filterType;
    RFTorrentState torrentState;
    RFTorrentStatus torrentStatus;
    RFTorrentGroup *torrentGroup;
}

@property (readonly) RFTorrentFilterType filterType;
@property (readonly) RFTorrentStatus torrentStatus;
@property (readonly) RFTorrentState torrentState;
@property (readonly) RFTorrentGroup *torrentGroup;

- (bool)isEqual:(id)other;
- (NSUInteger)hash;

- (id)initWithFilter:(RFTorrentFilter *)filter;
- (id)initWithStatus:(RFTorrentStatus)initStatus;
- (id)initWithType:(RFTorrentFilterType)initType;
- (id)initwithGroup:(RFTorrentGroup *)group;
- (id)initWithState:(RFTorrentState)initState;

- (bool)checkTorrent:(RFTorrent *)t;
- (NSPredicate *)predicate;

@end
