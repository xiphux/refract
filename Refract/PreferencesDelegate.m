//
//  PreferencesDelegate.m
//  Refract
//
//  Created by xiphux on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PreferencesDelegate.h"
#import "EMKeychainItem.h"
#import "RFConstants.h"

@implementation PreferencesDelegate

@synthesize window;
@synthesize general;
@synthesize engine;
@synthesize notifications;
@synthesize toolbar;
@synthesize generalButton;
@synthesize engineButton;
@synthesize notificationsButton;
@synthesize transmissionUsernameField;
@synthesize transmissionPasswordField;

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
    [super dealloc];
}

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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *tmUser = [defaults stringForKey:REFRACT_USERDEFAULT_TRANSMISSION_USERNAME];
    
    if ([tmUser length] > 0) {
        [self willChangeValueForKey:@"transmissionUsername"];
        transmissionUsername = tmUser;
        [self didChangeValueForKey:@"transmissionUsername"];
        EMGenericKeychainItem *tmPass = [EMGenericKeychainItem genericKeychainItemForService:REFRACT_KEYCHAIN_TRANSMISSION withUsername:transmissionUsername];
        if (tmPass) {
            NSString *passStr = [tmPass password];
            if ([passStr length] > 0) {
                [self willChangeValueForKey:@"transmissionPassword"];
                transmissionPassword = [tmPass password];   
                [self didChangeValueForKey:@"transmissionPassword"];
            }
            [tmPass release];
        }
    }
    
    NSView *contentView = [window contentView];
    [[contentView animator] addSubview:general];
    current = general;
    [window setTitle:@"General"];
    [toolbar setSelectedItemIdentifier:[generalButton itemIdentifier]];
    [self updateWindowSize];
    [window makeKeyAndOrderFront:self];
}

- (IBAction)switchToGeneral:(id)sender
{
    if (current == general) {
        return;
    }
    [self setCurrent:general];
    [window setTitle:@"General"];
}

- (IBAction)switchToEngine:(id)sender
{
    if (current == engine) {
        return;
    }
    [self setCurrent:engine];
    [window setTitle:@"Engine"];
}

- (IBAction)switchToNotifications:(id)sender
{
    if (current == notifications) {
        return;
    }
    [self setCurrent:notifications];
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

- (NSString *)transmissionUsername
{
    return transmissionUsername;
}

- (void)setTransmissionUsername:(NSString *)newTransmissionUsername
{
    if ([newTransmissionUsername isEqualToString:transmissionUsername]) {
        return;
    }
    
    EMGenericKeychainItem *oldPass = [EMGenericKeychainItem genericKeychainItemForService:REFRACT_KEYCHAIN_TRANSMISSION withUsername:transmissionUsername];
    if (oldPass) {
        [oldPass removeFromKeychain];
        [oldPass release];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([newTransmissionUsername length] > 0) {
        EMGenericKeychainItem *existingPass = [EMGenericKeychainItem genericKeychainItemForService:REFRACT_KEYCHAIN_TRANSMISSION withUsername:newTransmissionUsername];
        if (existingPass) {
            [self willChangeValueForKey:@"transmissionPassword"];
            transmissionPassword = [existingPass password];
            [self didChangeValueForKey:@"transmissionPassword"];
        } else {
            [EMGenericKeychainItem addGenericKeychainItemForService:REFRACT_KEYCHAIN_TRANSMISSION withUsername:newTransmissionUsername password:transmissionPassword];
        }
        [defaults setObject:newTransmissionUsername forKey:REFRACT_USERDEFAULT_TRANSMISSION_USERNAME];
    } else {
        [self willChangeValueForKey:@"transmissionPassword"];
        transmissionPassword = nil;
        [self didChangeValueForKey:@"transmissionPassword"];
        [defaults removeObjectForKey:REFRACT_USERDEFAULT_TRANSMISSION_USERNAME];
    }
    
    transmissionUsername = newTransmissionUsername;
}

- (NSString *)transmissionPassword
{
    return transmissionPassword;
}

- (void)setTransmissionPassword:(NSString *)newTransmissionPassword
{
    if ([newTransmissionPassword isEqualToString:transmissionPassword]) {
        return;
    }
    
    if ([transmissionUsername length] == 0) {
        [transmissionPasswordField setStringValue:@""];
        transmissionPassword = nil;
        return;
    }
    
    EMGenericKeychainItem *pass = [EMGenericKeychainItem genericKeychainItemForService:REFRACT_KEYCHAIN_TRANSMISSION withUsername:transmissionUsername];
    if (pass) {
        [pass setPassword:newTransmissionPassword];
    } else {
        [EMGenericKeychainItem addGenericKeychainItemForService:REFRACT_KEYCHAIN_TRANSMISSION withUsername:transmissionUsername password:newTransmissionPassword];
    }
    
    transmissionPassword = newTransmissionPassword;
}

@end
