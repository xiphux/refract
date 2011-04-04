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
#import <JSON/JSON.h>

@interface RFEngineTransmission ()
@property (readwrite, retain) NSMutableDictionary *torrents;
@property (retain) NSMutableURLRequest *request;
- (NSData *)rpcRequest:(NSData *)requestBody;
- (void)parseTorrentList:(NSArray *)torrentList;
@end

@implementation RFEngineTransmission

@synthesize torrents;
@synthesize url;
@synthesize username;
@synthesize password;
@synthesize request;

- (id)init
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObject:@"http://127.0.0.1:9091/transmission/rpc" forKey:@"Transmission.URL"];
    [defaults registerDefaults:appDefaults];
    
    return [self initWithUrl:[defaults objectForKey:@"Transmission.URL"]];
}

- (id)initWithUrl:(NSString *) initUrl
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    return [self initWithUrlAndLogin:initUrl username:[defaults objectForKey:@"Transmission.Username"] password:[defaults objectForKey:@"Transmission.Password"]];
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
    }
    
    return self;
}

- (void)dealloc
{
    [url release];
    [username release];
    [password release];
    [request release];
    [torrents release];
    [super dealloc];
}

- (bool)connect
{
    if ([url length] == 0) {
        return false;
    }
    
    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    if (([username length] > 0) && ([password length] > 0)) {
        NSString *auth = [RFBase64 encodeBase64WithData:[[NSString stringWithFormat:@"%@:%@", username, password] dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:[NSString stringWithFormat:@"Basic %@", auth] forHTTPHeaderField:@"Authorization"];
    }
    
    if ([self rpcRequest:nil] == nil) {
        return false;
    }
    
    return true;
}

- (bool)disconnect
{
    request = nil;
    return true;
}

- (bool)connected
{
    return request ? true : false;
}

- (bool)refresh
{
    SBJsonParser *parser = [[SBJsonParser alloc] init];
    SBJsonWriter *writer = [[SBJsonWriter alloc] init];
    
    NSArray *fields = [NSArray arrayWithObjects:@"id", @"name", @"totalSize", @"sizeWhenDone", @"leftUntilDone", @"rateDownload", @"rateUpload", @"status", nil];
    NSDictionary *args = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObject:fields] forKeys:[NSArray arrayWithObject:@"fields"]];
    NSDictionary *requestData = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:args, @"torrent-get", nil] forKeys:[NSArray arrayWithObjects:@"arguments", @"method", nil]];
    NSString *requestStr = [writer stringWithObject:requestData];
    NSData *requestJson = [requestStr dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *response = [self rpcRequest:requestJson];
    
    if (response != nil) {
        NSString *responseStr = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
        NSDictionary *responseData = [parser objectWithString:responseStr];
        
        if ([[responseData objectForKey:@"result"] isEqualToString:@"success"]) {
            NSArray *torrentList = [[responseData objectForKey:@"arguments"] objectForKey:@"torrents"];
            [self parseTorrentList:torrentList];
        }
    }
    
    [parser release];
    [writer release];
    
    return true;
}

- (NSData *)rpcRequest:(NSData *)requestBody
{
    if (!request) {
        return nil;
    }
    
    [request setHTTPBody:requestBody];
    
    NSHTTPURLResponse *responseData = nil;
    NSError *error = nil;
    
    NSData *response = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseData error:&error];
    
    if (responseData) {
        if ([responseData statusCode] == 409) {
            // requires session token - get token and resubmit request
            NSDictionary *responseHeaders = [responseData allHeaderFields];
            
            NSString *sessionId = [responseHeaders valueForKey:@"X-Transmission-Session-Id"];
            if ([sessionId length] > 0) {
                [request setValue:sessionId forHTTPHeaderField:@"X-Transmission-Session-Id"];
                return [self rpcRequest:requestBody];
            }
        }
    }
    
    return response;
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
            
            [existingIDs removeObject:tid];
        }
    }
    
    for (NSString *delID in existingIDs) {
        [torrents removeObjectForKey:delID];
    }
}

@end
