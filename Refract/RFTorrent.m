//
//  RFTorrent.m
//  Refract
//
//  Created by xiphux on 4/2/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import "RFTorrent.h"
#import "NotificationController.h"

@implementation RFTorrent

- (id)init
{
    return [self initWithTid:nil];
}

- (id)initWithTid:(NSString *)initTid
{
    self = [super init];
    if (self) {
        tid = [NSString stringWithString:initTid];
    }
    
    return self;
}

- (void)dealloc
{
    [name release];
    [tid release];
    [super dealloc];
}

@synthesize tid;

- (NSString *)name  
{
    return name;
}

- (void)setName:(NSString *)newName
{
    if ([name isEqualToString:newName]) {
        return;
    }
    
    name = [NSString stringWithString:newName];
    
    updated = true;
}

- (unsigned long)currentSize
{
    return currentSize;
}

- (void)setCurrentSize:(unsigned long)newCurrentSize
{
    if (currentSize == newCurrentSize) {
        return;
    }
    
    currentSize = newCurrentSize;

    updated = true;
}

- (unsigned long)doneSize
{
    return doneSize;
}

- (void)setDoneSize:(unsigned long)newDoneSize
{
    if (doneSize == newDoneSize) {
        return;
    }
    
    doneSize = newDoneSize;
    
    updated = true;
}

- (unsigned long)totalSize
{
    return totalSize;
}

- (void)setTotalSize:(unsigned long)newTotalSize
{
    if (totalSize == newTotalSize) {
        return;
    }
    
    totalSize = newTotalSize;
    
    updated = true;
}

- (unsigned long)uploadRate
{
    return uploadRate;
}

- (void)setUploadRate:(unsigned long)newUploadRate
{
    if (uploadRate == newUploadRate) {
        return;
    }
    
    uploadRate = newUploadRate;
    
    updated = true;
}

- (unsigned long)downloadRate
{
    return downloadRate;
}

- (void)setDownloadRate:(unsigned long)newDownloadRate
{
    if (downloadRate == newDownloadRate) {
        return;
    }
    
    downloadRate = newDownloadRate;
    
    updated = true;
}

- (RFTorrentStatus)status
{
    return status;
}

- (void)setStatus:(RFTorrentStatus)newStatus
{
    if (status == newStatus) {
        return;
    }
    
    if ((status == stDownloading) && (newStatus > 0)) {
        downloadJustFinished = true;
    }
    
    status = newStatus;
    
    updated = true;
}

- (double)percent
{
    return percent;
}

- (void)setPercent:(double)newPercent
{
    if (percent == newPercent) {
        return;
    }
    
    percent = newPercent;
    
    updated = true;
}

- (unsigned long)peersConnected
{
    return peersConnected;
}

- (void)setPeersConnected:(unsigned long)newPeersConnected
{
    if (peersConnected == newPeersConnected) {
        return;
    }
    
    peersConnected = newPeersConnected;
    
    updated = true;
}

- (unsigned long)peersUpload
{
    return peersUpload;
}

- (void)setPeersUpload:(unsigned long)newPeersUpload
{
    if (peersUpload == newPeersUpload) {
        return;
    }
    
    peersUpload = newPeersUpload;
    
    updated = true;
}

- (unsigned long)peersDownload
{
    return peersDownload;
}

- (void)setPeersDownload:(unsigned long)newPeersDownload
{
    if (peersDownload == newPeersDownload) {
        return;
    }
    
    peersDownload = newPeersDownload;
    
    updated = true;
}

- (long)eta
{
    return eta;
}

- (void)setEta:(long)newEta
{
    if (eta == newEta) {
        return;
    }
    
    eta = newEta;
    
    updated = true;
}

- (double)recheckPercent
{
    return recheckPercent;
}

- (void)setRecheckPercent:(double)newRecheckPercent
{
    if (recheckPercent == newRecheckPercent) {
        return;
    }
    
    recheckPercent = newRecheckPercent;
    
    updated = true;
}

- (double)ratio
{
    return ratio;
}

- (void)setRatio:(double)newRatio
{
    if (ratio == newRatio) {
        return;
    }
    
    ratio = newRatio;
    
    updated = true;
}

- (unsigned long)uploadedSize
{
    return uploadedSize;
}

- (void)setUploadedSize:(unsigned long)newUploadedSize
{
    if (uploadedSize == newUploadedSize) {
        return;
    }
    
    uploadedSize = newUploadedSize;
    
    updated = true;
}

- (time_t)doneDate
{
    return doneDate;
}

- (void)setDoneDate:(time_t)newDoneDate
{
    if (doneDate == newDoneDate) {
        return;
    }
    
    doneDate = newDoneDate;
    
    updated = true;
}

- (bool)isEqual:(id)other
{
    if (other == self) {
        return true;
    }
    if (!other || ![other isKindOfClass:[self class]]) {
        return false;
    }
    return [[self tid] isEqualToString:[other tid]];
}

- (NSUInteger)hash
{
    return [[self tid] hash];
}

- (bool)dataEqual:(RFTorrent *)other
{
    if (other == self) {
        return true;
    }
    if (!other) {
        return false;
    }
    return (
            [[self name] isEqualToString:[other name]] &&
            [[self tid] isEqualToString:[other tid]] &&
            ([self currentSize] == [other currentSize]) &&
            ([self doneSize] == [other doneSize]) &&
            ([self totalSize] == [other totalSize]) &&
            ([self uploadRate] == [other uploadRate]) &&
            ([self downloadRate] == [other downloadRate]) &&
            ([self status] == [other status]) &&
            ([self peersConnected] == [other peersConnected]) &&
            ([self peersUpload] == [other peersUpload]) &&
            ([self peersDownload] == [other peersDownload]) &&
            ([self eta] == [other eta]) &&
            ([self recheckPercent] == [other recheckPercent]) &&
            ([self ratio] == [other ratio]) &&
            ([self uploadedSize] == [other uploadedSize]) &&
            ([self doneDate] == [other doneDate])
            );
}

- (void)signalUpdated
{
    if (updated) {
        if (downloadJustFinished && (doneDate > 0)) {
            [[NotificationController sharedNotificationController] notifyDownloadFinished:self];
            downloadJustFinished = false;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TorrentUpdated" object:self];
        updated = false;
    }
}

@end
