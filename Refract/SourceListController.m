//
//  SourceListController.m
//  Refract
//
//  Created by xiphux on 4/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SourceListController.h"

#import "BaseNode.h"
#import "CategoryNode.h"
#import "StatusNode.h"

@interface SourceListController ()
- (void)createStandardNodes;
- (NSUInteger)statusSortIndex:(RFTorrentStatus)status;
- (void)doRemoveStatusGroup:(RFTorrentStatus)remStatus;
@end

@implementation SourceListController

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

@synthesize treeController;
@synthesize sourceList;
@synthesize filter;

- (void)awakeFromNib
{
    NSSortDescriptor *indexsd = [NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:true];
    NSSortDescriptor *titlesd = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:true];
    [treeController setSortDescriptors:[NSArray arrayWithObjects:indexsd, titlesd, nil]];
    
    filter = [[RFTorrentFilter alloc] initWithType:filtNone];
    manipulatingSourceList = true;
    [self createStandardNodes];
    [sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:false];
    manipulatingSourceList = false;
}

- (void)createStandardNodes
{
    BaseNode *allNode = [[BaseNode alloc] init];
    [allNode setTitle:@"All"];
    [allNode setIsLeaf:true];
    [allNode setSortIndex:0];
    NSIndexPath *allPath = [NSIndexPath indexPathWithIndex:0];
    [treeController insertObject:allNode atArrangedObjectIndexPath:allPath];
}

- (void)addStatusGroup:(RFTorrentStatus)newStatus
{
    CategoryNode *statusCat = nil;
    NSIndexPath *path = nil;
    
    NSArray *nodes = [[treeController arrangedObjects] childNodes];
    
    if (removeStatus == newStatus) {
        removeStatus = 0;
    }
    
    for (NSUInteger i = 0; i < [nodes count]; i++) {
        id node = [[nodes objectAtIndex:i] representedObject];
        if ([node isKindOfClass:[CategoryNode class]]) {
            if ([node categoryType] == catStatus) {
                statusCat = node;
                path = [NSIndexPath indexPathWithIndex:i];
                break;
            }
        }
    }
    
    if (statusCat == nil) {
        statusCat = [[CategoryNode alloc] init];
        [statusCat setTitle:@"Status"];
        [statusCat setSortIndex:1];
        [statusCat setIsLeaf:false];
        path = [NSIndexPath indexPathWithIndex:1];
        manipulatingSourceList = true;
        [treeController insertObject:statusCat atArrangedObjectIndexPath:path];
        manipulatingSourceList = false;
    } else {
        for (NSUInteger i = 0; i < [[statusCat children] count]; i++) {
            id stat = [[statusCat children] objectAtIndex:i];
            if ([stat isKindOfClass:[StatusNode class]]) {
                if ([stat status] == newStatus) {
                    return;
                }
            }
        }
    }
    
    NSIndexPath *itemPath = [path indexPathByAddingIndex:[[statusCat children] count]];
    StatusNode *sNode = [[StatusNode alloc] init];
    switch (newStatus) {
        case stDownloading:
            [sNode setTitle:@"Downloading"];
            break;
        case stSeeding:
            [sNode setTitle:@"Seeding"];
            break;
        case stChecking:
            [sNode setTitle:@"Checking"];
            break;
        case stWaiting:
            [sNode setTitle:@"Waiting"];
            break;
        case stStopped:
            [sNode setTitle:@"Stopped"];
            break;
    }
    [sNode setIsLeaf:true];
    [sNode setStatus:newStatus];
    manipulatingSourceList = true;
    [treeController insertObject:sNode atArrangedObjectIndexPath:itemPath];
    [treeController rearrangeObjects];
    manipulatingSourceList = false;
}

- (void)removeStatusGroup:(RFTorrentStatus)remStatus
{
    NSArray *selection = [treeController selectedObjects];
    if ([selection count] > 0) {
        BaseNode *node = [selection objectAtIndex:0];
        if ([node isKindOfClass:[StatusNode class]]) {
            if ([node status] == remStatus) {
                removeStatus = remStatus;
                return;
            }
        }
    }
    
    [self doRemoveStatusGroup:remStatus];
}

