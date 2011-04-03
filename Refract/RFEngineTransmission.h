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
    NSString *url;
    NSString *username;
    NSString *password;
    NSMutableDictionary *torrents;
}

@property (readonly, retain) NSMutableDictionary *torrents;
@property (copy) NSString *url;
@property (copy) NSString *username;
@property (copy) NSString *password;

- (id)initWithUrl:(NSString *)initUrl;
- (id)initWithUrlAndLogin:(NSString *)initUrl username:(NSString *)initUser password:(NSString *)initPass;

@end
