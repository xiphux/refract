//
//  MainWindowController.m
//  Refract
//
//  Created by xiphux on 4/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainWindowController.h"


@implementation MainWindowController

- (id)init
{
    self = [super initWithWindowNibName:@"MainWindow"];
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
    [window makeKeyAndOrderFront:nil];
}

@end
