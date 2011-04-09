//
//  GroupController.m
//  Refract
//
//  Created by xiphux on 4/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GroupController.h"


@implementation GroupController

@synthesize torrentsArrayController;

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
    [super dealloc];
}

- (void)awakeFromNib
{
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:true];
    [torrentsArrayController setSortDescriptors:[NSArray arrayWithObject:sd]];
    [sd release];
}

@end
