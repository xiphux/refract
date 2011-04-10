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

@interface RefractAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow IBOutlet *window;
    SourceListController IBOutlet *sourceListController;
    RFEngine *engine;
    RFTorrentList *torrentList;
    NSTimer *updateTimer;
    bool started;
}

@property (assign) IBOutlet NSWindow *window;
@property (retain) IBOutlet SourceListController *sourceListController;
@property (assign) RFEngine *engine;
@property (retain) RFTorrentList *torrentList;
@property (retain) NSTimer *updateTimer;

- (IBAction)openPreferences:(id)sender;
- (void)setDefaults;
- (bool)initEngine;
- (bool)startEngine;
- (void)stopEngine;
- (void)destroyEngine;
- (void)refresh;
- (void)settingsChanged:(NSNotification *)notification;

@end
