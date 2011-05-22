//
//  RFEngineTransmission.m
//  Refract
//
//  Created by xiphux on 4/2/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import "RFEngineTransmission.h"
#import "RFTorrent.h"
#import "RFBase64.h"
#import "RFURLConnection.h"
#import "RFConstants.h"
#import "EMKeychainItem.h"
#import "NotificationController.h"
#import <JSON/JSON.h>

#define REFRACT_RFENGINETRANSMISSION_KEY_URL @"url"
#define REFRACT_RFENGINETRANSMISSION_KEY_USERNAME @"username"

@interface RFEngineTransmission ()
@property (readwrite, retain) NSMutableDictionary *torrents;
- (NSArray *)torrentListToIds:(NSArray *)list;
- (bool)request:(NSString *)type method:(NSString *)method arguments:(NSDictionary *)args;
- (bool)rpcRequest:(NSString *)type data:(NSData *)requestBody;
- (void)parseTorrentList:(NSArray *)torrentList;
- (NSMutableURLRequest *)createRequest;
- (void)handleResponse:(NSData *)responseData userInfo:(NSDictionary *)userInfo;
@end

@implementation RFEngineTransmission

- (id)init
{
    //return [self initWithUrl:@"http://127.0.0.1:9091/transmission/rpc"];
    return [self initWithUrl:@"http://10.0.1.200:9091/transmission/rpc"];
}

- (id)initWithUrl:(NSString *) initUrl
{
    //return [self initWithUrlAndLogin:initUrl username:@""];
    return [self initWithUrlAndLogin:initUrl username:@"xiphux"];
}

- (id)initWithUrlAndLogin:(NSString *)initUrl username:(NSString *)initUser
{
    self = [super init];
    if (self) {
        url = [NSString stringWithString:initUrl];
        username = [NSString stringWithString:initUser];
        
        if ([username length] > 0) {
            EMGenericKeychainItem *keychain = [EMGenericKeychainItem genericKeychainItemForService:REFRACT_KEYCHAIN_TRANSMISSION withUsername:username];
            if (keychain) {
                password = [keychain password];
            }
        }
        
        torrents = [[NSMutableDictionary alloc] init];
        
        updateQueue = [[NSOperationQueue alloc] init];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSString *coderURL = [aDecoder decodeObjectForKey:REFRACT_RFENGINETRANSMISSION_KEY_URL];
    NSString *coderUsername = [aDecoder decodeObjectForKey:REFRACT_RFENGINETRANSMISSION_KEY_USERNAME];
    
    return [self initWithUrlAndLogin:coderURL username:coderUsername];
}

- (void)dealloc
{
    [url release];
    [username release];
    [password release];
    [torrents release];
    [updateQueue release];
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:engTransmission forKey:REFRACT_RFENGINE_KEY_TYPE];
    
    if ([url length] > 0) {
        [aCoder encodeObject:url forKey:REFRACT_RFENGINETRANSMISSION_KEY_URL];
    }
    if ([username length] > 0) {
        [aCoder encodeObject:username forKey:REFRACT_RFENGINETRANSMISSION_KEY_USERNAME];
    }
}

@synthesize torrents;
@synthesize url;
@synthesize username;
@synthesize password;
@synthesize connected;
@synthesize uploadSpeed;
@synthesize downloadSpeed;
@synthesize sessionUploadedBytes;
@synthesize sessionDownloadedBytes;
@synthesize totalUploadedBytes;
@synthesize totalDownloadedBytes;

- (RFEngineType)type
{
    return engTransmission;
}

- (bool)connect
{
    if ([url length] == 0) {
        return false;
    }
    
    return true;
}

- (bool)disconnect
{
    return true;
}

