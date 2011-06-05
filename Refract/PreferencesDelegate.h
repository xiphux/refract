//
//  PreferencesDelegate.h
//  Refract
//
//  Created by xiphux on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RFServerList.h"

@interface PreferencesDelegate : NSObject <NSTextFieldDelegate, NSTableViewDelegate> {
@private
    IBOutlet NSWindow *window;
    IBOutlet NSView *serversPage;
    IBOutlet NSView *notificationsPage;
    
    NSView *current;
    
    IBOutlet NSToolbar *toolbar;
    IBOutlet NSToolbarItem *serversButton;
    IBOutlet NSToolbarItem *notificationsButton;
    
    IBOutlet NSTextField *serverNameField;
    
    IBOutlet NSTabView *engineOptionTabs;
    IBOutlet NSPopUpButton *engineField;
    IBOutlet NSTextField *transmissionURLField;
    IBOutlet NSTextField *transmissionUsernameField;
    IBOutlet NSTextField *transmissionPasswordField;
    
    RFServerList *serverList;
    IBOutlet NSArrayController *serverListController;
}

@property (retain) NSView *current;
@property (retain) RFServerList *serverList;

- (void)awakeFromNib;
- (IBAction)switchToServers:(id)sender;
- (IBAction)switchToNotifications:(id)sender;
- (void)updateWindowSize;

- (IBAction)addServer:(id)sender;
- (IBAction)removeServer:(id)sender;

@end
