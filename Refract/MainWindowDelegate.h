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

@interface MainWindowDelegate : NSObject <NSSplitViewDelegate, RFTorrentListDelegate, RFEngineDelegate, SourceListDelegate, TorrentItemDelegate> {
@private
    NSWindow IBOutlet *window;
    SourceListController IBOutlet *sourceListController;
    NSArrayController IBOutlet *torrentListController;
    NSSearchField IBOutlet *searchField;
    NSButton IBOutlet *statsButton;
    NSTextField IBOutlet *rateText;
    NSMenu IBOutlet *removeMenu;
    NSSegmentedControl IBOutlet *removeButton;
    
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

@property (retain) RFEngine *engine;
@property (retain) RFTorrentList *torrentList;
@property (retain) RFGroupList *groupList;

- (IBAction)search:(id)sender;
- (IBAction)statsButtonClick:(id)sender;
- (IBAction)startStopClicked:(id)sender;
- (IBAction)removeClicked:(id)sender;
- (IBAction)removeAndDeleteClicked:(id)sender;
- (IBAction)addClicked:(id)sender;
- (bool)addTorrentFile:(NSURL *)url;
- (bool)initEngine;
- (bool)startEngine;
- (void)stopEngine;
- (void)destroyEngine;
- (void)refresh;
- (void)settingsChanged:(NSNotification *)notification;

@end
