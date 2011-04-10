//
//  SourceListController.h
//  Refract
//
//  Created by xiphux on 4/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RFTorrent.h"

@interface SourceListController : NSObject <NSOutlineViewDelegate> {
@private
    IBOutlet NSTreeController *treeController;
    IBOutlet NSOutlineView *sourceList;
}

@property (retain) NSTreeController *treeController;
@property (retain) NSOutlineView *sourceList;

- (void)addStatusGroup:(RFTorrentStatus)newStatus;
- (void)removeStatusGroup:(RFTorrentStatus)remStatus;

@end
