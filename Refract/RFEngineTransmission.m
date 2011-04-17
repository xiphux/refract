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
#import <JSON/JSON.h>

@interface RFEngineTransmission ()
@property (readwrite, retain) NSMutableDictionary *torrents;
- (bool)rpcRequest:(NSString *)type data:(NSData *)requestBody;
- (void)parseTorrentList:(NSArray *)torrentList;
- (NSMutableURLRequest *)createRequest;
- (void)settingsChanged:(NSNotification *)notification;
- (void)handleResponse:(NSData *)responseData userInfo:(NSDictionary *)userInfo;
@end

@implementation RFEngineTransmission

- (id)init
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObject:@"http://127.0.0.1:9091/transmission/rpc" forKey:REFRACT_USERDEFAULT_TRANSMISSION_URL];
    [defaults registerDefaults:appDefaults];
    
    return [self initWithUrl:[defaults objectForKey:@"Transmission.URL"]];
}

- (id)initWithUrl:(NSString *) initUrl
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *user = [defaults stringForKey:REFRACT_USERDEFAULT_TRANSMISSION_USERNAME];
    NSString *pass = nil;
    if ([user length] > 0) {
        EMGenericKeychainItem *keychain = [EMGenericKeychainItem genericKeychainItemForService:REFRACT_KEYCHAIN_TRANSMISSION withUsername:user];
        if (keychain) {
            pass = [keychain password];
        }
    }
    
    return [self initWithUrlAndLogin:initUrl username:user password:pass];
}

- (id)initWithUrlAndLogin:(NSString *)initUrl username:(NSString *)initUser password:(NSString *)initPass
{
    self = [super init];
    if (self) {
        // Initialization code here.
        torrents = [[NSMutableDictionary alloc] init];
        
        url = [NSString stringWithString:initUrl];
        username = [NSString stringWithString:initUser];
        password = [NSString stringWithString:initPass];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [url release];
    [username release];
    [password release];
    [torrents release];
    [super dealloc];
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
    SBJsonWriter *writer = [[SBJsonWriter alloc] init];
    
    NSArray *fields = [NSArray arrayWithObjects:@"id", @"name", @"totalSize", @"sizeWhenDone", @"leftUntilDone", @"rateDownload", @"rateUpload", @"status", @"percentDone", @"eta", @"peersConnected", @"peersGettingFromUs", @"peersSendingToUs", @"recheckPercent", @"uploadedEver", @"uploadRatio", nil];
    NSDictionary *args = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:fields] forKeys:[NSArray arrayWithObject:@"fields"]];
    NSDictionary *requestData = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:args, @"torrent-get", nil] forKeys:[NSArray arrayWithObjects:@"arguments", @"method", nil]];
    NSString *requestStr = [writer stringWithObject:requestData];
    NSData *requestJson = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
    
    NSDictionary *statsRequestData = [NSDictionary dictionaryWithObject:@"session-stats" forKey:@"method"];
    NSString *statsRequestStr = [writer stringWithObject:statsRequestData];
    NSData *statsRequestJson = [statsRequestStr dataUsingEncoding:NSUTF8StringEncoding];
    
    [writer release];
    
    [self rpcRequest:@"refresh" data:requestJson];
    [self rpcRequest:@"stats" data:statsRequestJson];
    
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
                torrent = [[RFTorrent alloc] init];
                torrent.tid = tid;
                [torrents setValue:torrent forKey:tid];
            }
            
            NSString *name = [torrentDict objectForKey:@"name"];
            if ([name length] > 0) {
                torrent.name = name;
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
            
            [torrent signalUpdated];
            
            [existingIDs removeObject:tid];
        }
    }
    
    for (NSString *delID in existingIDs) {
        [torrents removeObjectForKey:delID];
    }
}

- (void)settingsChanged:(NSNotification *)notification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults integerForKey:REFRACT_USERDEFAULT_ENGINE] != engTransmission) {
        return;
    }
    
    NSString *settingsUrl = [defaults stringForKey:REFRACT_USERDEFAULT_TRANSMISSION_URL];
    if (![url isEqualToString:settingsUrl]) {
        url = settingsUrl;
    }
    NSString *settingsUser = [defaults stringForKey:REFRACT_USERDEFAULT_TRANSMISSION_USERNAME];
    if (![username isEqualToString:settingsUser]) {
        username = settingsUrl;
    }
    NSString *pass = nil;
    if ([username length] > 0) {
        EMGenericKeychainItem *keychain = [EMGenericKeychainItem genericKeychainItemForService: REFRACT_KEYCHAIN_TRANSMISSION withUsername:username];
        if (keychain) {
            pass = [keychain password];
        }
    }
    password = pass;
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
    
    if (![[responseDict objectForKey:@"result"] isEqualToString:@"success"]) {
        return;
    }
    
    if ([type isEqualToString:@"refresh"]) {
        NSArray *torrentList = [[responseDict objectForKey:@"arguments"] objectForKey:@"torrents"];
        [self parseTorrentList:torrentList];
    } else if ([type isEqualToString:@"stats"]) {
        NSDictionary *statsDict = [responseDict objectForKey:@"arguments"];
        
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
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:type object:self];
}

@end
