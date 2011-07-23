//
//  RFAlert.m
//  Refract
//
//  Created by xiphux on 7/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RFAlert.h"

@implementation RFAlert

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
    [torrents release];
    [paths release];
}

@synthesize torrents;
@synthesize paths;
@synthesize type;

@end
