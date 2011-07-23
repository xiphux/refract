//
//  RFAlert.h
//  Refract
//
//  Created by xiphux on 7/22/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

typedef enum {
    alertConfirmAdd = 1,
    alertConfirmRemove = 2,
    alertConfirmDelete = 3
} RFAlertType;

@interface RFAlert : NSAlert {
@private
    NSArray *torrents;
    NSArray *paths;
    RFAlertType type;
}

@property (nonatomic, assign) NSArray *torrents;
@property (nonatomic, assign) NSArray *paths;
@property RFAlertType type;

@end
