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

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    if (!flag) {
        [mainWindowController showWindow:self];
    }
    return TRUE;
}

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename
{
    if ([[filename pathExtension] isEqualToString:@"torrent"]) {
        NSURL *fileUrl = [NSURL fileURLWithPath:filename];
        [(MainWindowDelegate *)[[mainWindowController window] delegate] addTorrentFile:fileUrl];
        return YES;
    }
    return NO;
}

- (IBAction)openPreferences:(id)sender
{
    if (preferencesController == nil) {
        preferencesController = [[PreferencesController alloc] init];
    }
    [preferencesController showWindow:self];
}

@end
