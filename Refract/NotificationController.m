//
//  NotificationController.m
//  Refract
//
//  Created by xiphux on 4/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NotificationController.h"

#import "RFUtils.h"

static NotificationController *sharedInstance = nil;

@implementation NotificationController

- (id)init
{
    @synchronized(self) {
        self = [super init];
        if (self) {
            [GrowlApplicationBridge setGrowlDelegate:self];
        }
        return self;
    }
}

- (void)dealloc
{
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (void)release
{

}

- (id)autorelease
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;
}

- (NSString *)applicationNameForGrowl
{
    return @"Refract";
}

- (void)growlIsReady
{
    growlReady = true;
}

- (void)notifyDownloadFinished:(RFTorrent *)torrent
{
    NSString *title = @"Download Finished";
    
    NSString *desc = [NSString stringWithFormat:@"%@ (%@)", [torrent name], [RFUtils readableBytesDecimal:[torrent doneSize]]];
    
    [GrowlApplicationBridge notifyWithTitle:title description:desc notificationName:@"DownloadFinished" iconData:nil priority:0 isSticky:NO clickContext:nil];
}

+ (NotificationController *)sharedNotificationController
{
    @synchronized (self) {
        if (sharedInstance == nil) {
            [[self alloc] init];
        }
    }
    
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized (self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;
        }
    }
    
    return nil;
}

@end
