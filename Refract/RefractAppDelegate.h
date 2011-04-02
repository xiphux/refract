//
//  RefractAppDelegate.h
//  Refract
//
//  Created by xiphux on 4/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RefractAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
