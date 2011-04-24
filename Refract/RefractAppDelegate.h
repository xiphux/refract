//
//  RefractAppDelegate.h
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

@interface RefractAppDelegate : NSObject <NSApplicationDelegate, NSSplitViewDelegate, RFTorrentListDelegate, RFEngineDelegate> {
@private
    NSWindow IBOutlet *window;
    SourceListController IBOutlet *sourceListController;
    NSArrayController IBOutlet *torrentListController;
    PreferencesController *preferencesController;
    NSSearchField IBOutlet *searchField;
    NSButton IBOutlet *statsButton;
    NSTextField IBOutlet *rateText;
    
    RFEngine *engine;
    RFTorrentList *torrentList;
    NSPredicate *searchPredicate;
    
    bool showTotalStats;
    bool started;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) IBOutlet NSArrayController *torrentListController;
@property (retain) IBOutlet SourceListController *sourceListController;
@property (retain) IBOutlet NSSearchField *searchField;
@property (retain) IBOutlet NSTextField *rateText;
@property (retain) IBOutlet NSButton *statsButton;

@property (assign) RFEngine *engine;
@property (retain) RFTorrentList *torrentList;

- (IBAction)openPreferences:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)statsButtonClick:(id)sender;
- (IBAction)startStopClicked:(id)sender;
- (void)setDefaults;
- (bool)initEngine;
- (bool)startEngine;
- (void)stopEngine;
- (void)destroyEngine;
- (void)refresh;
- (void)settingsChanged:(NSNotification *)notification;
- (void)sourceListSelectionChanged:(NSNotification *)notification;

@end
