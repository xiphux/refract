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

- (void)notifyDownloadFinished:(RFTorrent *)torrent;

+ (NotificationController *)sharedNotificationController;

@end
