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

@interface RefractAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
    RFEngine *engine;
    RFTorrentList *torrentList;
    NSTimer *updateTimer;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) RFEngine *engine;
@property (retain) RFTorrentList *torrentList;
@property (retain) NSTimer *updateTimer;

- (IBAction)openPreferences:(id)sender;
- (void)setDefaults;
- (bool)initEngine;
- (void)destroyEngine;
- (void)refresh;

@end
