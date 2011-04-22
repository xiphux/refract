//
//  NotificationController.m
//  Refract
//
//  Created by xiphux on 4/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "NotificationController.h"

#import "RFUtils.h"
#import "RFConstants.h"

static NotificationController *sharedInstance = nil;

@interface NotificationController ()
- (void)doNotifyDownloadAdded:(RFTorrent *)torrent;
- (void)doNotifyDownloadRemoved:(RFTorrent *)torrent;
- (void)doNotifyDownloadFinished:(RFTorrent *)torrent;
- (void)doNotifyMultipleAdded:(NSUInteger)count;
- (void)doNotifyMultipleRemoved:(NSUInteger)count;
- (void)doNotifyMultipleFinished:(NSUInteger)count;
@end

@implementation NotificationController

@synthesize queueing;

- (id)init
{
    @synchronized(self) {
        self = [super init];
        if (self) {
            
            queuedDownloadAdded = [NSMutableArray array];
            queuedDownloadRemoved = [NSMutableArray array];
            queuedDownloadFinished = [NSMutableArray array];
            
            notificationQueue = [[NSOperationQueue alloc] init];
            
            [GrowlApplicationBridge setGrowlDelegate:self];
        }
        return self;
    }
}

- (void)dealloc
{
    [queuedDownloadAdded release];
    [queuedDownloadRemoved release];
    [queuedDownloadFinished release];
    
    [notificationQueue release];
    
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

- (void)setDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
    
    [appDefaults setObject:[NSNumber numberWithInt:1] forKey:REFRACT_USERDEFAULT_NOTIFICATION_DOWNLOAD_FINISHED];
    
    [defaults registerDefaults:appDefaults];
}

- (void)notifyDownloadFinished:(RFTorrent *)torrent
{
    if (!torrent) {
        return;
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:REFRACT_USERDEFAULT_NOTIFICATION_DOWNLOAD_FINISHED]) {
        return;
    }
    
    if (queueing) {
        [queuedDownloadFinished addObject:torrent];
    } else {
        [notificationQueue addOperation:[[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(doNotifyDownloadFinished:) object:torrent] autorelease]];
    }
}

- (void)doNotifyDownloadFinished:(RFTorrent *)torrent
{
    if (!torrent) {
        return;
    }
    
    NSString *title = @"Download Finished";
    
    NSString *desc = [NSString stringWithFormat:@"%@ (%@)", [torrent name], [RFUtils readableBytesDecimal:[torrent doneSize]]];
    
    [GrowlApplicationBridge notifyWithTitle:title description:desc notificationName:@"Download Finished" iconData:nil priority:0 isSticky:NO clickContext:nil];
}

- (void)notifyDownloadAdded:(RFTorrent *)torrent
{
    if (!torrent) {
        return;
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:REFRACT_USERDEFAULT_NOTIFICATION_DOWNLOAD_ADDED]) {
        return;
    }
    
    if (queueing) {
        [queuedDownloadAdded addObject:torrent];
    } else {
        [notificationQueue addOperation:[[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(doNotifyDownloadAdded:) object:torrent] autorelease]];
    }
}

- (void)doNotifyDownloadAdded:(RFTorrent *)torrent
{
    if (!torrent) {
        return;
    }
    
    NSString *title = @"Download Added";
    
    NSString *desc = [NSString stringWithFormat:@"%@ (%@)", [torrent name], [RFUtils readableBytesDecimal:[torrent doneSize]]];
    
    [GrowlApplicationBridge notifyWithTitle:title description:desc notificationName:@"Download Added" iconData:nil priority:0 isSticky:NO clickContext:nil];    
}

- (void)notifyDownloadRemoved:(RFTorrent *)torrent
{
    if (!torrent) {
        return;
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:REFRACT_USERDEFAULT_NOTIFICATION_DOWNLOAD_REMOVED]) {
        return;
    }   
    
    if (queueing) {
        [queuedDownloadRemoved addObject:torrent];
    } else {
        [notificationQueue addOperation:[[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(doNotifyDownloadRemoved:) object:self] autorelease]];
    }
}