- (NSMutableURLRequest *)createRequest
{
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [req setHTTPMethod:@"POST"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    if (([username length] > 0) && ([password length] > 0)) {
        NSString *auth = [RFBase64 encodeBase64WithData:[[NSString stringWithFormat:@"%@:%@", username, password] dataUsingEncoding:NSUTF8StringEncoding]];
        [req setValue:[NSString stringWithFormat:@"Basic %@", auth] forHTTPHeaderField:@"Authorization"];
    }
    
    if ([sessionId length] > 0) {
        [req setValue:sessionId forHTTPHeaderField:@"X-Transmission-Session-Id"];
    }
    
    return req;
}

- (bool)refresh
{
    NSArray *fields = [NSArray arrayWithObjects:@"id", @"name", @"totalSize", @"sizeWhenDone", @"leftUntilDone", @"rateDownload", @"rateUpload", @"status", @"percentDone", @"eta", @"peersConnected", @"peersGettingFromUs", @"peersSendingToUs", @"recheckPercent", @"uploadedEver", @"uploadRatio", @"doneDate", @"addedDate", @"hashString", nil];
    NSDictionary *args = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:fields] forKeys:[NSArray arrayWithObject:@"fields"]];
    
    [self request:@"refresh" method:@"torrent-get" arguments:args];
    [self request:@"stats" method:@"session-stats" arguments:nil];
    
    return true;
}

- (bool)startTorrents:(NSArray *)list
{
    NSArray *ids = [self torrentListToIds:list];
    if ((!ids) || ([ids count] < 1)) {
        return false;
    }
    
    NSDictionary *args = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:ids] forKeys:[NSArray arrayWithObject:@"ids"]];
    
    return [self request:@"start" method:@"torrent-start" arguments:args];
}

- (bool)stopTorrents:(NSArray *)list
{
    NSArray *ids = [self torrentListToIds:list];
    if ((!ids) || ([ids count] < 1)) {
        return false;
    }
    
    NSDictionary *args = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:ids] forKeys:[NSArray arrayWithObject:@"ids"]];
    
    return [self request:@"stop" method:@"torrent-stop" arguments:args];
}

- (bool)startAllTorrents
{
    return [self request:@"startall" method:@"torrent-start" arguments:nil];
}

- (bool)stopAllTorrents
{
    return [self request:@"stopall" method:@"torrent-stop" arguments:nil];
}

- (bool)verifyTorrents:(NSArray *)list
{
    NSArray *ids = [self torrentListToIds:list];
    if ((!ids) || ([ids count] < 1)) {
        return false;
    }
    
    NSDictionary *args = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:ids] forKeys:[NSArray arrayWithObject:@"ids"]];
    
    return [self request:@"verify" method:@"torrent-verify" arguments:args];
}

- (bool)reannounceTorrents:(NSArray *)list
{
    NSArray *ids = [self torrentListToIds:list];
    if ((!ids) || ([ids count] < 1)) {
        return false;
    }
    
    NSDictionary *args = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:ids] forKeys:[NSArray arrayWithObject:@"ids"]];
    
    return [self request:@"reannounce" method:@"torrent-reannounce" arguments:args];
}

- (bool)removeTorrents:(NSArray *)list deleteData:(bool)del
{
    NSArray *ids = [self torrentListToIds:list];
    if ((!ids) || ([ids count] < 1)) {
        return false;
    }
    
    NSDictionary *args = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:ids, [NSNumber numberWithBool:del], nil] forKeys:[NSArray arrayWithObjects:@"ids", @"delete-local-data", nil]];
    
    NSString *type;
    if (del) {
        type = @"removedelete";
    } else {
        type = @"remove";
    }
    
    return [self request:type method:@"torrent-remove" arguments:args];
}

- (bool)addTorrent:(NSData *)data
{
    if (!data) {
        return false;
    }
    
    if ([data length] < 1) {
        return false;
    }
    
    NSDictionary *args = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObject:[RFBase64 encodeBase64WithData:data]] forKeys:[NSArray arrayWithObject:@"metainfo"]];
    
    return [self request:@"add" method:@"torrent-add" arguments:args];
}

- (NSArray *)torrentListToIds:(NSArray *)list
{
    if (!list) {
        return nil;
    }
    
    if ([list count] == 0) {
        return nil;
    }
    
    NSMutableArray *ids = [NSMutableArray array];
    for (RFTorrent *t in list) {
        if ([[t tid] length] > 0) {
            [ids addObject:[NSNumber numberWithInt:[[t tid] intValue]]];
        }
    }
    
    if ([ids count] == 0) {
        return nil;
    }
    
    return ids;
}

