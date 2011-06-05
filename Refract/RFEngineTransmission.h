//
//  RFEngineTransmission.h
//  Refract
//
//  Created by xiphux on 4/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFEngine.h"

@interface RFEngineTransmission : RFEngine {
@private
    NSURL *url;
    NSString *username;
    NSString *password;
    NSMutableDictionary *torrents;
    NSString *sessionId;
    bool connected;
    unsigned long uploadSpeed;
    unsigned long downloadSpeed;
    unsigned long sessionUploadedBytes;
    unsigned long sessionDownloadedBytes;
    unsigned long totalUploadedBytes;
    unsigned long totalDownloadedBytes;
    
    NSOperationQueue *updateQueue;
}

@property (readonly, retain) NSMutableDictionary *torrents;
@property (readonly) bool connected;
@property (copy) NSURL *url;
@property (copy) NSString *username;
@property (copy) NSString *password;

@property (readonly) unsigned long uploadSpeed;
@property (readonly) unsigned long downloadSpeed;
@property (readonly) unsigned long sessionUploadedBytes;
@property (readonly) unsigned long sessionDownloadedBytes;
@property (readonly) unsigned long totalUploadedBytes;
@property (readonly) unsigned long totalDownloadedBytes;

- (id)initWithUrl:(NSURL *)initUrl;
- (id)initWithUrlAndLogin:(NSURL *)initUrl username:(NSString *)initUser;

@end
