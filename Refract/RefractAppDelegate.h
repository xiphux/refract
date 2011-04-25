//
//  RefractAppDelegate.h
//  Refract
//
//  Created by xiphux on 4/24/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "PreferencesController.h"
#import "MainWindowController.h"

@interface RefractAppDelegate : NSObject <NSApplicationDelegate> {
@private
    PreferencesController *preferencesController;
    MainWindowController *mainWindowController;
}

- (IBAction)openPreferences:(id)sender;

@end
