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
#import "StateNode.h"
#import "RFServerList.h"

@interface SourceListController ()
- (void)doRemoveGroupNode:(NSTreeNode *)node;
- (NSTreeNode *)findServerTreeNode:(RFServer *)server;
- (NSTreeNode *)findOwningServerNode:(NSTreeNode *)node;
- (NSTreeNode *)findCategoryTreeNode:(CategoryNodeType)type inList:(NSArray *)list;
- (NSTreeNode *)findStatusTreeNode:(RFTorrentStatus)status inList:(NSArray *)list;
- (NSTreeNode *)findStateTreeNode:(RFTorrentState)state inList:(NSArray *)list;
- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode
        contextInfo:(void *)contextInfo;

- (void)createServerNode:(RFServer *)server;
- (void)initServerNodes;
- (StatusNode *)createStatusNode:(RFTorrentStatus)status;
- (StateNode *)createStateNode:(RFTorrentState)state;
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
    
    [[RFServerList sharedServerList] addObserver:self forKeyPath:@"servers" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:NULL];
    
    [self initServerNodes];
    
    initialized = true;
    
    [sourceList setAutosaveExpandedItems:true];
}

- (void)initServerNodes
{
    bool hasNode = false;
    
    RFServerList *list = [RFServerList sharedServerList];
    
    for (RFServer *srv in [list servers]) {
        
        if ([srv enabled]) {
            [self createServerNode:srv];
            
            [self updateServer:srv];
            hasNode = true;
        }
        
        [srv addObserver:self forKeyPath:@"enabled" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:NULL];
    }
    
    if (hasNode) {
        [treeController rearrangeObjects];
    }
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
    
    NSTreeNode *serverNode = [self findServerTreeNode:server];
    [sourceList expandItem:serverNode expandChildren:true];
}

- (void)updateServer:(RFServer *)server
{
    if (!server) {
        return;
    }
    
    bool modified = false;
    
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
    
    for (NSUInteger state = stateComplete; state <= stateIncomplete; state++) {
        bool needsnode;
        
        if (state == stateComplete) {
            needsnode = [[server torrentList] hasComplete];
        } else if (state == stateIncomplete) {
            needsnode = [[server torrentList] hasIncomplete];
        }
        
        NSTreeNode *stateNode = [self findStateTreeNode:state inList:[statusCatNode childNodes]];
        if (needsnode) {
            if (!stateNode) {
                NSIndexPath *statePath = [[statusCatNode indexPath] indexPathByAddingIndex:[[statusCatNode childNodes] count]];
                [treeController insertObject:[self createStateNode:state] atArrangedObjectIndexPath:statePath];
                modified = true;
            }
        } else {
            if (stateNode) {
                [treeController removeObjectAtArrangedObjectIndexPath:[stateNode indexPath]];
                modified = true;
            }
        }
    }
    
    if (modified) {
        [treeController rearrangeObjects];
    }
}

- (StatusNode *)createStatusNode:(RFTorrentStatus)status
{
    StatusNode *sNode = [[[StatusNode alloc] init] autorelease];
    switch (status) {
        case stDownloading:
            [sNode setTitle:@"Downloading"];
            [sNode setSortIndex:1];
            break;
        case stSeeding:
            [sNode setTitle:@"Seeding"];
            [sNode setSortIndex:2];
            break;
        case stChecking:
            [sNode setTitle:@"Checking"];
            [sNode setSortIndex:3];
            break;
        case stWaiting:
            [sNode setTitle:@"Waiting"];
            [sNode setSortIndex:4];
            break;
        case stStopped:
            [sNode setTitle:@"Stopped"];
            [sNode setSortIndex:5];
            break;
    }
    [sNode setIsLeaf:true];
    [sNode setStatus:status];
    return sNode;
}

