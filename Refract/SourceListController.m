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
#import "ServerNode.h"
#import "RFServerList.h"

@interface SourceListController ()
- (NSUInteger)statusSortIndex:(RFTorrentStatus)status;
- (void)doRemoveGroupNode:(NSTreeNode *)node;
- (NSTreeNode *)findServerTreeNode:(RFServer *)server;
- (NSTreeNode *)findOwningServerNode:(NSTreeNode *)node;
- (NSTreeNode *)findCategoryTreeNode:(CategoryNodeType)type inList:(NSArray *)list;
- (NSTreeNode *)findStatusTreeNode:(RFTorrentStatus)status inList:(NSArray *)list;
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode
        contextInfo:(void *)contextInfo;

- (void)createServerNode:(RFServer *)server;
- (void)initServerNodes;
- (StatusNode *)createStatusNode:(RFTorrentStatus)status;
- (GroupNode *)createGroupNode:(RFTorrentGroup *)group;
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

@synthesize delegate;

- (void)awakeFromNib
{
    NSSortDescriptor *indexsd = [NSSortDescriptor sortDescriptorWithKey:@"sortIndex" ascending:true];
    NSSortDescriptor *titlesd = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:true];
    [treeController setSortDescriptors:[NSArray arrayWithObjects:indexsd, titlesd, nil]];
    
    [self initServerNodes];
    
    initialized = true;
    
    [sourceList setAutosaveExpandedItems:true];
}

- (void)initServerNodes
{
    RFServerList *list = [RFServerList sharedServerList];
    
    for (RFServer *srv in [list servers]) {
        
        manipulatingSourceList = true;
        [self createServerNode:srv];
        manipulatingSourceList = false;
        
        [self updateServer:srv];
    }
    
    [treeController rearrangeObjects];
}

- (void)createServerNode:(RFServer *)server
{
    if (!server) {
        return;
    }
    
    ServerNode *sNode = [[[ServerNode alloc] init] autorelease];
    [sNode setTitle:[server name]];
    [sNode setIsLeaf:false];
    [sNode setServer:server];
    
    NSIndexPath *serverPath = [NSIndexPath indexPathWithIndex:[[treeController arrangedObjects] count]];
    [treeController insertObject:sNode atArrangedObjectIndexPath:serverPath];
    
    CategoryNode *statusNode = [[[CategoryNode alloc] init] autorelease];
    [statusNode setTitle:@"Status"];
    [statusNode setSortIndex:0];
    [statusNode setIsLeaf:false];
    [statusNode setCategoryType:catStatus];
    [treeController insertObject:statusNode atArrangedObjectIndexPath:[serverPath indexPathByAddingIndex:0]];
    
    CategoryNode *groupNode = [[[CategoryNode alloc] init] autorelease];
    [groupNode setTitle:@"Group"];
    [groupNode setSortIndex:1];
    [groupNode setIsLeaf:false];
    [groupNode setCategoryType:catGroup];
    NSIndexPath *groupsPath = [serverPath indexPathByAddingIndex:1];
    [treeController insertObject:groupNode atArrangedObjectIndexPath:groupsPath];
    
    NSUInteger groupIdx = 0;
    GroupNode *noGroup = [[[GroupNode alloc] init] autorelease];
    [noGroup setTitle:@"No Group"];
    [noGroup setIsLeaf:true];
    [noGroup setSortIndex:0];
    [treeController insertObject:noGroup atArrangedObjectIndexPath:[groupsPath indexPathByAddingIndex:groupIdx++]];
    
    for (RFTorrentGroup *grp in [[server groupList] groups]) {
        [treeController insertObject:[self createGroupNode:grp] atArrangedObjectIndexPath:[groupsPath indexPathByAddingIndex:groupIdx++]];
    }
}

- (void)updateServer:(RFServer *)server
{
    if (!server) {
        return;
    }
    
    bool modified = false;
    
    manipulatingSourceList = true;
    
    NSTreeNode *serverNode = [self findServerTreeNode:server];
    
    NSTreeNode *statusCatNode = [self findCategoryTreeNode:catStatus inList:[serverNode childNodes]];
    
    for (NSUInteger stat = stWaiting; stat <= stStopped; stat++) {
        
        bool needsnode = [[server torrentList] containsStatus:stat];
        
        NSTreeNode *statusNode = [self findStatusTreeNode:stat inList:[statusCatNode childNodes]];
        if (needsnode) {
            if (!statusNode) {
                NSIndexPath *statusPath = [[statusCatNode indexPath] indexPathByAddingIndex:[[statusCatNode childNodes] count]];
                [treeController insertObject:[self createStatusNode:stat] atArrangedObjectIndexPath:statusPath];
                modified = true;
            }
        } else {
            if (statusNode) {
                [treeController removeObjectAtArrangedObjectIndexPath:[statusNode indexPath]];
                modified = true;
            }
        }
        
    }
    
    if (modified) {
        [treeController rearrangeObjects];
    }
    
    manipulatingSourceList = false;
}

