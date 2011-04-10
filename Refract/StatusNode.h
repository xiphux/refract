//
//  StatusNode.h
//  Refract
//
//  Created by xiphux on 4/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseNode.h"
#import "RFTorrent.h"

@interface StatusNode : BaseNode {
@private
    RFTorrentStatus status;
}

@property (assign) RFTorrentStatus status;

@end
