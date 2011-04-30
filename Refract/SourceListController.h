//
//  SourceListController.h
//  Refract
//
//  Created by xiphux on 4/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RFTorrentFilter.h"

@protocol SourceListDelegate;

@interface SourceListController : NSObject <NSOutlineViewDelegate, NSMenuDelegate> {
@private
    IBOutlet NSTreeController *treeController;
    IBOutlet NSOutlineView *sourceList;
    IBOutlet NSMenu *contextMenu;
    IBOutlet NSWindow *window;
    RFTorrentFilter *filter;
    bool manipulatingSourceList;
    RFTorrentStatus removeStatus;
    
    bool initialized;
    NSArray *initialGroups;

    NSObject <SourceListDelegate> *delegate;
}

@property (retain) NSTreeController *treeController;
@property (retain) NSOutlineView *sourceList;
@property (retain) NSMenu *contextMenu;
@property (retain) NSWindow *window;
@property (readonly) RFTorrentFilter *filter;
@property (nonatomic, assign) NSObject <SourceListDelegate> *delegate;

- (void)addStatusGroup:(RFTorrentStatus)newStatus;
- (void)removeStatusGroup:(RFTorrentStatus)remStatus;

- (void)initGroups:(NSArray *)groupList;

- (IBAction)addGroup:(id)sender;
- (IBAction)removeGroup:(id)sender;

@end

@protocol SourceListDelegate <NSObject>
@optional
- (void)sourceList:(SourceListController *)list filterDidChange:(RFTorrentFilter *)newFilter;

- (NSUInteger)sourceList:(SourceListController *)list torrentsInGroup:(RFTorrentGroup *)group;

- (BOOL)sourceList:(SourceListController *)list canRemoveGroup:(RFTorrentGroup *)group;
- (void)sourceList:(SourceListController *)list didRemoveGroup:(RFTorrentGroup *)group;

- (BOOL)sourceList:(SourceListController *)list canRenameGroup:(RFTorrentGroup *)group toName:(NSString *)newName;
- (void)sourceList:(SourceListController *)list didRenameGroup:(RFTorrentGroup *)group toName:(NSString *)newName;

- (BOOL)sourceList:(SourceListController *)list canAddGroup:(NSString *)name;
- (RFTorrentGroup *)sourceList:(SourceListController *)list didAddGroup:(NSString *)name;
@end
