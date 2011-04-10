//
//  RFTorrentFilter.h
//  Refract
//
//  Created by xiphux on 4/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RFTorrent.h"

typedef enum {
    filtNone,
    filtStatus
} RFTorrentFilterType;

@interface RFTorrentFilter : NSObject {
@private
    RFTorrentFilterType filterType;
    RFTorrentStatus torrentStatus;
}

@property (readonly) RFTorrentFilterType filterType;
@property (readonly) RFTorrentStatus torrentStatus;

- (bool)isEqual:(id)other;
- (NSUInteger)hash;

- (id)initWithFilter:(RFTorrentFilter *)filter;
- (id)initWithStatus:(RFTorrentStatus)initStatus;
- (id)initWithType:(RFTorrentFilterType)initType;

- (bool)checkTorrent:(RFTorrent *)t;

@end
