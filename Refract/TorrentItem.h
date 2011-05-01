//
//  TorrentItem.h
//  Refract
//
//  Created by xiphux on 4/17/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TorrentItemDelegate;

@interface TorrentItem : NSCollectionViewItem {
@private
    NSTextField IBOutlet *upperLabel;
    NSTextField IBOutlet *lowerLabel;
    NSPopUpButton IBOutlet *actionButton;
    
    NSObject <TorrentItemDelegate> IBOutlet *delegate;
}

@property (retain) IBOutlet NSTextField *upperLabel;
@property (retain) IBOutlet NSTextField *lowerLabel;
@property (retain) IBOutlet NSPopUpButton *actionButton;
@property (nonatomic, assign) NSObject <TorrentItemDelegate> *delegate;

- (void)actionButton:(NSNotification *)notification;

@end


@protocol TorrentItemDelegate <NSObject>
@optional
- (NSArray *)torrentItemAvailableGroups:(TorrentItem *)item;
@end