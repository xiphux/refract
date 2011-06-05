//
//  RFServer.m
//  Refract
//
//  Created by xiphux on 5/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RFServer.h"
#import "RFConstants.h"

#define REFRACT_RFSERVER_KEY_SID @"sid"
#define REFRACT_RFSERVER_KEY_NAME @"name"
#define REFRACT_RFSERVER_KEY_ENGINE @"engine"
#define REFRACT_RFSERVER_KEY_TORRENTLIST @"torrentList"
#define REFRACT_RFSERVER_KEY_GROUPLIST @"groupList"
#define REFRACT_RFSERVER_KEY_ENABLED @"enabled"
#define REFRACT_RFSERVER_KEY_UPDATEFREQUENCY @"updateFrequency"

@implementation RFServer

- (id)init
{
    return [self initWithId:[RFServer generateServerId]];
}

- (id)initWithId:(NSUInteger)initId
{
    self = [super init];
    if (self) {
        sid = initId;
        
        engine = [[RFEngine engine] retain];
        [engine setDelegate:self];
        
        [self willChangeValueForKey:@"torrentList"];
        torrentList = [[RFTorrentList alloc] init];
        [self didChangeValueForKey:@"torrentList"];
        [torrentList setDelegate:self];
        
        if ([engine type] == engTransmission) {
            [torrentList setSaveGroups:true];
        }
        
        groupList = [[RFGroupList alloc] init];
        
        enabled = true;
        
        updateFrequency = 5;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSUInteger serverId = [aDecoder decodeIntForKey:REFRACT_RFSERVER_KEY_SID];
    if (serverId < 1) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        sid = serverId;
        
        name = [[aDecoder decodeObjectForKey:REFRACT_RFSERVER_KEY_NAME] retain];
        
        engine = [[aDecoder decodeObjectForKey:REFRACT_RFSERVER_KEY_ENGINE] retain];
        [engine setDelegate:self];
        
        torrentList = [[aDecoder decodeObjectForKey:REFRACT_RFSERVER_KEY_TORRENTLIST] retain];
        [torrentList setDelegate:self];
        if ([engine type] == engTransmission) {
            [torrentList setSaveGroups:true];
        }
        
        groupList = [[aDecoder decodeObjectForKey:REFRACT_RFSERVER_KEY_GROUPLIST] retain];
        
        enabled = [aDecoder decodeBoolForKey:REFRACT_RFSERVER_KEY_ENABLED];
        
        updateFrequency = [aDecoder decodeIntForKey:REFRACT_RFSERVER_KEY_UPDATEFREQUENCY];
    }
    
    return self;
}

- (void)dealloc
{
    [engine release];
    [torrentList release];
    [groupList release];
    [name release];
    [refreshTimer invalidate];
    [refreshTimer release];
    
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:name forKey:REFRACT_RFSERVER_KEY_NAME];
    [aCoder encodeInt:sid forKey:REFRACT_RFSERVER_KEY_SID];
    [aCoder encodeObject:engine forKey:REFRACT_RFSERVER_KEY_ENGINE];
    [aCoder encodeObject:torrentList forKey:REFRACT_RFSERVER_KEY_TORRENTLIST];
    [aCoder encodeObject:groupList forKey:REFRACT_RFSERVER_KEY_GROUPLIST];
    [aCoder encodeBool:enabled forKey:REFRACT_RFSERVER_KEY_ENABLED];
    [aCoder encodeInt:updateFrequency forKey:REFRACT_RFSERVER_KEY_UPDATEFREQUENCY];
}

@synthesize enabled;
@synthesize name;
@synthesize sid;
@synthesize updateFrequency;

@synthesize engine;
@synthesize torrentList;
@synthesize groupList;

@synthesize started;

@synthesize delegate;

- (bool)enabled
{
    return enabled;
}

- (void)setEnabled:(bool)newEnabled
{
    if (enabled == newEnabled) {
        return;
    }
    
    enabled = newEnabled;
    
    if (enabled) {
        if (!started) {
            [self start];
        }
    } else {
        if (started) {
            [self stop];
        }
    }
}

- (NSUInteger)updateFrequency
{
    return updateFrequency;
}

- (void)setUpdateFrequency:(NSUInteger)newUpdateFrequency
{
    if (updateFrequency == newUpdateFrequency) {
        return;
    }
    
    if (newUpdateFrequency < 1) {
        newUpdateFrequency = 1;
    }
    
    bool needsupdate = (newUpdateFrequency < updateFrequency);
    
    updateFrequency = newUpdateFrequency;
    
    if (needsupdate && started) {
        [self refresh];
    }
}


#pragma mark torrent manipulation

