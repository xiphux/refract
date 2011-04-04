//
//  PreferencesDelegate.m
//  Refract
//
//  Created by xiphux on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PreferencesDelegate.h"


@implementation PreferencesDelegate

@synthesize window;
@synthesize general;
@synthesize engine;
@synthesize toolbar;
@synthesize generalButton;
@synthesize engineButton;

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
    NSView *contentView = [window contentView];
    [[contentView animator] addSubview:general];
    current = general;
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
}

- (IBAction)switchToEngine:(id)sender
{
    if (current == engine) {
        return;
    }
    [self setCurrent:engine];
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

@end
