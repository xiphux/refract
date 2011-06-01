//
//  ServerNode.m
//  Refract
//
//  Created by xiphux on 5/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ServerNode.h"


@implementation ServerNode

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [server release];
    [super dealloc];
}

@synthesize server;

@end
