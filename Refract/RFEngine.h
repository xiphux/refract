//
//  RFEngine.h
//  Refract
//
//  Created by xiphux on 4/2/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    engTransmission = 1
} RFEngineType;

#define REFRACT_RFENGINE_KEY_TYPE @"type"

@protocol RFEngineDelegate;

@interface RFEngine : NSObject <NSCoding> {
@protected
    NSObject <RFEngineDelegate> *delegate;
}

@property (nonatomic, assign) NSObject <RFEngineDelegate> *delegate;

- (bool)connect;
- (bool)disconnect;
- (bool)connected;
- (bool)refresh;
- (bool)startTorrents:(NSArray *)list;
- (bool)stopTorrents:(NSArray *)list;
- (bool)startAllTorrents;
- (bool)stopAllTorrents;
- (bool)verifyTorrents:(NSArray *)list;
- (bool)reannounceTorrents:(NSArray *)list;
- (bool)removeTorrents:(NSArray *)list deleteData:(bool)del;
- (bool)addTorrent:(NSData *)data;

- (NSDictionary *)torrents;
- (RFEngineType)type;
- (unsigned long)uploadSpeed;
- (unsigned long)downloadSpeed;
- (unsigned long)sessionUploadedBytes;
- (unsigned long)sessionDownloadedBytes;
- (unsigned long)totalUploadedBytes;
- (unsigned long)totalDownloadedBytes;

+ (id)engineOfType:(RFEngineType)type;
+ (id)engine;

@end

@protocol RFEngineDelegate <NSObject>
@optional
- (void)engine:(RFEngine *)engine requestDidFail:(NSString *)requestType;
- (void)engineDidRefreshTorrents:(RFEngine *)engine;
- (void)engineDidRefreshStats:(RFEngine *)engine;
@end
