//
//  SourceListController.h
//  Refract
//
//  Created by xiphux on 4/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RFTorrentFilter.h"

@protocol SourceListControllerDelegate;

@interface SourceListController : NSObject <NSOutlineViewDelegate, NSMenuDelegate> {
@private
    IBOutlet NSTreeController *treeController;
    IBOutlet NSOutlineView *sourceList;
    IBOutlet NSMenu *contextMenu;
    RFTorrentFilter *filter;
    bool manipulatingSourceList;
    RFTorrentStatus removeStatus;

    NSObject <SourceListControllerDelegate> *delegate;
}

@property (retain) NSTreeController *treeController;
@property (retain) NSOutlineView *sourceList;
@property (retain) NSMenu *contextMenu;
@property (readonly) RFTorrentFilter *filter;
@property (nonatomic, assign) NSObject <SourceListControllerDelegate> *delegate;

- (void)addStatusGroup:(RFTorrentStatus)newStatus;
- (void)removeStatusGroup:(RFTorrentStatus)remStatus;

- (IBAction)addGroup:(id)sender;
- (IBAction)removeGroup:(id)sender;

@end

@protocol SourceListControllerDelegate <NSObject>
@optional
- (void)sourceList:(SourceListController *)list filterDidChange:(RFTorrentFilter *)newFilter;

- (BOOL)sourceList:(SourceListController *)list canRemoveGroup:(NSUInteger)gid;
- (void)sourceList:(SourceListController *)list didRemoveGroup:(NSUInteger)gid;

- (BOOL)sourceList:(SourceListController *)list canRenameGroup:(NSUInteger)gid toName:(NSString *)newName;
- (void)sourceList:(SourceListController *)list didRenameGroup:(NSUInteger)gid toName:(NSString *)newName;

- (BOOL)sourceList:(SourceListController *)list canAddGroup:(NSString *)name;
- (RFTorrentGroup *)sourceList:(SourceListController *)list didAddGroup:(NSString *)name;
@end
