//
//  GroupNode.h
//  Refract
//
//  Created by xiphux on 4/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseNode.h"
#import "RFTorrentGroup.h"

@interface GroupNode : BaseNode {
@private
    RFTorrentGroup *group;
}

@property (retain) RFTorrentGroup *group;

@end
