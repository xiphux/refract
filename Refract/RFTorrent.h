//
//  RFTorrent.h
//  Refract
//
//  Created by xiphux on 4/2/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    stWaiting = 1,
    stChecking = 2,
    stDownloading = 3,
    stSeeding = 4,
    stStopped = 5
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
    
    long eta;
    
    unsigned long peersConnected;
    unsigned long peersDownload;
    unsigned long peersUpload;
    
    double percent;
    double recheckPercent;

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
@property unsigned long peersConnected;
@property unsigned long peersDownload;
@property unsigned long peersUpload;
@property double recheckPercent;
@property long eta;

@property double percent;

- (bool)isEqual:(id)other;
- (bool)dataEqual:(RFTorrent *)other;
- (NSUInteger)hash;
- (void)signalUpdated;

@end
