//
//  TorrentListController.m
//  Refract
//
//  Created by xiphux on 5/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TorrentListController.h"

@interface TorrentListController ()
- (NSPredicate *)searchPredicate;
- (void)updateFilter;
- (void)listButton:(NSNotification *)notification;
- (void)changeSort:(id)sender;
@end


@implementation TorrentListController

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

@synthesize controller;
@synthesize listView;
@synthesize searchField;
@synthesize listButton;

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(listButton:) name:NSPopUpButtonWillPopUpNotification object:listButton];
    
    [controller setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:true]]];
    listSort = sortName;
}

- (NSArray *)selectedObjects
{
    return [controller selectedObjects];
}

- (NSArray *)arrangedObjects
{
    return [controller arrangedObjects];
}

- (void)rearrangeObjects
{
    [controller rearrangeObjects];
}

- (IBAction)search:(id)sender
{
    [self updateFilter];
}

- (void)setGroupFilter:(NSUInteger)gid
{
    listPredicate = [NSPredicate predicateWithFormat:@"group == %d", gid];
    [searchField setStringValue:@""];
    [self updateFilter];
}

- (void)setStatusFilter:(RFTorrentStatus)status
{
    listPredicate = [NSPredicate predicateWithFormat:@"status == %d", status];
    [searchField setStringValue:@""];
    [self updateFilter];
}

- (void)clearFilter
{
    listPredicate = nil;
    [searchField setStringValue:@""];
    [self updateFilter];
}



- (NSPredicate *)searchPredicate
{
    NSString *searchText = [searchField stringValue];
    if ([searchText length] == 0) {
        return nil;
    }
    
    NSMutableArray *keywordPredicates = [NSMutableArray array];
    
    NSArray *keywords = [searchText componentsSeparatedByString:@" "];
    if ([keywords count] > 0) {
        for (NSString *word in keywords) {
            if ([word length] > 0) {
                [keywordPredicates addObject:[NSPredicate predicateWithFormat:@"name contains[cd] %@", word]];
            }
        }
    }
    
    if ([keywordPredicates count] == 0) {
        return nil;
    }
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:keywordPredicates];
}

- (void)updateFilter
{
    NSPredicate *search = [self searchPredicate];
    
    if (search && listPredicate) {
        [controller setFilterPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:search, listPredicate, nil]]];
    } else if (search) {
        [controller setFilterPredicate:search];
    } else if (listPredicate) {
        [controller setFilterPredicate:listPredicate];
    } else {
        [controller setFilterPredicate:nil];
    }
}

- (void)listButton:(NSNotification *)notification
{
    NSMenu *menu = [listButton menu];
    
    NSMenuItem *title = [menu itemAtIndex:0];
    
    [menu removeAllItems];
    
    [menu addItem:title];
    
    NSMenuItem *sortMenuItem = [[NSMenuItem alloc] initWithTitle:@"Sort" action:nil keyEquivalent:@""];
    NSMenu *sortSubMenu = [[NSMenu alloc] initWithTitle:@"Sort"];
    [sortMenuItem setSubmenu:sortSubMenu];
    
    for (NSUInteger i = sortName; i <= sortUploadRate; i++) {
        NSString *name = nil;
        switch (i) {
            case sortName:
                name = @"Name";
                break;
            case sortDateAdded:
                name = @"Date Added";
                break;
            case sortDateDone:
                name = @"Date Done";
                break;
            case sortProgress:
                name = @"Progress";
                break;
            case sortDownloadRate:
                name = @"Download Rate";
                break;
            case sortUploadRate:
                name = @"Upload Rate";
                break;
            default:
                continue;
        }
        NSMenuItem *sortItem = [[NSMenuItem alloc] initWithTitle:name action:@selector(changeSort:) keyEquivalent:@""];
        [sortItem setTag:i];
        [sortItem setTarget:self];
        if (listSort == i) {
            [sortItem setState:NSOnState];
        }
        [sortSubMenu addItem:sortItem];
    }
    [menu addItem:sortMenuItem];
}

- (void)changeSort:(id)sender
{
    NSUInteger newSort = [sender tag];
    
    NSSortDescriptor *desc = nil;
    
    switch (newSort) {
        case sortName:
            desc = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:true];
            break;
        case sortDateAdded:
            desc = [NSSortDescriptor sortDescriptorWithKey:@"addedDate" ascending:false];
            break;
        case sortDateDone:
            desc = [NSSortDescriptor sortDescriptorWithKey:@"doneDate" ascending:false];
            break;
        case sortProgress:
            desc = [NSSortDescriptor sortDescriptorWithKey:@"percent" ascending:false];
            break;
        case sortDownloadRate:
            desc = [NSSortDescriptor sortDescriptorWithKey:@"downloadRate" ascending:false];
            break;
        case sortUploadRate:
            desc = [NSSortDescriptor sortDescriptorWithKey:@"uploadRate" ascending:false];
            break;
    }
    
    if (desc) {
        [controller setSortDescriptors:[NSArray arrayWithObject:desc]];
        listSort = newSort;
    }
}

@end
