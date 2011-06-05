//
//  RFGroupList.h
//  Refract
//
//  Created by xiphux on 4/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RFTorrentGroup.h"

@interface RFGroupList : NSObject <NSCoding> {
@private
    NSMutableArray *groups;
}

@property (readonly) NSArray *groups;

- (RFTorrentGroup *)groupWithName:(NSString *)name;
- (bool)groupWithNameExists:(NSString *)name;

- (RFTorrentGroup *)addGroup:(NSString *)name;
- (void)removeGroup:(RFTorrentGroup *)group;

+ (NSUInteger)generateGroupId;

@end
