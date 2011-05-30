//
//  RFServerList.m
//  Refract
//
//  Created by xiphux on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RFServerList.h"
#import "RFConstants.h"

static RFServerList *sharedInstance = nil;

@implementation RFServerList

- (id)init
{
    @synchronized (self) {
        self = [super init];
        if (self) {
            
            NSData *serverData = [[NSUserDefaults standardUserDefaults] objectForKey:REFRACT_USERDEFAULT_SERVERS];
            if (serverData) {
                NSArray *serverArray = [NSKeyedUnarchiver unarchiveObjectWithData:serverData];
                if (serverArray) {
                    servers = [[NSMutableArray alloc] initWithArray:serverArray];
                }
            }
            if (!servers) {
                servers = [[NSMutableArray alloc] init];
            }
            
            syncTimer = [[NSTimer timerWithTimeInterval:180 target:self selector:@selector(save:) userInfo:nil repeats:true] retain];
            
        }
        
        return self;
    }
}

- (void)dealloc
{
    [syncTimer invalidate];
    [syncTimer release];
    [servers release];
    [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain
{
    return self;
}

- (void)release
{
    
}

- (id)autorelease
{
    return self;
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;
}

@synthesize servers;

- (void)save
{
    @synchronized (self) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:servers] forKey:REFRACT_USERDEFAULT_SERVERS];
    }
}


+ (RFServerList *)sharedServerList
{
    @synchronized (self) {
        if (sharedInstance == nil) {
            [[self alloc] init];
        }
    }
    
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized (self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;
        }
    }
    
    return nil;
}

@end
