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
- (CategoryNode *)findCategoryNode:(CategoryNodeType)type;
- (NSUInteger)statusSortIndex:(RFTorrentStatus)status;
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

- (void)awakeFromNib
{
    NSSortDescriptor *indexsd = [NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:true];
    NSSortDescriptor *titlesd = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:true];
    [treeController setSortDescriptors:[NSArray arrayWithObjects:indexsd, titlesd, nil]];
    
    [self createStandardNodes];
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
        [treeController insertObject:statusCat atArrangedObjectIndexPath:path];
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
    [treeController insertObject:sNode atArrangedObjectIndexPath:itemPath];
    
    [treeController rearrangeObjects];
}

- (void)removeStatusGroup:(RFTorrentStatus)remStatus
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
                    [treeController removeObjectAtArrangedObjectIndexPath:[treenode indexPath]];
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

- (CategoryNode *)findCategoryNode:(CategoryNodeType)type
{
    for (id node in [treeController arrangedObjects]) {
        if ([node isKindOfClass:[CategoryNode class]]) {
            if ([node categoryType] == type) {
                return node;
            }
        }
    }
    
    return nil;
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

@end
