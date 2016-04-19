/* ChatTableViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "ChatTableViewController.h"
#import "UIChatCell.h"
#import "FileTransferDelegate.h"
#import "linphone/linphonecore.h"
#import "PhoneMainView.h"
#import "UACellBackgroundView.h"
#import "UILinphone.h"
#import "Utils.h"
#import "ChatThreadTableViewCell.h"
#import "NewChatHeaderView.h"

static NSString * const chatThreadCellIdentifier    = @"ChatThreadCell";
static NSString * const newChatHeaderViewIdentifier = @"NewChatHeaderView";


@interface ChatTableViewController ()

@property (nonatomic, assign) MSList *data;
@property (nonatomic, assign) MSList *filteredData;

@end

@implementation ChatTableViewController

#pragma mark - Lifecycle Functions
- (instancetype)init {
	self = super.init;
	if (self) {
		self.data = nil;
	}
	return self;
}

- (void)dealloc {
	if (self.data != nil) {
		ms_list_free_with_data(self.data, chatTable_free_chatrooms);
	}
}


#pragma mark - ViewController Functions
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupController];
}

- (void)viewWillAppear:(BOOL)animated {
    
	[super viewWillAppear:animated];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor whiteColor]];
	self.tableView.accessibilityIdentifier = @"Chat list";
    self.data = nil;
	[self loadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor blackColor]];
}



#pragma mark - Instance Methods
static int sorted_history_comparison(LinphoneChatRoom *to_insert, LinphoneChatRoom *elem) {
	LinphoneChatMessage *last_new_message = linphone_chat_room_get_user_data(to_insert);
	LinphoneChatMessage *last_elem_message = linphone_chat_room_get_user_data(elem);

	if (last_new_message && last_elem_message) {
		time_t new = linphone_chat_message_get_time(last_new_message);
		time_t old = linphone_chat_message_get_time(last_elem_message);
		if (new < old)
			return 1;
		else if (new > old)
			return -1;
	}
	return 0;
}

- (MSList *)sortChatRooms {
	MSList *sorted = nil;
	const MSList *unsorted = linphone_core_get_chat_rooms([LinphoneManager getLc]);
	const MSList *iter = unsorted;

	while (iter) {
		// store last message in user data
		LinphoneChatRoom *chat_room = iter->data;
		MSList *history = linphone_chat_room_get_history(iter->data, 1);
		LinphoneChatMessage *last_msg = NULL;
		if (history) {
			last_msg = linphone_chat_message_ref(history->data);
			ms_list_free(history);
		}
		linphone_chat_room_set_user_data(chat_room, last_msg);
		sorted = ms_list_insert_sorted(sorted, chat_room, (MSCompareFunc)sorted_history_comparison);
		iter = iter->next;
	}
	return sorted;
}

- (MSList *)filterChatRoomsWithSearchText:(NSString *)searchText {
    
    if (!searchText) {
        return nil;
    }
    
    MSList *filtered = nil;
    const MSList *current = self.data;
    const MSList *iter = current;
    
    while (iter) {
        // store last message in user data
        LinphoneChatRoom *chat_room = iter->data;
        const LinphoneAddress *linphoneAddress = linphone_chat_room_get_peer_address(chat_room);
        
        if (linphoneAddress != NULL) {
            char *tmp = linphone_address_as_string_uri_only(linphoneAddress);
            NSString *normalizedSipAddress = [NSString stringWithUTF8String:tmp];
            ms_free(tmp);
            
            NSString *displayName = nil;
            ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:normalizedSipAddress];
            char *address = linphone_address_as_string(linphoneAddress);
            NSString *trimmerdAddress = [[NSString stringWithUTF8String:address] substringFromIndex:@"sip:".length];
            ms_free(address);
            
            if (contact != nil) {
                displayName = [NSString stringWithFormat:@"%@ %@", [FastAddressBook getContactDisplayName:contact], trimmerdAddress];
            }
            
            if (displayName == nil) {
                const char *username = linphone_address_get_username(linphoneAddress);
                displayName = [NSString stringWithFormat:@"%s %@", username, trimmerdAddress];
            }
            
            if ([[displayName lowercaseString] rangeOfString:[searchText lowercaseString]].location != NSNotFound) {
                filtered = ms_list_insert(filtered, filtered, chat_room);
            }
        }
        
        iter = iter->next;
    }
    return filtered;
}

static void chatTable_free_chatrooms(void *data) {
	LinphoneChatMessage *lastMsg = linphone_chat_room_get_user_data(data);
	if (lastMsg) {
		linphone_chat_message_unref(lastMsg);
		linphone_chat_room_set_user_data(data, NULL);
	}
}

- (void)loadData {
	if (self.data != NULL) {
		ms_list_free_with_data(self.data, chatTable_free_chatrooms);
	}
	self.data = [self sortChatRooms];
	[[self tableView] reloadData];
}

- (void)setupController {
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([ChatThreadTableViewCell class]) bundle:nil]
         forCellReuseIdentifier:chatThreadCellIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([NewChatHeaderView class]) bundle:nil] forHeaderFooterViewReuseIdentifier:newChatHeaderViewIdentifier];
    
    [self.searchDisplayController.searchResultsTableView setBackgroundColor:[UIColor colorWithRed:0.1843 green:0.1961 blue:0.1961 alpha:1.0]];
    [self.searchDisplayController.searchResultsTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self changeSearchBarDesign];
}

- (void)startChatRoomWithAddress:(NSString *)address {
    
    LinphoneChatRoom *room = linphone_core_get_chat_room_from_uri([LinphoneManager getLc], [address UTF8String]);
    if (room != nil) {
        ChatRoomViewController *controller = DYNAMIC_CAST(
                                                          [[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE],
                                                          ChatRoomViewController);
        if (controller != nil) {
            [controller setChatRoom:room];
        }
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Invalid address", nil)
                                                        message:@"Please specify the entire SIP address for the chat"
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - Private Methods
- (void)changeSearchBarDesign {
    
    UISearchBar *searchBar = self.searchDisplayController.searchBar;
    [searchBar setImage:[UIImage imageNamed:@"search_icon"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    
    NSArray *subviews;
    if (searchBar.subviews.count > 1) {
        subviews = searchBar.subviews;
    }
    else if (searchBar.subviews.count == 1){
        subviews = [searchBar.subviews firstObject].subviews;
    }
    
    for (UIView *subview in subviews) {
        if ([subview isKindOfClass:[UITextField class]]) {
            UITextField *searchField = (UITextField *)subview;
            searchField.backgroundColor = [UIColor colorWithRed:0.4157 green:0.4196 blue:0.4196 alpha:1.0];
            searchField.textColor = [UIColor colorWithRed:0.102 green:0.1098 blue:0.1137 alpha:1.0];
            [(UILabel *)[searchField valueForKey:@"_placeholderLabel"] setTextColor:[UIColor colorWithRed:0.102 green:0.1098 blue:0.1137 alpha:1.0]];
            searchField.borderStyle = UITextBorderStyleNone;
            searchField.layer.cornerRadius = 4.f;
            break;
        }
    }
}
#pragma mark - UITableViewDataSource Functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return ms_list_size(self.filteredData);
    }
    else {
        return ms_list_size(self.data);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    ChatThreadTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:chatThreadCellIdentifier];
    LinphoneChatRoom *chatRoom;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        
        chatRoom = (LinphoneChatRoom *)ms_list_nth_data(self.filteredData, (int)[indexPath row]);
        [cell fillWithChatRoom:chatRoom];
    }
    else {
        
        chatRoom = (LinphoneChatRoom *)ms_list_nth_data(self.data, (int)[indexPath row]);
        [cell fillWithChatRoom:chatRoom];
    }

	return cell;
}


#pragma mark - UITableViewDelegate Functions
- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    if (tableView == self.searchDisplayController.searchResultsTableView && ms_list_size(self.filteredData) == 0) {
        
        NewChatHeaderView *headerView = (NewChatHeaderView *)[self.tableView dequeueReusableHeaderFooterViewWithIdentifier:newChatHeaderViewIdentifier];
        UISearchBar *searchBar = self.searchDisplayController.searchBar;
        [headerView setNewChatName:searchBar.text];
        
        __weak ChatTableViewController *weakSelf = self;
        headerView.headerActionBlock = ^{
            
            [weakSelf startChatRoomWithAddress:searchBar.text];
            self.searchDisplayController.active = NO;
            [weakSelf.tableView reloadData];
        };
        
        return headerView;
    }
    else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    if (tableView == self.searchDisplayController.searchResultsTableView && ms_list_size(self.filteredData) == 0) {
        return 44;
    }
    else {
        return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    LinphoneChatRoom *chatRoom;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        
        chatRoom = (LinphoneChatRoom *)ms_list_nth_data(self.filteredData, (int)[indexPath row]);
    }
    else {
        
        chatRoom = (LinphoneChatRoom *)ms_list_nth_data(self.data, (int)[indexPath row]);
    }

	// Go to ChatRoom view
	ChatRoomViewController *controller = DYNAMIC_CAST(
		[[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE],
		ChatRoomViewController);
	if (controller != nil) {
		[controller setChatRoom:chatRoom];
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView
		   editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	// Detemine if it's in editing mode
	if (self.editing) {
		return UITableViewCellEditingStyleDelete;
	}
	return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[self.tableView beginUpdates];

        LinphoneChatRoom *chatRoom;
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            
            chatRoom = (LinphoneChatRoom *)ms_list_nth_data(self.filteredData, (int)[indexPath row]);
        }
        else {
            
            chatRoom = (LinphoneChatRoom *)ms_list_nth_data(self.data, (int)[indexPath row]);
        }

        
		LinphoneChatMessage *last_msg = linphone_chat_room_get_user_data(chatRoom);
		if (last_msg) {
			linphone_chat_message_unref(last_msg);
			linphone_chat_room_set_user_data(chatRoom, NULL);
		}

		FileTransferDelegate *ftdToDelete = nil;
		for (FileTransferDelegate *ftd in [[LinphoneManager instance] fileTransferDelegates]) {
			if (linphone_chat_message_get_chat_room(ftd.message) == chatRoom) {
				ftdToDelete = ftd;
				break;
			}
		}
        [ftdToDelete cancel];
        
        linphone_core_delete_chat_room(linphone_chat_room_get_lc(chatRoom), chatRoom);
        self.data = ms_list_remove(self.data, chatRoom);
        
        // will force a call to [self loadData]
        [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneTextReceived object:self];
        
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                              withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}


#pragma mark - 

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    
    [self filterContentForSearchText:searchString
                               scope:[[self.searchDisplayController.searchBar scopeButtonTitles]
                                      objectAtIndex:[self.searchDisplayController.searchBar
                                                     selectedScopeButtonIndex]]];
    
    return YES;
}


#pragma mark - Search

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    
    self.filteredData = [self filterChatRoomsWithSearchText:searchText];
}
@end