- (bool)request:(NSString *)type method:(NSString *)method arguments:(NSDictionary *)args
{
    if ([type length] == 0) {
        return false;
    }
    
    if ([method length] == 0) {
        return false;
    }
    
    if (!args) {
        args = [NSDictionary dictionary];
    }
    
    SBJsonWriter *writer = [[SBJsonWriter alloc] init];
    NSDictionary *requestData = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:args, method, nil] forKeys:[NSArray arrayWithObjects:@"arguments", @"method", nil]];
    NSString *requestStr = [writer stringWithObject:requestData];
    NSData *requestJson = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
    [writer release];
    
    [self rpcRequest:type data:requestJson];
    
    return true;
}

- (bool)rpcRequest:(NSString *)type data:(NSData *)requestBody
{
    NSMutableURLRequest *request = [self createRequest];
    
    if (!request) {
        return false;
    }
    
    [request setHTTPBody:requestBody];
    
    RFURLConnection *rfConn = [[RFURLConnection alloc] initWithRequest:request delegate:self startImmediately:false];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:type, @"type", nil];
    [rfConn setUserInfo:userInfo];
    [rfConn setRequestData:requestBody];
    [rfConn scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [rfConn start];
    [rfConn release];
    
    return true;
}

- (void)parseTorrentList:(NSArray *)torrentList
{
    [[NotificationController sharedNotificationController] startQueue];
    
    NSMutableArray *existingIDs = [NSMutableArray array];
    
    for (NSString *key in torrents) {
        [existingIDs addObject:key];
    }
    
    for (NSDictionary *torrentDict in torrentList)
    {
        NSString *tid = [[torrentDict valueForKey:@"id"] stringValue];
        
        if ([tid length] > 0) {
            RFTorrent *torrent = [torrents objectForKey:tid];
            
            if (!torrent) {
                torrent = [[RFTorrent alloc] initWithTid:tid];
                [torrents setValue:torrent forKey:tid];
            }
            
            NSString *name = [torrentDict objectForKey:@"name"];
            if ([name length] > 0) {
                torrent.name = name;
            }
            
            NSString *hashString = [torrentDict objectForKey:@"hashString"];
            if ([hashString length] > 0) {
                torrent.hashString = hashString;
            }
            
            NSNumber *totalSize = [torrentDict objectForKey:@"totalSize"];
            if (totalSize) {
                torrent.totalSize = [totalSize unsignedLongValue];
            }
            
            NSNumber *sizeWhenDone = [torrentDict objectForKey:@"sizeWhenDone"];
            if (sizeWhenDone) {
                torrent.doneSize = [sizeWhenDone unsignedLongValue];
            }
            
            NSNumber *leftUntilDone = [torrentDict objectForKey:@"leftUntilDone"];
            if (leftUntilDone) {
                torrent.currentSize = torrent.doneSize - [leftUntilDone unsignedLongValue];
            }
            
            NSNumber *rateDownload = [torrentDict objectForKey:@"rateDownload"];
            if (rateDownload) {
                torrent.downloadRate = [rateDownload unsignedLongValue];
            }
            
            NSNumber *rateUpload = [torrentDict objectForKey:@"rateUpload"];
            if (rateUpload) {
                torrent.uploadRate = [rateUpload unsignedLongValue];
            }
            
            NSNumber *percent = [torrentDict objectForKey:@"percentDone"];
            if (percent) {
                torrent.percent = [percent doubleValue] * 100;
            }
            
            NSNumber *status = [torrentDict objectForKey:@"status"];
            if (status) {
                switch ([status intValue]) {
                    case 1:         // TR_STATUS_CHECK_WAIT
                        torrent.status = stWaiting;
                        break;
                    case 2:         // TR_STATUS_CHECK
                        torrent.status = stChecking;
                        break;
                    case 4:         // TR_STATUS_DOWNLOAD
                        torrent.status = stDownloading;
                        break;
                    case 8:         // TR_STATUS_SEED
                        torrent.status = stSeeding;
                        break;
                    case 16:        // TR_STATUS_STOPPED
                        torrent.status = stStopped;
                        break;
                    default:
                        torrent.status = 0;
                        break;
                }
            }
            
            NSNumber *peersConnected = [torrentDict objectForKey:@"peersConnected"];
            if (peersConnected) {
                torrent.peersConnected = [peersConnected unsignedLongValue];
            }
            
            NSNumber *peersGettingFromUs = [torrentDict objectForKey:@"peersGettingFromUs"];
            if (peersGettingFromUs) {
                torrent.peersUpload = [peersGettingFromUs unsignedLongValue];
            }
            
            NSNumber *peersSendingToUs = [torrentDict objectForKey:@"peersSendingToUs"];
            if (peersSendingToUs) {
                torrent.peersDownload = [peersSendingToUs unsignedLongValue];
            }
            
            NSNumber *eta = [torrentDict objectForKey:@"eta"];
            if (eta) {
                torrent.eta = [eta longValue];
            }
            
            NSNumber *recheckProgress = [torrentDict objectForKey:@"recheckProgress"];
            if (recheckProgress) {
                torrent.recheckPercent = [recheckProgress doubleValue] * 100;
            }
            
            NSNumber *uploadedEver = [torrentDict objectForKey:@"uploadedEver"];
            if (uploadedEver) {
                torrent.uploadedSize = [uploadedEver unsignedLongValue];
            }
            
            NSNumber *uploadRatio = [torrentDict objectForKey:@"uploadRatio"];
            if (uploadRatio) {
                torrent.ratio = [uploadRatio doubleValue];
            }
            
            NSNumber *doneDate = [torrentDict objectForKey:@"doneDate"];
            if (doneDate) {
                torrent.doneDate = (time_t)[doneDate unsignedLongValue];
            }
            
            NSNumber *addedDate = [torrentDict objectForKey:@"addedDate"];
            if (addedDate) {
                torrent.addedDate = (time_t)[addedDate unsignedLongValue];
            }
            
            [torrent signalUpdated];
            
            [existingIDs removeObject:tid];
        }
    }
    
    for (NSString *delID in existingIDs) {
        [torrents removeObjectForKey:delID];
    }
    
    [[NotificationController sharedNotificationController] flushQueue];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    RFURLConnection *rfConn = (RFURLConnection *)connection;
    [rfConn setResponse:response];
    [rfConn setResponseData:[[NSMutableData alloc] init]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    RFURLConnection *rfConn = (RFURLConnection *)connection;
    [[rfConn responseData] appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    RFURLConnection *rfConn = (RFURLConnection *)connection;
    
    if ([[rfConn response] statusCode] == 409) {
        // requires session token - get token and resubmit request
        NSDictionary *responseHeaders = [[rfConn response] allHeaderFields];
        
        sessionId = [responseHeaders valueForKey:@"X-Transmission-Session-Id"];
        if ([sessionId length] > 0) {
            [self rpcRequest:[[rfConn userInfo] objectForKey:@"type"] data:[rfConn requestData]]; 
        }
        
        return;
    }
    
    if ([[rfConn response] statusCode] == 200) {
        
        connected = true;
        
        [self handleResponse:[rfConn responseData] userInfo:[rfConn userInfo]];
        
        return;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(engine:requestDidFail:)]) {
            RFURLConnection *rfConn = (RFURLConnection *)connection;
            [[self delegate] engine:self requestDidFail:[[rfConn userInfo] objectForKey:@"type"]];
        }
    }
}

