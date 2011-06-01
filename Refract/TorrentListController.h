//
//  TorrentListController.h
//  Refract
//
//  Created by xiphux on 5/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFTorrent.h"

typedef enum {
    sortName = 1,
    sortDateAdded = 2,
    sortDateDone = 3,
    sortProgress = 4,
    sortDownloadRate = 5,
    sortUploadRate = 6
} TorrentListSort;

@interface TorrentListController : NSObject {
@private
    NSArrayController IBOutlet *controller;
    NSCollectionView IBOutlet *listView;
    NSSearchField IBOutlet *searchField;
    
    NSPopUpButton IBOutlet *listButton;
    
    NSPredicate *listPredicate;
    TorrentListSort listSort;
}

@property (readonly) NSArray *selectedObjects;
@property (readonly) NSArray *arrangedObjects;

- (void)rearrangeObjects;
- (IBAction)search:(id)sender;
- (void)setGroupFilter:(NSUInteger)gid;
- (void)setStatusFilter:(RFTorrentStatus)status;
- (void)clearFilter;

@end
