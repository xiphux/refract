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
}

- (bool)connect;
- (bool)disconnect;
- (bool)connected;
- (bool)refresh;
- (NSDictionary *)torrents;

+ (id)engineOfType:(RFEngineType)type;
+ (id)engine;

@end
