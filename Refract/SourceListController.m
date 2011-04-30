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
#import "GroupNode.h"

@interface SourceListController ()
- (void)createStandardNodes;
- (NSUInteger)statusSortIndex:(RFTorrentStatus)status;
- (void)doRemoveStatusGroup:(RFTorrentStatus)remStatus;
- (void)doRemoveGroup:(RFTorrentGroup *)group;
- (NSTreeNode *)findCategoryTreeNode:(CategoryNodeType)type;
- (NSTreeNode *)findStatusTreeNode:(RFTorrentStatus)status inList:(NSArray *)list;
- (NSTreeNode *)findStatusTreeNode:(RFTorrentStatus)status;
- (NSTreeNode *)findSelectedStatusTreeNode:(RFTorrentStatus)status;
- (NSTreeNode *)findGroupTreeNodeWithName:(NSString *)name;
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode
        contextInfo:(void *)contextInfo;
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
@synthesize contextMenu;
@synthesize window;
@synthesize filter;
@synthesize delegate;

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
    [treeController insertObject:allNode atArrangedObjectIndexPath:[NSIndexPath indexPathWithIndex:0]];
    
    CategoryNode *statusCat = [[CategoryNode alloc] init];
    [statusCat setTitle:@"Status"];
    [statusCat setSortIndex:1];
    [statusCat setIsLeaf:false];
    [statusCat setCategoryType:catStatus];
    [treeController insertObject:statusCat atArrangedObjectIndexPath:[NSIndexPath indexPathWithIndex:1]];
    
    CategoryNode *groupCat = [[CategoryNode alloc] init];
    [groupCat setTitle:@"Groups"];
    [groupCat setSortIndex:2];
    [groupCat setIsLeaf:false];
    [groupCat setCategoryType:catGroup];
    NSIndexPath *groupsPath = [NSIndexPath indexPathWithIndex:2];
    [treeController insertObject:groupCat atArrangedObjectIndexPath:groupsPath];
    
    GroupNode *noGroup = [[GroupNode alloc] init];
    [noGroup setTitle:@"No Group"];
    [noGroup setIsLeaf:true];
    [noGroup setSortIndex:0];
    [treeController insertObject:noGroup atArrangedObjectIndexPath:[groupsPath indexPathByAddingIndex:0]];
}

- (NSTreeNode *)findCategoryTreeNode:(CategoryNodeType)type
{
    NSArray *nodes = [[treeController arrangedObjects] childNodes];
    
    for (NSUInteger i = 0; i < [nodes count]; i++) {
        NSTreeNode *tNode = [nodes objectAtIndex:i];
        BaseNode *dNode = [tNode representedObject];
        if ([dNode isKindOfClass:[CategoryNode class]]) {
            if ([(CategoryNode *)dNode categoryType] == type) {
                return tNode;
            }
        }
    }
    
    return nil;
}

- (NSTreeNode *)findStatusTreeNode:(RFTorrentStatus)status inList:(NSArray *)list
{
    if (!list) {
        return nil;
    }
    
    for (NSUInteger i = 0; i < [list count]; i++) {
        NSTreeNode *tNode = [list objectAtIndex:i];
        BaseNode *dNode = [tNode representedObject];
        if ([dNode isKindOfClass:[StatusNode class]]) {
            if ([(StatusNode *)dNode status] == status) {
                return tNode;
            }
        }
    }
    
    return nil;
}

- (NSTreeNode *)findStatusTreeNode:(RFTorrentStatus)status
{
    return [self findStatusTreeNode:status inList:[[self findCategoryTreeNode:catStatus] childNodes]];
}

- (NSTreeNode *)findSelectedStatusTreeNode:(RFTorrentStatus)status
{
    return [self findStatusTreeNode:status inList:[treeController selectedNodes]];
}

- (NSTreeNode *)findGroupTreeNodeWithName:(NSString *)name
{
    if ([name length] == 0) {
        return nil;
    }
    
    NSTreeNode *groupCat = [self findCategoryTreeNode:catGroup];
    if (!groupCat) {
        return nil;
    }
    
    for (NSUInteger i = 0; i < [[groupCat childNodes] count]; i++) {
        NSTreeNode *tNode = [[groupCat childNodes] objectAtIndex:i];
        BaseNode *dNode = [tNode representedObject];
        if ([dNode isKindOfClass:[GroupNode class]]) {
            if ([[(GroupNode *)dNode title] isEqualToString:name]) {
                return tNode;
            }
        }
    }
    
    return nil;
}

