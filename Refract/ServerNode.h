//
//  ServerNode.h
//  Refract
//
//  Created by xiphux on 5/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseNode.h"
#import "RFServer.h"

@interface ServerNode : BaseNode {
@private
    RFServer *server;
}

@property (retain) RFServer *server;

@end
