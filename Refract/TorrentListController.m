//
//  TorrentListController.m
//  Refract
//
//  Created by xiphux on 5/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TorrentListController.h"
#import "RFConstants.h"

@interface TorrentListController ()
- (NSPredicate *)searchPredicate;
- (void)updateFilter;
- (void)listButton:(NSNotification *)notification;
- (void)changeSort:(id)sender;
- (NSSortDescriptor *)descriptorForSort:(TorrentListSort)sort;
- (NSArray *)sortDescriptorArray;
- (void)setDefaults;
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
    [controller release];
    [listView release];
    [searchField release];
    [listButton release];
    [filter release];
    [super dealloc];
}

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(listButton:) name:NSPopUpButtonWillPopUpNotification object:listButton];
    
    [self setDefaults];
    
    [controller setSortDescriptors:[self sortDescriptorArray]];
    NSArray *sorts = [[NSUserDefaults standardUserDefaults] arrayForKey:REFRACT_USERDEFAULT_SORT];
    if (sorts && ([sorts count] > 0)) {
        listSort = [[sorts objectAtIndex:0] intValue];
    }
}

- (void)setDefaults
{
    NSMutableDictionary *def = [NSMutableDictionary dictionary];
    
    [def setObject:[NSArray arrayWithObject:[NSNumber numberWithInt:(int)sortName]] forKey:REFRACT_USERDEFAULT_SORT];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:def];
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

- (RFTorrentFilter *)filter
{
    return filter;
}

- (void)setFilter:(RFTorrentFilter *)newFilter
{
    if ([filter isEqual:newFilter]) {
        return;
    }
    
    [filter release];
    filter = [newFilter retain];
    
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
    NSPredicate *filterPredicate = [filter predicate];
    
    if (search && filterPredicate) {
        [controller setFilterPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:search, filterPredicate, nil]]];
    } else if (search) {
        [controller setFilterPredicate:search];
    } else if (filterPredicate) {
        [controller setFilterPredicate:filterPredicate];
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
    
    NSMenuItem *sortMenuItem = [[[NSMenuItem alloc] initWithTitle:@"Sort" action:nil keyEquivalent:@""] autorelease];
    NSMenu *sortSubMenu = [[[NSMenu alloc] initWithTitle:@"Sort"] autorelease];
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
        NSMenuItem *sortItem = [[[NSMenuItem alloc] initWithTitle:name action:@selector(changeSort:) keyEquivalent:@""] autorelease];
        [sortItem setTag:i];
        [sortItem setTarget:self];
        if (listSort == i) {
            [sortItem setState:NSOnState];
        }
        [sortSubMenu addItem:sortItem];
    }
    [menu addItem:sortMenuItem];
}

- (NSSortDescriptor *)descriptorForSort:(TorrentListSort)sort
{
    switch (sort) {
        case sortName:
            return [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:true];
            break;
        case sortDateAdded:
            return [NSSortDescriptor sortDescriptorWithKey:@"addedDate" ascending:false];
            break;
        case sortDateDone:
            return [NSSortDescriptor sortDescriptorWithKey:@"doneDate" ascending:false];
            break;
        case sortProgress:
            return [NSSortDescriptor sortDescriptorWithKey:@"percent" ascending:false];
            break;
        case sortDownloadRate:
            return [NSSortDescriptor sortDescriptorWithKey:@"downloadRate" ascending:false];
            break;
        case sortUploadRate:
            return [NSSortDescriptor sortDescriptorWithKey:@"uploadRate" ascending:false];
            break;
    }
    return nil;
}

- (NSArray *)sortDescriptorArray
{
    NSArray *sorts = [[NSUserDefaults standardUserDefaults] arrayForKey:REFRACT_USERDEFAULT_SORT];
    if (!sorts) {
        return nil;
    }
    
    if ([sorts count] == 0) {
        return nil;
    }
    
    NSMutableArray *descriptors = [NSMutableArray array];
    
    for (NSNumber *sort in sorts) {
        NSSortDescriptor *desc = [self descriptorForSort:[sort intValue]];
        if (desc) {
            [descriptors addObject:desc];
        }
    }
    
    return descriptors;  
}

- (void)changeSort:(id)sender
{
    NSUInteger newSort = [sender tag];
    
    if (newSort == listSort) {
        return;
    }
    
    NSMutableArray *sorts = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] arrayForKey:REFRACT_USERDEFAULT_SORT]];
    if ([sorts count] == 3) {
        [sorts removeLastObject];
    }
    [sorts insertObject:[NSNumber numberWithInt:(int)newSort] atIndex:0];
    [[NSUserDefaults standardUserDefaults] setObject:sorts forKey:REFRACT_USERDEFAULT_SORT];
    [controller setSortDescriptors:[self sortDescriptorArray]];
    listSort = newSort;
}

@end
