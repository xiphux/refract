//
//  CategoryNode.h
//  Refract
//
//  Created by xiphux on 4/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BaseNode.h"

typedef enum {
    catStatus = 1,
    catGroup = 2
} CategoryNodeType;

@interface CategoryNode : BaseNode {
@private
    CategoryNodeType categoryType;
}

@property (assign) CategoryNodeType categoryType;

@end
