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
    
    unsigned long currentSize;
    unsigned long doneSize;
    unsigned long totalSize;
    
    unsigned long uploadRate;
    unsigned long downloadRate;

    RFTorrentStatus status;
}

@property(copy) NSString *name;
@property(copy) NSString *tid;
@property unsigned long currentSize;
@property unsigned long doneSize;
@property unsigned long totalSize;
@property unsigned long uploadRate;
@property unsigned long downloadRate;
@property RFTorrentStatus status;

@end
