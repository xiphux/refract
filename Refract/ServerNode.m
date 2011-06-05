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

- (RFServer *)server
{
    return server;
}

- (void)setServer:(RFServer *)newServer
{
    if (server == newServer) {
        return;
    }
    
    if (server) {
        [server removeObserver:self forKeyPath:@"name"];
    }
    
    [server release];
    
    server = [newServer retain];
    
    if (newServer) {
        [newServer addObserver:self forKeyPath:@"name" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:NULL];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([server isEqual:object]) {
        if ([keyPath isEqualToString:@"name"]) {
            [self setTitle:[server name]];
        }
    }
}

@end
