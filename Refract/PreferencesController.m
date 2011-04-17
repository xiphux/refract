//
//  PreferencesController.m
//  Refract
//
//  Created by xiphux on 4/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PreferencesController.h"


@implementation PreferencesController

- (id)init
{
    self = [super initWithWindowNibName:@"Preferences"];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (IBAction)showWindow:(id)sender
{
    NSWindow *window = [self window];
    if (![window isVisible]) {
        [window center];
    }
    [window makeKeyAndOrderFront:nil];
}

@end
