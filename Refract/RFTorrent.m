//
//  RFTorrent.m
//  Refract
//
//  Created by xiphux on 4/2/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import "RFTorrent.h"


@implementation RFTorrent

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
    [name release];
    [tid release];
    [super dealloc];
}

@synthesize name;
@synthesize tid;
@synthesize currentSize;
@synthesize doneSize;
@synthesize totalSize;
@synthesize uploadRate;
@synthesize downloadRate;
@synthesize status;

- (unsigned int)percent
{
    if (doneSize == 0) {
        return 0;
    }
    
    return (unsigned int)((currentSize / doneSize) * 100);
}

@end