- (void)startTorrents:(NSArray *)torrents
{
    if (!torrents) {
        return;
    }
    
    if ([torrents count] == 0) {
        return;
    }
    
    [engine startTorrents:torrents];   
}

- (void)stopTorrents:(NSArray *)torrents
{
    if (!torrents) {
        return;
    }
    
    if ([torrents count] == 0) {
        return;
    }
    
    [engine stopTorrents:torrents];
}

- (void)startAllTorrents
{
    [engine startAllTorrents];
}

- (void)stopAllTorrents
{
    [engine stopAllTorrents];
}

- (void)removeTorrents:(NSArray *)torrents deleteData:(bool)del
{
    if (!torrents) {
        return;
    }
    
    if ([torrents count] == 0) {
        return;
    }
    
    [engine removeTorrents:torrents deleteData:del];
}

- (void)addTorrents:(NSArray *)files
{
    if (!files) {
        return;
    }
    
    if ([files count] == 0) {
        return;
    }
    
    for (NSString *path in files) {
        NSURL *pathUrl = [NSURL fileURLWithPath:path];
        [self addTorrentFile:pathUrl];
        //NSInvocationOperation *op = [[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(addTorrentFile:) object:pathUrl] autorelease];
        //[updateQueue addOperation:op];
    }
}

- (void)verifyTorrents:(NSArray *)torrents
{
    if (!torrents) {
        return;
    }
    
    if ([torrents count] == 0) {
        return;
    }
    
    [engine verifyTorrents:torrents];
}

- (void)reannounceTorrents:(NSArray *)torrents
{
    if (!torrents) {
        return;
    }
    
    if ([torrents count] == 0) {
        return;
    }
    
    [engine reannounceTorrents:torrents];
}

- (void)addTorrentFile:(NSURL *)url
{
    NSFileWrapper *file = [[NSFileWrapper alloc] initWithURL:url options:0 error:nil];
    
    if (!file) {
        return;
    }
    
    NSData *fileContent = [file regularFileContents];
    [engine addTorrent:fileContent];
    
    [file release];
    
    return;
}


#pragma mark engine manipulation

- (bool)start
{
    if (started) {
        return true;
    }
    
    if (!engine) {
        return false;
    }
    
    if (![engine connected]) {
        [engine connect];
    }
    
    started = true;
    
    [self refresh];
    
    return true;
}

- (bool)stop
{
    if (!started) {
        return true;
    }
    
    if (!engine) {
        return false;
    }
    
    started = false;
    
    if ([engine connected]) {
        [engine disconnect];
    }
    
    return true;
}

- (bool)refresh
{
    if (refreshTimer) {
        [refreshTimer invalidate];
        [refreshTimer release];
    }
    
    if (!started) {
        return false;
    }
    
    [engine refresh];
    
    return true;
}


#pragma mark engine delegate

- (void)engine:(RFEngine *)eng requestDidFail:(NSString *)requestType
{
    if (![eng isEqual:engine]) {
        return;
    }
    
    if ([requestType isEqualToString:@"refresh"]) {
        [[self torrentList] clearTorrents];
        refreshTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)updateFrequency target:self selector:@selector(refresh) userInfo:nil repeats:false];
    }
}

- (void)engineDidRefreshTorrents:(RFEngine *)eng
{
    if (![eng isEqual:engine]) {
        return;
    }
    
    NSArray *allTorrents = [[eng torrents] allValues];
    
    [[self torrentList] loadTorrents:allTorrents];
}

- (void)engineDidRefreshStats:(RFEngine *)eng
{
    if (![eng isEqual:engine]) {
        return;
    }
    
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(serverDidRefreshStats:)]) {
            [[self delegate] serverDidRefreshStats:self];
        }
    }
}


#pragma mark torrent list delegate

- (void)torrentListDidFinishLoading:(RFTorrentList *)list
{
    if (![list isEqual:torrentList]) {
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSTimeInterval update = [defaults doubleForKey:REFRACT_USERDEFAULT_UPDATE_FREQUENCY];
    refreshTimer = [[NSTimer scheduledTimerWithTimeInterval:update target:self selector:@selector(refresh) userInfo:nil repeats:false] retain];
    
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(serverDidRefreshTorrents:)]) {
            [[self delegate] serverDidRefreshTorrents:self];
        }
    }
}


#pragma mark static functions

+ (NSUInteger)generateServerId
{
    @synchronized (self) {
        NSInteger lastId = [[NSUserDefaults standardUserDefaults] integerForKey:REFRACT_USERDEFAULT_SERVER_ID];
        lastId++;
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithLong:lastId] forKey:REFRACT_USERDEFAULT_SERVER_ID];
        return lastId;
    }
}

@end