- (void)handleResponse:(NSData *)responseData userInfo:(NSDictionary *)userInfo
{
    if (!(responseData || userInfo)) {
        return;
    }
    
    NSString *type = [userInfo objectForKey:@"type"];
    
    NSString *responseStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    NSDictionary *responseDict = [parser objectWithString:responseStr];
    [parser release];
    [responseStr release];
    
    if (![[responseDict objectForKey:@"result"] isEqualToString:@"success"]) {
        return;
    }
    
    if ([type isEqualToString:@"refresh"]) {
        
        NSArray *torrentList = [[responseDict objectForKey:@"arguments"] objectForKey:@"torrents"];
        
        NSInvocationOperation *refreshOp = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(parseTorrentList:) object:torrentList];
        [refreshOp setCompletionBlock:^{
            if ([self delegate]) {
                if ([[self delegate] respondsToSelector:@selector(engineDidRefreshTorrents:)]) {
                    [[self delegate] performSelectorOnMainThread:@selector(engineDidRefreshTorrents:) withObject:self waitUntilDone:NO];
                }
            }
        }];
        [updateQueue addOperation:refreshOp];
        [refreshOp release];
        
    } else if ([type isEqualToString:@"stats"]) {
        
        NSDictionary *statsDict = [responseDict objectForKey:@"arguments"];
        
        NSBlockOperation *statsOp = [NSBlockOperation blockOperationWithBlock:^{
        
            NSNumber *downSpeed = [statsDict objectForKey:@"downloadSpeed"];
            if (downSpeed && ([downSpeed unsignedLongValue] != downloadSpeed)) {
                [self willChangeValueForKey:@"downloadSpeed"];
                downloadSpeed = [downSpeed unsignedLongValue];
                [self didChangeValueForKey:@"downloadSpeed"];
            }
            
            NSNumber *upSpeed = [statsDict objectForKey:@"uploadSpeed"];
            if (upSpeed && ([upSpeed unsignedLongValue] != uploadSpeed)) {
                [self willChangeValueForKey:@"uploadSpeed"];
                uploadSpeed = [upSpeed unsignedLongValue];
                [self didChangeValueForKey:@"uploadSpeed"];
            }
            
            NSDictionary *sessionDict = [statsDict objectForKey:@"current-stats"];
            
            NSNumber *sUpBytes = [sessionDict objectForKey:@"uploadedBytes"];
            if (sUpBytes && ([sUpBytes unsignedLongValue] != sessionUploadedBytes)) {
                [self willChangeValueForKey:@"sessionUploadedBytes"];
                sessionUploadedBytes = [sUpBytes unsignedLongValue];
                [self didChangeValueForKey:@"sessionUploadedBytes"];
            }
            
            NSNumber *sDownBytes = [sessionDict objectForKey:@"downloadedBytes"];
            if (sDownBytes && ([sDownBytes unsignedLongValue] != sessionDownloadedBytes)) {
                [self willChangeValueForKey:@"sessionDownloadedBytes"];
                sessionDownloadedBytes = [sDownBytes unsignedLongValue];
                [self didChangeValueForKey:@"sessionDownloadedBytes"];
            }
            
            NSDictionary *totalDict = [statsDict objectForKey:@"cumulative-stats"];
            
            NSNumber *tUpBytes = [totalDict objectForKey:@"uploadedBytes"];
            if (tUpBytes && ([tUpBytes unsignedLongValue] != totalUploadedBytes)) {
                [self willChangeValueForKey:@"totalUploadedBytes"];
                totalUploadedBytes = [tUpBytes unsignedLongValue];
                [self didChangeValueForKey:@"totalUploadedBytes"];
            }
            
            NSNumber *tDownBytes = [totalDict objectForKey:@"downloadedBytes"];
            if (tDownBytes && ([tDownBytes unsignedLongValue] != totalDownloadedBytes)) {
                [self willChangeValueForKey:@"totalDownloadedBytes"];
                totalDownloadedBytes = [tDownBytes unsignedLongValue];
                [self didChangeValueForKey:@"totalDownloadedBytes"];
            }
            
        }];
        [statsOp setCompletionBlock:^{
            if ([self delegate]) {
                if ([[self delegate] respondsToSelector:@selector(engineDidRefreshStats:)]) {
                    [[self delegate] performSelectorOnMainThread:@selector(engineDidRefreshStats:) withObject:self waitUntilDone:NO];
                }
            }
        }];
        [updateQueue addOperation:statsOp];
        [statsOp release];
        
    }
}

@end