- (StatusNode *)createStatusNode:(RFTorrentStatus)status
{
    StatusNode *sNode = [[[StatusNode alloc] init] autorelease];
    switch (status) {
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
    [sNode setStatus:status];
    [sNode setSortIndex:[self statusSortIndex:status]];
    return sNode;
}

- (GroupNode *)createGroupNode:(RFTorrentGroup *)group
{
    if (!group) {
        return nil;
    }
    
    GroupNode *newNode = [[[GroupNode alloc] init] autorelease];
    [newNode setTitle:[group name]];
    [newNode setIsLeaf:true];
    [newNode setSortIndex:1];
    [newNode setGroup:group];
    [newNode addObserver:self forKeyPath:@"title" options:0 context:nil];
    return newNode;
}

- (NSTreeNode *)findServerTreeNode:(RFServer *)server
{
    if (!server) {
        return nil;
    }
    
    NSArray *list = [[treeController arrangedObjects] childNodes];
    
    for (NSUInteger i = 0; i < [list count]; i++) {
        NSTreeNode *tNode = [list objectAtIndex:i];
        BaseNode *dNode = [tNode representedObject];
        if ([dNode isKindOfClass:[ServerNode class]]) {
            if ([[(ServerNode *)dNode server] isEqual:server]) {
                return tNode;
            }
        }
    }
    
    return nil;
}

- (NSTreeNode *)findOwningServerNode:(NSTreeNode *)node
{
    if (!node) {
        return nil;
    }
    
    while (node) {
        BaseNode *dataNode = [node representedObject];
        if ([dataNode isKindOfClass:[ServerNode class]]) {
            return node;
        }
        node = [node parentNode];
    }
    
    return nil;
}

- (NSTreeNode *)findCategoryTreeNode:(CategoryNodeType)type inList:(NSArray *)list
{
    if (!list) {
        return nil;
    }
    
    for (NSUInteger i = 0; i < [list count]; i++) {
        NSTreeNode *tNode = [list objectAtIndex:i];
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
    if ([[treeController selectedNodes] count] < 1) {
        return;
    }
    
    NSTreeNode *selectedNode;
    if ([sender isEqual:addGroupButton]) {
        selectedNode = [[treeController selectedNodes] objectAtIndex:0];
    } else {
        selectedNode = [sourceList itemAtRow:[sourceList clickedRow]];
    }
    NSTreeNode *serverNode = [self findOwningServerNode:selectedNode];
    RFServer *server = [(ServerNode *)[serverNode representedObject] server];
    if (!server) {
        return;
    }
    
    NSTreeNode *groupTreeNode = [self findCategoryTreeNode:catGroup inList:[serverNode childNodes]];
    if (!groupTreeNode) {
        return;
    }
    
    NSString *name = @"New Group";
    NSUInteger num = 0;
    while ([[server groupList] groupWithNameExists:name]) {
        name = [NSString stringWithFormat:@"New Group %d", ++num];
    }
    
    NSIndexPath *itemPath = [[groupTreeNode indexPath] indexPathByAddingIndex:[[groupTreeNode childNodes] count]];
    RFTorrentGroup *newGroup = [[server groupList] addGroup:name];
    if (!newGroup) {
        return;
    }
    GroupNode *newNode = [self createGroupNode:newGroup];
    manipulatingSourceList = true;
    [treeController insertObject:newNode atArrangedObjectIndexPath:itemPath];
    [treeController rearrangeObjects];
    manipulatingSourceList = false;
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
    
    NSTreeNode *serverNode = [self findOwningServerNode:item];
    RFServer *server = [(ServerNode *)[serverNode representedObject] server];
    
    
    
    NSArray *torrents = [[[server torrentList] torrents] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"group == %d", [[(GroupNode *)node group] gid]]];

    if ([torrents count] == 0) {
        [self doRemoveGroupNode:item];
        return;
    }
    
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert addButtonWithTitle:@"Cancel"];
    [alert addButtonWithTitle:@"Delete"];
    [alert setMessageText:@"Are you sure you want to delete this group?"];
    [alert setInformativeText:[NSString stringWithFormat:@"%d torrents will be returned to the default group.", [torrents count]]];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    NSDictionary *context = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:item, @"removegroup", nil] forKeys:[NSArray arrayWithObjects:@"group", @"type", nil]];
    
    [alert beginSheetModalForWindow:window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:context];
}

