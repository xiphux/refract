//
//  RFServer.h
//  Refract
//
//  Created by xiphux on 5/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RFEngine.h"
#import "RFTorrentList.h"
#import "RFGroupList.h"

@protocol RFServerDelegate;

@interface RFServer : NSObject <RFEngineDelegate, RFTorrentListDelegate, NSCoding> {
@private
    
    bool enabled;
    NSString *name;
    NSUInteger sid;
    NSUInteger updateFrequency;
    
    RFEngine *engine;
    RFTorrentList *torrentList;
    RFGroupList *groupList;
    
    bool started;
    NSTimer *refreshTimer;
    
    id <RFServerDelegate> delegate;
}

@property bool enabled;
@property (copy) NSString *name;
@property (readonly) NSUInteger sid;
@property NSUInteger updateFrequency;

@property (readonly) RFEngine *engine;
@property (readonly) RFTorrentList *torrentList;
@property (readonly) RFGroupList *groupList;

@property (readonly) bool started;

@property (nonatomic, assign) id <RFServerDelegate> delegate;

- (id)initWithId:(NSUInteger)initId;

- (void)startTorrents:(NSArray *)torrents;
- (void)stopTorrents:(NSArray *)torrents;
- (void)startAllTorrents;
- (void)stopAllTorrents;
- (void)removeTorrents:(NSArray *)torrents deleteData:(bool)del;
- (void)addTorrents:(NSArray *)files;
- (void)verifyTorrents:(NSArray *)torrents;
- (void)reannounceTorrents:(NSArray *)torrents;

- (void)addTorrentFile:(NSURL *)url;

- (bool)start;
- (bool)stop;
- (bool)refresh;

+ (NSUInteger)generateServerId;

@end


@protocol RFServerDelegate <NSObject>
@optional
- (void)serverDidRefreshTorrents:(RFServer *)server;
- (void)serverDidRefreshStats:(RFServer *)server;
@end