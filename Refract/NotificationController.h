//
//  NotificationController.h
//  Refract
//
//  Created by xiphux on 4/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RFTorrent.h"
#import "Growl/GrowlApplicationBridge.h"

@interface NotificationController : NSObject <GrowlApplicationBridgeDelegate> {
@private
    bool growlReady;
    
    bool queueing;
    
    NSMutableArray *queuedDownloadFinished;
    NSMutableArray *queuedDownloadAdded;
    NSMutableArray *queuedDownloadRemoved;
    
    NSOperationQueue *notificationQueue;
}

@property (readonly) bool queueing;

- (void)setDefaults;
- (void)notifyDownloadFinished:(RFTorrent *)torrent;
- (void)notifyDownloadAdded:(RFTorrent *)torrent;
- (void)notifyDownloadRemoved:(RFTorrent *)torrent;

- (void)startQueue;
- (void)flushQueue;

+ (NotificationController *)sharedNotificationController;

@end
