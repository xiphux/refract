//
//  TorrentListController.h
//  Refract
//
//  Created by xiphux on 5/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFTorrent.h"

@interface TorrentListController : NSObject {
@private
    NSArrayController IBOutlet *torrentListController;
    NSCollectionView IBOutlet *torrentListView;
    NSSearchField IBOutlet *searchField;
    
    NSPredicate *listPredicate;
}

@property (retain) IBOutlet NSArrayController *controller;
@property (retain) IBOutlet NSCollectionView *listView;
@property (retain) IBOutlet NSSearchField *searchField;
@property (readonly) NSArray *selectedObjects;
@property (readonly) NSArray *arrangedObjects;

- (void)rearrangeObjects;
- (IBAction)search:(id)sender;
- (void)setGroupFilter:(NSUInteger)gid;
- (void)setStatusFilter:(RFTorrentStatus)status;
- (void)clearFilter;

@end