- (void)tryRemoveStatusGroup
{
    if (removeStatus == 0) {
        return;
    }
    
    NSArray *selection = [treeController selectedObjects];
    if ([selection count] > 0) {
        BaseNode *node = [selection objectAtIndex:0];
        if ([node isKindOfClass:[StatusNode class]]) {
            if ([node status] == removeStatus) {
                return;
            }
        }
    }
    
    [self doRemoveStatusGroup:removeStatus];
    removeStatus = 0;
}

- (void)doRemoveStatusGroup:(RFTorrentStatus)remStatus
{
    NSTreeNode *statusNode = nil;
    
    NSArray *nodes = [[treeController arrangedObjects] childNodes];
    
    for (NSUInteger i = 0; i < [nodes count]; i++) {
        id treenode = [nodes objectAtIndex:i];
        id datanode = [treenode representedObject];
        if ([datanode isKindOfClass:[CategoryNode class]]) {
            if ([datanode categoryType] == catStatus) {
                statusNode = treenode;
                break;
            }
        }
    }
    
    if (statusNode != nil) {
        for (NSUInteger i = 0; i < [[statusNode childNodes] count]; i++) {
            id treenode = [[statusNode childNodes] objectAtIndex:i];
            id datanode = [treenode representedObject];
            if ([datanode isKindOfClass:[StatusNode class]]) {
                if ([datanode status] == remStatus) {
                    manipulatingSourceList = true;
                    [treeController removeObjectAtArrangedObjectIndexPath:[treenode indexPath]];
                    if ([[statusNode childNodes] count] == 0) {
                        [treeController removeObjectAtArrangedObjectIndexPath:[statusNode indexPath]];
                    }
                    manipulatingSourceList = false;
                    break;
                }
            }
        }
    }
}

- (NSUInteger)statusSortIndex:(RFTorrentStatus)status
{
    switch (status) {
        case stDownloading:
            return 1;
            break;
        case stSeeding:
            return 2;
            break;
        case stChecking:
            return 3;
            break;
        case stWaiting:
            return 4;
            break;
        case stStopped:
            return 5;
            break;
        default:
            return 0;
            break;
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    if ([[item representedObject] isKindOfClass:[CategoryNode class]]) {
        return YES;
    }
    return NO;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([[item representedObject] isKindOfClass:[CategoryNode class]]) {
        NSMutableAttributedString *newTitle = [[cell attributedStringValue] mutableCopy];
        [newTitle replaceCharactersInRange:NSMakeRange(0, [newTitle length]) withString:[[newTitle string] uppercaseString]];
        [cell setAttributedStringValue:newTitle];
        [newTitle release];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    if ([[item representedObject] isKindOfClass:[CategoryNode class]]) {
        return NO;
    }
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return false;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    if (manipulatingSourceList) {
        return;
    }
    
    NSArray *selection = [treeController selectedObjects];
    if ([selection count] == 0) {
        [treeController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:0]];
        return;
    }
    BaseNode *node = [selection objectAtIndex:0];
    
    RFTorrentFilter *newFilter;
    
    if ([node isKindOfClass:[StatusNode class]]) {
        newFilter = [[RFTorrentFilter alloc] initWithStatus:[node status]];
    } else if (![node isKindOfClass:[CategoryNode class]]) {
        if ([[node title] isEqualToString:@"All"]) {
            newFilter = [[RFTorrentFilter alloc] initWithType:filtNone];
        }
    }
    
    if (!newFilter) {
        return;
    }
    
    if (![newFilter isEqual:filter]) {
        filter = newFilter;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SourceListSelectionChanged" object:self];
    }
    
    [newFilter release];
        
    if (removeStatus > 0) {
        [self performSelector:@selector(tryRemoveStatusGroup) withObject:nil afterDelay:1.0];
    }
}

@end