- (void)addStatusGroup:(RFTorrentStatus)newStatus
{
    if (removeStatus == newStatus) {
        removeStatus = 0;
    }
    
    NSTreeNode *statusTreeNode = [self findCategoryTreeNode:catStatus];
    if (!statusTreeNode) {
        return;
    }
    
    NSTreeNode *existingNode = [self findStatusTreeNode:newStatus inList:[statusTreeNode childNodes]];
    if (existingNode) {
        return;
    }
    
    NSIndexPath *itemPath = [[statusTreeNode indexPath] indexPathByAddingIndex:[[statusTreeNode childNodes] count]];
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
    if ([self findSelectedStatusTreeNode:remStatus]) {
        removeStatus = remStatus;
        return;
    }
    
    [self doRemoveStatusGroup:remStatus];
}

- (void)tryRemoveStatusGroup
{
    if (removeStatus == 0) {
        return;
    }
    
    if ([self findSelectedStatusTreeNode:removeStatus]) {
        return;
    }
    
    [self doRemoveStatusGroup:removeStatus];
    removeStatus = 0;
}

- (void)doRemoveStatusGroup:(RFTorrentStatus)remStatus
{
    NSTreeNode *statusNode = [self findStatusTreeNode:remStatus];
    if (statusNode) {
        manipulatingSourceList = true;
        [treeController removeObjectAtArrangedObjectIndexPath:[statusNode indexPath]];
        manipulatingSourceList = false;
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

- (IBAction)addGroup:(id)sender
{
    NSTreeNode *groupTreeNode = nil;
    CategoryNode *groupCat = nil;
    
    groupTreeNode = [self findCategoryTreeNode:catGroup];
    if (!groupTreeNode) {
        return;
    }
    
    groupCat = [groupTreeNode representedObject];
    if (!groupCat) {
        return;
    }
    
    bool canadd = true;
    NSString *name = @"New Group";
    
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(sourceList:canAddGroup:)]) {
            canadd = [[self delegate] sourceList:self canAddGroup:name];
        } else {
            canadd = ([self findGroupTreeNodeWithName:name] == nil);
        }
    }
    
    NSUInteger num = 0;
    while (!canadd) {
        num++;
        name = [NSString stringWithFormat:@"New Group %d", num];
        
        if ([self delegate]) {
            if ([[self delegate] respondsToSelector:@selector(sourceList:canAddGroup:)]) {
                canadd = [[self delegate] sourceList:self canAddGroup:name];
            } else {
                canadd = ([self findGroupTreeNodeWithName:name] == nil);
            }
        }
        
    }
    
    NSIndexPath *itemPath = [[groupTreeNode indexPath] indexPathByAddingIndex:[[groupCat children] count]];
    GroupNode *newNode = [[GroupNode alloc] init];
    [newNode setTitle:name];
    [newNode setIsLeaf:true];
    [newNode setSortIndex:1];
    manipulatingSourceList = true;
    [treeController insertObject:newNode atArrangedObjectIndexPath:itemPath];
    [treeController rearrangeObjects];
    manipulatingSourceList = false;
    
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(sourceList:didAddGroup:)]) {
            RFTorrentGroup *newGroup = [[self delegate] sourceList:self didAddGroup:name];
            if (newGroup) {
                [newNode setGroup:newGroup];
            }
        }
    }
}

- (IBAction)removeGroup:(id)sender
{
    NSInteger clickedRow = [sourceList clickedRow];
    id item = nil;
    BaseNode *node = nil;
    if (clickedRow == -1) {
        return;
    }
    
    item = [sourceList itemAtRow:clickedRow];
    node = [item representedObject];
    
    if (!node) {
        return;
    }
    
    if (![node isKindOfClass:[GroupNode class]]) {
        return;
    }
    
    bool canremove = true;
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(sourceList:canRemoveGroup:)]) {
            if ([(GroupNode *)node group]) {
                canremove = [[self delegate] sourceList:self canRemoveGroup:[(GroupNode *)node group]];
            }
        }
    }
    
    if (!canremove) {
        return;
    }
    
    NSUInteger count = 0;
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(sourceList:torrentsInGroup:)]) {
            if ([(GroupNode *)node group]) {
                count = [[self delegate] sourceList:self torrentsInGroup:[(GroupNode *)node group]];
            }
        }
    }

    if (count == 0) {
        [self doRemoveGroup:[(GroupNode *)node group]];
        return;
    }
    
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Delete"];
    [alert setMessageText:@"Are you sure you want to delete this group?"];
    [alert setInformativeText:[NSString stringWithFormat:@"%d torrents will be returned to the default group.", count]];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSDictionary *context = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[(GroupNode *)node group], @"removegroup", nil] forKeys:[NSArray arrayWithObjects:@"group", @"type", nil]];
    
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:context];
}