- (void)doNotifyDownloadRemoved:(RFTorrent *)torrent
{
    if (!torrent) {
        return;
    }
    
    NSString *title = @"Download Removed";
    
    NSString *desc = [NSString stringWithFormat:@"%@ (%@)", [torrent name], [RFUtils readableBytesDecimal:[torrent doneSize]]];
    
    [GrowlApplicationBridge notifyWithTitle:title description:desc notificationName:@"Download Removed" iconData:nil priority:0 isSticky:NO clickContext:nil];        
}

- (void)doNotifyMultipleAdded:(NSUInteger)count
{
    if (count < 1) {
        return;
    }
    
    NSString *title = @"Downloads Added";
    
    NSString *desc = [NSString stringWithFormat:@"%d downloads added", count];
    
    [GrowlApplicationBridge notifyWithTitle:title description:desc notificationName:@"Download Added" iconData:nil priority:0 isSticky:NO clickContext:nil];
}

- (void)doNotifyMultipleRemoved:(NSUInteger)count
{
    if (count < 1) {
        return;
    }
    
    NSString *title = @"Downloads Removed";
    
    NSString *desc = [NSString stringWithFormat:@"%d downloads removed", count];
    
    [GrowlApplicationBridge notifyWithTitle:title description:desc notificationName:@"Download Removed" iconData:nil priority:0 isSticky:NO clickContext:nil];
}

- (void)doNotifyMultipleFinished:(NSUInteger)count
{
    if (count < 1) {
        return;
    }
    
    NSString *title = @"Downloads Finished";
    
    NSString *desc = [NSString stringWithFormat:@"%d downloads finished", count];
    
    [GrowlApplicationBridge notifyWithTitle:title description:desc notificationName:@"Download Finished" iconData:nil priority:0 isSticky:NO clickContext:nil];
}

- (void)startQueue
{
    @synchronized (self) {
        queueing = true;
    }
}

- (void)flushQueue
{
    [notificationQueue addOperation:[[NSBlockOperation blockOperationWithBlock:^{
        NSMutableArray *copyQueuedAdded = nil;
        NSMutableArray *copyQueuedRemoved = nil;
        NSMutableArray *copyQueuedFinished = nil;
        
        @synchronized (self) {
            queueing = false;
            
            if ([queuedDownloadAdded count] > 0) {
                copyQueuedAdded = [NSMutableArray arrayWithArray:queuedDownloadAdded];
                [queuedDownloadAdded removeAllObjects];
            }
            
            if ([queuedDownloadRemoved count] > 0) {
                copyQueuedRemoved = [NSMutableArray arrayWithArray:queuedDownloadRemoved];
                [queuedDownloadRemoved removeAllObjects];
            }
            
            if ([queuedDownloadFinished count] > 0) {
                copyQueuedFinished = [NSMutableArray arrayWithArray:queuedDownloadFinished];
                [queuedDownloadFinished removeAllObjects];
            }
        }
        
        if (copyQueuedAdded) {
            if ([copyQueuedAdded count] > 2) {
                [self doNotifyMultipleAdded:[copyQueuedAdded count]];
            } else {
                for (RFTorrent *t in copyQueuedAdded) {
                    [self doNotifyDownloadAdded:t];
                }
            }
        }
        
        if (copyQueuedRemoved) {
            if ([copyQueuedRemoved count] > 2) {
                [self doNotifyMultipleRemoved:[copyQueuedRemoved count]];
            } else {
                for (RFTorrent *t in copyQueuedRemoved) {
                    [self doNotifyDownloadRemoved:t];
                }
            }
        }
        
        if (copyQueuedFinished) {
            if ([copyQueuedFinished count] > 2) {
                [self doNotifyMultipleFinished:[copyQueuedFinished count]];
            } else {
                for (RFTorrent *t in copyQueuedFinished) {
                    [self doNotifyDownloadFinished:t];
                }
            }
        }
    }] autorelease]];
    
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