- (void)doRemoveGroupNode:(NSTreeNode *)node
{
    if (!node) {
        return;
    }
    
    if (![[node representedObject] isKindOfClass:[GroupNode class]]) {
        return;
    }
    
    NSTreeNode *serverNode = [self findOwningServerNode:node];
    RFServer *server = [(ServerNode *)[serverNode representedObject] server];
    if (!server) {
        return;
    }
    
    GroupNode *gNode = [node representedObject];
    [gNode removeObserver:self forKeyPath:@"title"];
    [treeController removeObjectAtArrangedObjectIndexPath:[node indexPath]];
    
    [[server torrentList] clearGroup:[gNode group]];
    [[server groupList] removeGroup:[gNode group]];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    NSDictionary *context = (NSDictionary *)contextInfo;
    NSString *type = [context objectForKey:@"type"];
    
    if ([type isEqualToString:@"removegroup"]) {
        if (returnCode == NSAlertSecondButtonReturn) {
            [self doRemoveGroupNode:[context objectForKey:@"group"]];
        }
    }
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    if ([control isEqual:sourceList]) {
        
        if ([[fieldEditor string] length] == 0) {
            return false;
        }
        
        if ([[fieldEditor string] isEqualToString:@"No Group"]) {
            return false;
        }
        
        NSInteger row = [sourceList editedRow];
        
        id item = [sourceList itemAtRow:row];
        BaseNode *node = [item representedObject];
        
        if ([node isKindOfClass:[GroupNode class]]) {
            
            NSTreeNode *serverNode = [self findOwningServerNode:item];
            RFServer *server = [(ServerNode *)[serverNode representedObject] server];
            
            if (server) {
                RFTorrentGroup *existing = [[server groupList] groupWithName:[fieldEditor string]];
                if (existing && ![existing isEqual:[(GroupNode *)node group]]) {
                    return false;
                }
                return true;
            }
            
        }
    }
    return true;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isKindOfClass:[GroupNode class]]) {
        
        [treeController rearrangeObjects];
        
        [[(GroupNode *)object group] setName:[(GroupNode *)object title]];
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
        if ([grpNode group]) {
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
    
    NSArray *selection = [treeController selectedNodes];
    if ([selection count] == 0) {
        [treeController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:0]];
        return;
    }
    NSTreeNode *node = [selection objectAtIndex:0];
    BaseNode *dataNode = [node representedObject];
    
    RFTorrentFilter *newFilter;
    
    if ([dataNode isKindOfClass:[StatusNode class]]) {
        newFilter = [[[RFTorrentFilter alloc] initWithStatus:[(StatusNode *)dataNode status]] autorelease];
    } else if ([dataNode isKindOfClass:[GroupNode class]]) {
        newFilter = [[[RFTorrentFilter alloc] initwithGroup:[(GroupNode *)dataNode group]] autorelease];
    } else if (![dataNode isKindOfClass:[CategoryNode class]]) {
        if ([dataNode isKindOfClass:[ServerNode class]]) {
            newFilter = [[[RFTorrentFilter alloc] initWithType:filtNone] autorelease];
        }
    }
    
    if (!newFilter) {
        return;
    }
    
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(sourceList:server:filterDidChange:)]) {
            RFServer *server = [(ServerNode *)[[self findOwningServerNode:node] representedObject] server];
            [[self delegate] sourceList:self server:server filterDidChange:newFilter];
        }
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
            NSMenuItem *addGroupItem = [[[NSMenuItem alloc] initWithTitle:@"Add Group" action:@selector(addGroup:) keyEquivalent:@""] autorelease];
            [addGroupItem setTarget:self];
            [menu addItem:addGroupItem];
        }
    
        if ([node isKindOfClass:[GroupNode class]]) {
            if ([(GroupNode *)node group]) {
                NSMenuItem *delGroupItem = [[[NSMenuItem alloc] initWithTitle:@"Delete" action:@selector(removeGroup:) keyEquivalent:@""] autorelease];
                [delGroupItem setTarget:self];
                [menu addItem:delGroupItem];
                [delGroupItem setEnabled:true];
            }
        }
    }
}

- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object
{
//    if ([object isEqualToString:@"Status"]) {
//        return [self findCategoryTreeNode:catStatus];
//    } else if ([object isEqualToString:@"Group"]) {
//        return [self findCategoryTreeNode:catGroup];
//    }
    
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item
{
//    if ([[item representedObject] isKindOfClass:[CategoryNode class]]) {
//        if ([(CategoryNode *)[item representedObject] categoryType] == catStatus) {
//            return @"Status";
//        } else if ([(CategoryNode *)[item representedObject] categoryType] == catGroup) {
//            return @"Group";
//        }
//    }
    
    return nil;
}

@end
