//
//  RFTorrent.h
//  Refract
//
//  Created by xiphux on 4/2/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    Waiting,
    Checking,
    Downloading,
    Seeding,
    Stopped
} RFTorrentStatus;

@interface RFTorrent : NSObject {
@private
    
    NSString *name;
    NSString *tid;
    
    int currentSize;
    int doneSize;
    int totalSize;
    
    int uploadRate;
    int downloadRate;

    RFTorrentStatus status;
}

@property(copy) NSString *name;
@property(copy) NSString *tid;
@property int currentSize;
@property int doneSize;
@property int totalSize;
@property int uploadRate;
@property int downloadRate;
@property RFTorrentStatus status;

@end
