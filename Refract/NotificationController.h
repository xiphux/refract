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
}

- (void)setDefaults;
- (void)notifyDownloadFinished:(RFTorrent *)torrent;
- (void)notifyDownloadAdded:(RFTorrent *)torrent;
- (void)notifyDownloadRemoved:(RFTorrent *)torrent;
- (void)notifyMultipleAdded:(NSUInteger)count;
- (void)notifyMultipleRemoved:(NSUInteger)count;

+ (NotificationController *)sharedNotificationController;

@end