- (void)doRemoveGroup:(RFTorrentGroup *)group
{
    if (!group) {
        return;
    }
    
    NSTreeNode *groupCat = [self findCategoryTreeNode:catGroup];
    if (!groupCat) {
        return;
    }
    
    for (NSUInteger i = 0; i < [[groupCat childNodes] count]; i++) {
        NSTreeNode *treenode = [[groupCat childNodes] objectAtIndex:i];
        BaseNode *datanode = [treenode representedObject];
        if ([datanode isKindOfClass:[GroupNode class]]) {
            if ([[(GroupNode *)datanode group] isEqual:group]) {
                [treeController removeObjectAtArrangedObjectIndexPath:[treenode indexPath]];
                
                if ([self delegate]) {
                    if ([[self delegate] respondsToSelector:@selector(sourceList:didRemoveGroup:)]) {
                        if ([(GroupNode *)datanode group]) {
                            [[self delegate] sourceList:self didRemoveGroup:[(GroupNode *)datanode group]];
                        }
                    }
                }
                
                break;
            }
        }
    }
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    NSDictionary *context = (NSDictionary *)contextInfo;
    NSString *type = [context objectForKey:@"type"];
    
    if ([type isEqualToString:@"removegroup"]) {
        if (returnCode == NSAlertSecondButtonReturn) {
            [self doRemoveGroup:[context objectForKey:@"group"]];
        }
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
    if ([[item representedObject] isKindOfClass:[GroupNode class]]) {
        GroupNode *grpNode = [item representedObject];
        if (![[grpNode title] isEqualToString:@"No Group"]) {
            return true;
        }
    }
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
        newFilter = [[RFTorrentFilter alloc] initWithStatus:[(StatusNode *)node status]];
    } else if ([node isKindOfClass:[GroupNode class]]) {
        newFilter = [[RFTorrentFilter alloc] initwithGroup:[(GroupNode *)node group]];
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
        if ([self delegate]) {
            if ([[self delegate] respondsToSelector:@selector(sourceList:filterDidChange:)]) {
                [[self delegate] sourceList:self filterDidChange:filter];
            }
        }
    }
    
    [newFilter release];
        
    if (removeStatus > 0) {
        [self performSelector:@selector(tryRemoveStatusGroup) withObject:nil afterDelay:1.0];
    }
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{
    NSInteger clickedRow = [sourceList clickedRow];
    id item = nil;
    BaseNode *node = nil;
    if (clickedRow != -1) {
        item = [sourceList itemAtRow:clickedRow];
        node = [item representedObject];
    }
    
    [menu removeAllItems];
    
    if (node) {
    
        bool addgroup = false;
        if ([node isKindOfClass:[GroupNode class]]) {
            addgroup = true;
        } else if ([node isKindOfClass:[CategoryNode class]]) {
            if ([(CategoryNode *)node categoryType] == catGroup) {
                addgroup = true;
            }
        }
        if (addgroup) {
            NSMenuItem *addGroupItem = [[[NSMenuItem alloc] initWithTitle:@"Add Group..." action:@selector(addGroup:) keyEquivalent:@""] autorelease];
            [addGroupItem setTarget:self];
            [menu addItem:addGroupItem];
        }
    
        if ([node isKindOfClass:[GroupNode class]]) {
            if (![[node title] isEqualToString:@"No Group"]) {
                NSMenuItem *delGroupItem = [[[NSMenuItem alloc] initWithTitle:@"Delete" action:@selector(removeGroup:) keyEquivalent:@""] autorelease];
                [delGroupItem setTarget:self];
                [menu addItem:delGroupItem];
                if ([self delegate]) {
                    if ([[self delegate] respondsToSelector:@selector(sourceList:canRemoveGroup:)]) {
                        if ([(GroupNode *)node group]) {
                            [delGroupItem setEnabled:[[self delegate] sourceList:self canRemoveGroup:[(GroupNode *)node group]]];
                        }
                    }
                }
            }
        }
    }
}

@end
