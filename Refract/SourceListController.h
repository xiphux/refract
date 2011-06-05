//
//  SourceListController.h
//  Refract
//
//  Created by xiphux on 4/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RFTorrentFilter.h"
#import "RFServer.h"

@protocol SourceListDelegate;

@interface SourceListController : NSObject <NSOutlineViewDelegate, NSMenuDelegate, NSOutlineViewDataSource> {
@private
    IBOutlet NSTreeController *treeController;
    IBOutlet NSOutlineView *sourceList;
    IBOutlet NSMenu *contextMenu;
    IBOutlet NSWindow *window;
    IBOutlet NSButton *addGroupButton;
    bool manipulatingSourceList;
    RFTorrentStatus removeStatus;
    
    bool initialized;
    NSArray *initialGroups;

    IBOutlet NSObject <SourceListDelegate> *delegate;
}

@property (nonatomic, assign) NSObject <SourceListDelegate> *delegate;

- (void)updateServer:(RFServer *)server;

- (IBAction)addGroup:(id)sender;
- (IBAction)removeGroup:(id)sender;

@end

@protocol SourceListDelegate <NSObject>
@optional
- (void)sourceList:(SourceListController *)list server:(RFServer *)server filterDidChange:(RFTorrentFilter *)newFilter;
@end
