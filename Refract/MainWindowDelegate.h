//
//  MainWindowDelegate.h
//  Refract
//
//  Created by xiphux on 4/1/11.
//  Copyright 2011 Chris Han. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RFEngine.h"
#import "RFTorrentList.h"
#import "RFGroupList.h"
#import "SourceListController.h"
#import "PreferencesController.h"
#import "TorrentItem.h"

@interface MainWindowDelegate : NSObject <NSSplitViewDelegate, RFTorrentListDelegate, RFEngineDelegate, SourceListDelegate, TorrentItemDelegate, NSMenuDelegate> {
@private
    NSWindow IBOutlet *window;
    SourceListController IBOutlet *sourceListController;
    NSArrayController IBOutlet *torrentListController;
    NSSearchField IBOutlet *searchField;
    NSButton IBOutlet *statsButton;
    NSTextField IBOutlet *rateText;
    NSMenu IBOutlet *removeMenu;
    NSSegmentedControl IBOutlet *removeButton;
    NSMenu IBOutlet *actionMenu;
    NSSegmentedControl IBOutlet *actionButton;
    NSMenu IBOutlet *stopMenu;
    NSMenu IBOutlet *startMenu;
    NSSegmentedControl IBOutlet *startStopButton;
    
    RFEngine *engine;
    RFTorrentList *torrentList;
    RFGroupList *groupList;
    NSPredicate *searchPredicate;
    
    bool showTotalStats;
    bool started;
    
    NSOperationQueue *updateQueue;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) IBOutlet NSArrayController *torrentListController;
@property (retain) IBOutlet SourceListController *sourceListController;
@property (retain) IBOutlet NSSearchField *searchField;
@property (retain) IBOutlet NSTextField *rateText;
@property (retain) IBOutlet NSButton *statsButton;
@property (retain) IBOutlet NSMenu *removeMenu;
@property (retain) IBOutlet NSSegmentedControl *removeButton;
@property (retain) IBOutlet NSMenu *actionMenu;
@property (retain) IBOutlet NSSegmentedControl *actionButton;
@property (retain) IBOutlet NSMenu *stopMenu;
@property (retain) IBOutlet NSMenu *startMenu;
@property (retain) IBOutlet NSSegmentedControl *startStopButton;

@property (retain) RFEngine *engine;
@property (retain) RFTorrentList *torrentList;
@property (retain) RFGroupList *groupList;

- (IBAction)search:(id)sender;
- (IBAction)statsButtonClick:(id)sender;
- (IBAction)startStopClicked:(id)sender;
- (IBAction)startClicked:(id)sender;
- (IBAction)startAllClicked:(id)sender;
- (IBAction)stopClicked:(id)sender;
- (IBAction)stopAllClicked:(id)sender;
- (IBAction)removeClicked:(id)sender;
- (IBAction)removeAndDeleteClicked:(id)sender;
- (IBAction)addClicked:(id)sender;
- (bool)initEngine;
- (bool)startEngine;
- (void)stopEngine;
- (void)destroyEngine;
- (void)refresh;

- (void)tryAddTorrents:(NSArray *)files;

@end
