//
//  RFTorrentGroup.h
//  Refract
//
//  Created by xiphux on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RFTorrentGroup : NSObject {
@private
    NSString *name;
    NSMutableArray *torrents;
}

@property (copy) NSString *name;
@property (assign) NSMutableArray *torrents;

- (id)initWithName:(NSString *)initName;

@end
