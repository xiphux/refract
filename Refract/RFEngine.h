//
//  RFEngine.h
//  Refract
//
//  Created by xiphux on 4/2/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RFEngine : NSObject {
@private
    NSMutableDictionary *torrents;
}

@property(readonly) NSMutableDictionary *torrents;

- (bool)connect;
- (bool)disconnect;
- (bool)connected;
- (bool)refresh;

@end