- (StateNode *)createStateNode:(RFTorrentState)state
{
    StateNode *sNode = [[[StateNode alloc] init] autorelease];
    switch (state) {
        case stateComplete:
            [sNode setTitle:@"Complete"];
            [sNode setSortIndex:10];
            break;
            
        case stateIncomplete:
            [sNode setTitle:@"Incomplete"];
            [sNode setSortIndex:11];
            break;
    }
    [sNode setIsLeaf:true];
    [sNode setState:state];
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

- (NSTreeNode *)findStateTreeNode:(RFTorrentState)state inList:(NSArray *)list
{
    if (!list) {
        return nil;
    }
    
    for (NSUInteger i = 0; i < [list count]; i++) {
        NSTreeNode *tNode = [list objectAtIndex:i];
        BaseNode *dNode = [tNode representedObject];
        if ([dNode isKindOfClass:[StateNode class]]) {
            if ([(StateNode *)dNode state] == state) {
                return tNode;
            }
        }
    }
    
    return nil;
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
    [treeController insertObject:newNode atArrangedObjectIndexPath:itemPath];
    [treeController rearrangeObjects];
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
    if ([object isEqual:[RFServerList sharedServerList]]) {
        if ([keyPath isEqualToString:@"servers"]) {
            NSKeyValueChange changeKind = [[change objectForKey:NSKeyValueChangeKindKey] intValue];
            if (changeKind == NSKeyValueChangeRemoval || changeKind == NSKeyValueChangeReplacement) {
                NSArray *removedList = [change objectForKey:NSKeyValueChangeOldKey];
                if (removedList) {
                    for (RFServer *oldServer in removedList) {
                        NSTreeNode *oldServerNode = [self findServerTreeNode:oldServer];
                        if (oldServerNode) {
                            [treeController removeObjectAtArrangedObjectIndexPath:[oldServerNode indexPath]];
                        }
                        [oldServer removeObserver:self forKeyPath:@"enabled"];
                    }
                }
            }
            if (changeKind == NSKeyValueChangeInsertion || changeKind == NSKeyValueChangeReplacement) {
                NSArray *addedList = [change objectForKey:NSKeyValueChangeNewKey];
                if (addedList) {
                    for (RFServer *newServer in addedList) {
                        [self createServerNode:newServer];
                        
                        [self updateServer:newServer];
                        [newServer addObserver:self forKeyPath:@"enabled" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:NULL];
                    }
                    [treeController rearrangeObjects];
                }
            }
        }
    } else if ([object isKindOfClass:[RFServer class]]) {
        if ([keyPath isEqualToString:@"enabled"]) {
            if ([(RFServer *)object enabled]) {
                [self createServerNode:object];
                
                [self updateServer:object];
            } else {
                NSTreeNode *oldServerNode = [self findServerTreeNode:object];
                if (oldServerNode) {
                    [treeController removeObjectAtArrangedObjectIndexPath:[oldServerNode indexPath]];
                }
            }
        }
    } else if ([object isKindOfClass:[GroupNode class]]) {
        
        [treeController rearrangeObjects];
        
        [[(GroupNode *)object group] setName:[(GroupNode *)object title]];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    if ([[item representedObject] isKindOfClass:[CategoryNode class]]) {
        return YES;
    }
    if ([[item representedObject] isKindOfClass:[ServerNode class]]) {
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

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item
{
    if ([[item representedObject] isKindOfClass:[ServerNode class]]) {
        return YES;
    }
    return NO;
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
    NSArray *selection = [treeController selectedNodes];
    if ([selection count] == 0) {
        [treeController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:0]];
        selection = [treeController selectedNodes];
    }
    
    RFTorrentFilter *newFilter = nil;
    NSTreeNode *node = nil;
    
    if ([selection count] > 0) {
        node = [selection objectAtIndex:0];
        BaseNode *dataNode = [node representedObject];
        if ([dataNode isKindOfClass:[StatusNode class]]) {
            newFilter = [[[RFTorrentFilter alloc] initWithStatus:[(StatusNode *)dataNode status]] autorelease];
        } else if ([dataNode isKindOfClass:[StateNode class]]) {
            newFilter = [[[RFTorrentFilter alloc] initWithState:[(StateNode *)dataNode state]] autorelease];
        } else if ([dataNode isKindOfClass:[GroupNode class]]) {
            newFilter = [[[RFTorrentFilter alloc] initwithGroup:[(GroupNode *)dataNode group]] autorelease];
        } else if (![dataNode isKindOfClass:[CategoryNode class]]) {
            if ([dataNode isKindOfClass:[ServerNode class]]) {
                newFilter = [[[RFTorrentFilter alloc] initWithType:filtNone] autorelease];
            }
        }
    }
    
    if ([self delegate]) {
        if ([[self delegate] respondsToSelector:@selector(sourceList:server:filterDidChange:)]) {
            RFServer *server = nil;
            if (node) {
                server = [(ServerNode *)[[self findOwningServerNode:node] representedObject] server];
            }
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
    if ([object isKindOfClass:[NSNumber class]]) {
        NSArray *list = [[treeController arrangedObjects] childNodes];
        
        for (NSUInteger i = 0; i < [list count]; i++) {
            NSTreeNode *tNode = [list objectAtIndex:i];
            BaseNode *dNode = [tNode representedObject];
            if ([dNode isKindOfClass:[ServerNode class]]) {
                if ([[(ServerNode *)dNode server] sid] == [(NSNumber *)object intValue]) {
                    return tNode;
                }
            }
        }
    }
    
    return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item
{
    if ([[item representedObject] isKindOfClass:[ServerNode class]]) {
        return [NSNumber numberWithInt:[[(ServerNode *)[item representedObject] server] sid]];
    }
    
    return nil;
}

@end
