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

- (void)awakeFromNib
{
    [controller setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:true]]];
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

@end
