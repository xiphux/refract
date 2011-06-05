//
//  PreferencesDelegate.m
//  Refract
//
//  Created by xiphux on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PreferencesDelegate.h"
#import "RFConstants.h"
#import "RFServerList.h"
#import "RFServer.h"

@interface PreferencesDelegate ()

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void)doRemoveServer:(RFServer *)server;

@end

@implementation PreferencesDelegate

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
    [window release];
    [serversPage release];
    [notificationsPage release];
    [toolbar release];
    [serversButton release];
    [notificationsButton release];
    [serverList release];
    [super dealloc];
}

@synthesize serverList;

- (NSView *)current
{
    return current;
}

- (void)setCurrent:(NSView *)newView
{
    if (!current) {
        current = newView;
        return;
    }
    NSView *contentView = [window contentView];
    [[contentView animator] replaceSubview:current with:newView];
    current = newView;
    [self updateWindowSize];
}

- (void)awakeFromNib
{
    NSView *contentView = [window contentView];
    [[contentView animator] addSubview:serversPage];
    current = serversPage;
    [window setTitle:@"Servers"];
    [toolbar setSelectedItemIdentifier:[serversButton itemIdentifier]];
    [self updateWindowSize];
    [window makeKeyAndOrderFront:self];
    [self setServerList:[RFServerList sharedServerList]];
}

- (IBAction)switchToServers:(id)sender
{
    if (current == serversPage) {
        return;
    }
    [self setCurrent:serversPage];
    [window setTitle:@"Servers"];
}

- (IBAction)switchToNotifications:(id)sender
{
    if (current == notificationsPage) {
        return;
    }
    [self setCurrent:notificationsPage];
    [window setTitle:@"Notifications"];
}

- (void)updateWindowSize
{
    NSRect contentFrame = [[window contentView] frame];
    NSRect newFrame = [current frame];
    NSRect windowFrame = [window frame];
    
    CGFloat widthChange = newFrame.size.width - contentFrame.size.width;
    CGFloat heightChange = newFrame.size.height - contentFrame.size.height;
    
    windowFrame.size.height += heightChange;
    windowFrame.size.width += widthChange;
    windowFrame.origin.y -= heightChange;
    
    [window setFrame:windowFrame display:true animate:true];
}

- (IBAction)addServer:(id)sender
{
    NSString *name = @"New Server";
    NSUInteger num = 0;
    while ([[RFServerList sharedServerList] serverWithNameExists:name]) {
        name = [NSString stringWithFormat:@"New Server %d", ++num];
    }
    
    RFServer *newServer = [[[RFServer alloc] init] autorelease];
    [newServer setName:name];
    
    [serverList insertObject:newServer inServersAtIndex:[serverList countOfServers]];
    [newServer start];
}

- (IBAction)removeServer:(id)sender
{
    if ([[serverListController selectedObjects] count] < 1) {
        return;
    }
    
    RFServer *selectedServer = [[serverListController selectedObjects] objectAtIndex:0];
    
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Remove"];
    [alert setMessageText:[NSString stringWithFormat:@"Are you sure you want to remove the server \"%@\"?", [selectedServer name]]];
    [alert setInformativeText:@"All information associated with this server, including groups, will be discarded."];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSDictionary *context = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:selectedServer, @"remove", nil] forKeys:[NSArray arrayWithObjects:@"server", @"type", nil]];
    
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:context];
}

- (void)doRemoveServer:(RFServer *)server
{
    if (!server) {
        return;
    }
    
    if ([server started]) {
        [server stop];
    }
    
    NSUInteger idx = [[serverList servers] indexOfObject:server];
    if (idx != NSNotFound) {
        [serverList removeObjectFromServersAtIndex:idx];
    }
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    NSDictionary *context = (NSDictionary *)contextInfo;
    
    NSString *type = [context objectForKey:@"type"];
    
    if ([type isEqualToString:@"remove"]) {
        if (returnCode == NSAlertSecondButtonReturn) {
            [self doRemoveServer:[context objectForKey:@"server"]];
        }
    }
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    if ([control isEqual:serverNameField]) {
        if ([[fieldEditor string] length] == 0) {
            return false;
        }
        
        RFServer *selectedServer = [[serverListController selectedObjects] objectAtIndex:0];
        
        RFServer *existingServer = [serverList serverWithName:[fieldEditor string]];
        
        if (existingServer && (![selectedServer isEqual:existingServer])) {
            return false;
        }
    }
    
    return true;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [engineOptionTabs selectTabViewItemAtIndex:1];
    [engineField setEnabled:false];
    
    if ([[serverListController selectedObjects] count] == 0) {
        return;
    }
    
    RFServer *selectedServer = [[serverListController selectedObjects] objectAtIndex:0];
    [engineField setEnabled:true];
    [engineField selectItemWithTag:[[selectedServer engine] type]];
    if ([[selectedServer engine] type] == engTransmission) {
        [engineOptionTabs selectTabViewItemAtIndex:0];
    }
}

@end
