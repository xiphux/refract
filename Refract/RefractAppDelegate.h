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
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) RFEngine *engine;
@property (retain) RFTorrentList *torrentList;

- (IBAction)openPreferences:(id)sender;
- (bool)initEngine;
- (void)destroyEngine;

@end
