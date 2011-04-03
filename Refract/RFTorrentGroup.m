//
//  RFTorrentGroup.m
//  Refract
//
//  Created by xiphux on 4/3/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import "RFTorrentGroup.h"


@implementation RFTorrentGroup

@synthesize name;
@synthesize torrents;

- (id)init
{
    return [self initWithName:@""];
}

- (id)initWithName:(NSString *)initName
{
    self = [super init];
    if (self) {
        name = initName;
        torrents = [NSMutableArray array];
    }
    
    return self;
}

- (void)dealloc
{
    [torrents release];
    [name release];
    [super dealloc];
}

@end
