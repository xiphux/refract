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

@interface RFEngine : NSObject {
@private
}

- (bool)connect;
- (bool)disconnect;
- (bool)connected;
- (bool)refresh;
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
