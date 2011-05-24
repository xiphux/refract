//
//  BaseNode.m
//  Refract
//
//  Created by xiphux on 4/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BaseNode.h"


@implementation BaseNode

- (id)init
{
    self = [super init];
    if (self) {
        children = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [title release];
    [children release];
    [super dealloc];
}

@synthesize title;
@synthesize children;
@synthesize isLeaf;
@synthesize sortIndex;

@end
