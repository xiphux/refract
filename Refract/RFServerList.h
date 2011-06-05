//
//  RFServerList.h
//  Refract
//
//  Created by xiphux on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFServer.h"

@interface RFServerList : NSObject {
@private
    NSMutableArray *servers;
    NSTimer *syncTimer;
}

@property (readonly) NSArray *servers;

- (void)save;

- (RFServer *)serverWithName:(NSString *)name;
- (bool)serverWithNameExists:(NSString *)name;

- (NSUInteger)countOfServers;
- (void)insertObject:(RFServer *)server inServersAtIndex:(NSUInteger)index;
- (void)removeObjectFromServersAtIndex:(NSUInteger)index;

+ (RFServerList *)sharedServerList;

@end
