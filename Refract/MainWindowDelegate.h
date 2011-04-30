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
#import "SourceListController.h"
#import "PreferencesController.h"

@interface MainWindowDelegate : NSObject <NSSplitViewDelegate, RFTorrentListDelegate, RFEngineDelegate, SourceListControllerDelegate> {
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

@property (assign) RFEngine *engine;
@property (retain) RFTorrentList *torrentList;

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
- (void)sourceListSelectionChanged:(NSNotification *)notification;

@end
