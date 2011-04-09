//
//  GroupController.h
//  Refract
//
//  Created by xiphux on 4/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GroupController : NSObject {
@private
    IBOutlet NSArrayController *torrentsArrayController;
}

@property (assign) NSArrayController *torrentsArrayController;

@end
