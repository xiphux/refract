//
//  RFTorrentGroup.h
//  Refract
//
//  Created by xiphux on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RFTorrentGroup : NSObject <NSCoding> {
@private
    NSString *name;
    NSUInteger gid;
}

@property (copy) NSString *name;
@property NSUInteger gid;

- (bool)isEqual:(id)other;
- (NSUInteger)hash;

@end
