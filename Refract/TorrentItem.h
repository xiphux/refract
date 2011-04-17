//
//  TorrentItem.h
//  Refract
//
//  Created by xiphux on 4/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TorrentItem : NSCollectionViewItem {
@private
    NSTextField IBOutlet *upperLabel;
    NSTextField IBOutlet *lowerLabel;
}

@property (retain) IBOutlet NSTextField *upperLabel;
@property (retain) IBOutlet NSTextField *lowerLabel;

@end
