//
//  RefractAppDelegate.m
//  Refract
//
//  Created by xiphux on 4/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RefractAppDelegate.h"
#import "RFConstants.h"
#import "NotificationController.h"
#import "MainWindowDelegate.h"
#import "RFServerList.h"

@implementation RefractAppDelegate

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [preferencesController release];
    [mainWindowController release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *appDefaults = [NSMutableDictionary dictionary];
    
    [appDefaults setObject:[NSNumber numberWithDouble:5.0] forKey:REFRACT_USERDEFAULT_UPDATE_FREQUENCY];
    
    [defaults registerDefaults:appDefaults];
    
    [[NotificationController sharedNotificationController] setDefaults];
    
    mainWindowController = [[MainWindowController alloc] init];
    [mainWindowController showWindow:self];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [[RFServerList sharedServerList] save];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    if (!flag) {
        [mainWindowController showWindow:self];
    }
    return TRUE;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
    if (!filenames) {
        [sender replyToOpenOrPrint:NSApplicationDelegateReplyFailure];
        return;
    }
    
    if ([filenames count] == 0) {
        [sender replyToOpenOrPrint:NSApplicationDelegateReplyFailure];
        return;
    }
    
    NSMutableArray *torrents = [NSMutableArray array];
    for (NSString *path in filenames) {
        if ([[path pathExtension] isEqualToString:@"torrent"]) {
            [torrents addObject:path];
        }
    }
    
    if ([torrents count] == 0) {
        [sender replyToOpenOrPrint:NSApplicationDelegateReplyFailure];
        return;
    }
    
    [(MainWindowDelegate *)[[mainWindowController window] delegate] tryAddTorrents:torrents];
    
    [sender replyToOpenOrPrint:NSApplicationDelegateReplySuccess];
    return;
}

- (IBAction)openPreferences:(id)sender
{
    if (preferencesController == nil) {
        preferencesController = [[PreferencesController alloc] init];
    }
    [preferencesController showWindow:self];
}

@end
