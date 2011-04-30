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
    filtGroup
} RFTorrentFilterType;

@interface RFTorrentFilter : NSObject {
@private
    RFTorrentFilterType filterType;
    RFTorrentStatus torrentStatus;
    RFTorrentGroup *torrentGroup;
}

@property (readonly) RFTorrentFilterType filterType;
@property (readonly) RFTorrentStatus torrentStatus;
@property (readonly) RFTorrentGroup *torrentGroup;

- (bool)isEqual:(id)other;
- (NSUInteger)hash;

- (id)initWithFilter:(RFTorrentFilter *)filter;
- (id)initWithStatus:(RFTorrentStatus)initStatus;
- (id)initWithType:(RFTorrentFilterType)initType;
- (id)initwithGroup:(RFTorrentGroup *)group;

- (bool)checkTorrent:(RFTorrent *)t;

@end
