//
//  StateNode.h
//  Refract
//
//  Created by xiphux on 6/5/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseNode.h"
#import "RFTorrentFilter.h"

@interface StateNode : BaseNode {
@private
    RFTorrentState state;
}

@property RFTorrentState state;

@end
