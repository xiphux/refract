//
//  PreferencesDelegate.h
//  Refract
//
//  Created by xiphux on 4/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface PreferencesDelegate : NSObject {
@private
    IBOutlet NSWindow *window;
    IBOutlet NSView *general;
    IBOutlet NSView *engine;
    NSView *current;
    IBOutlet NSToolbar *toolbar;
    IBOutlet NSToolbarItem *generalButton;
    IBOutlet NSToolbarItem *engineButton;
}

@property (retain) IBOutlet NSWindow *window;
@property (retain) IBOutlet NSView *general;
@property (retain) IBOutlet NSView *engine;
@property (retain) NSView *current;
@property (retain) NSToolbar *toolbar;
@property (retain) IBOutlet NSToolbarItem *generalButton;
@property (retain) IBOutlet NSToolbarItem *engineButton;

- (void)awakeFromNib;
- (IBAction)switchToGeneral:(id)sender;
- (IBAction)switchToEngine:(id)sender;
- (void)updateWindowSize;

@end
