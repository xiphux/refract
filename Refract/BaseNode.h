//
//  BaseNode.h
//  Refract
//
//  Created by xiphux on 4/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface BaseNode : NSObject {
@protected
    NSString *title;
    NSMutableArray *children;
    bool isLeaf;
    NSUInteger sortIndex;
}

@property (copy) NSString *title;
@property (copy) NSMutableArray *children;
@property (assign) bool isLeaf;
@property (assign) NSUInteger sortIndex;

@end
