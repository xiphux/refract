//
//  RFServerList.h
//  Refract
//
//  Created by xiphux on 5/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RFServerList : NSObject {
@private
    NSMutableArray *servers;
    NSTimer *syncTimer;
}

@property (readonly) NSMutableArray *servers;

- (void)save;

+ (RFServerList *)sharedServerList;

@end
