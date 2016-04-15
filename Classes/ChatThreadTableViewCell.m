
//
//  ChatThreadTableViewCell.m
//  linphone
//
//  Created by Misha Torosyan on 4/12/16.
//
//

#import "ChatThreadTableViewCell.h"
#import "LinphoneManager.h"

@interface ChatThreadTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastMessageLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *initialsLabel;
@property (weak, nonatomic) IBOutlet UIView *imageAndInitialsContainerView;
@property (weak, nonatomic) IBOutlet UIView *unreadMessagesCountIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *unreadMessagesCountLabel;

@property (assign, nonatomic) LinphoneChatRoom *chatRoom;


@end

@implementation ChatThreadTableViewCell

#pragma mark - Lifecycle Methods
- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    [self setupCell];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Private Methods
- (void)setupCell {
    
    self.imageAndInitialsContainerView.layer.cornerRadius = CGRectGetHeight(self.profileImageView.frame)/2;
    self.imageAndInitialsContainerView.layer.borderColor = [UIColor grayColor].CGColor;
    self.imageAndInitialsContainerView.layer.borderWidth = 1.5f;
}


- (void)fillWithChatRoom:(LinphoneChatRoom *)chatRoom {
    
    _chatRoom = chatRoom;
    [self update];
}


- (void)update {
    NSString *displayName = nil;
    UIImage *image = nil;
    if (self.chatRoom == nil) {
        LOGW(@"Cannot update chat cell: null chat");
        return;
    }
    const LinphoneAddress *linphoneAddress = linphone_chat_room_get_peer_address(self.chatRoom);
    
    if (linphoneAddress == NULL)
        return;
    char *tmp = linphone_address_as_string_uri_only(linphoneAddress);
    NSString *normalizedSipAddress = [NSString stringWithUTF8String:tmp];
    ms_free(tmp);
    
    ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:normalizedSipAddress];
    if (contact != nil) {
        displayName = [FastAddressBook getContactDisplayName:contact];
        image = [FastAddressBook getContactImage:contact thumbnail:true];
    }
    
    // Display name
    if (displayName == nil) {
        const char *username = linphone_address_get_username(linphoneAddress);
        char *address = linphone_address_as_string(linphoneAddress);
        displayName = [NSString stringWithUTF8String:username ?: address];
        ms_free(address);
    }
    
    [self updateNameAndInitialsWithDisplayName:displayName];
    [self updateProfileImage:image];
    
    LinphoneChatMessage *last_message = linphone_chat_room_get_user_data(self.chatRoom);
    
    if (last_message) {
        
        const char *text = linphone_chat_message_get_text(last_message);
        const char *url = linphone_chat_message_get_external_body_url(last_message);
        const LinphoneContent *last_content = linphone_chat_message_get_file_transfer_information(last_message);
        // Message
        NSString *lastMessage;
        if (url || last_content) {
            lastMessage = @"🗻";
        } else if (text) {
            NSString *message = [NSString stringWithUTF8String:text];
            // shorten long messages
            if ([message length] > 50) {
                message = [[message substringToIndex:50] stringByAppendingString:@"[...]"];
            }
            
            lastMessage = [message stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        }
        
        int count = linphone_chat_room_get_unread_messages_count(self.chatRoom);
        [self updateLastMessageWithMessage:lastMessage withUnreadMessagesCount:count];
        
        time_t chattime = linphone_chat_message_get_time(last_message);
        NSDate *messageDate;
        if (chattime > 0) {
            messageDate = [NSDate dateWithTimeIntervalSince1970:chattime];
        }
        [self updateMessageDate:messageDate];
        
    } else {
        
        [self updateLastMessageWithMessage:nil withUnreadMessagesCount:0];
    }
}

- (void)updateNameAndInitialsWithDisplayName:(NSString *)displayName {
    
    self.nameLabel.text = displayName;
    NSArray *separatedDisplayName = [displayName componentsSeparatedByString:@" "];
    
    if (separatedDisplayName.count > 0) {
        
        NSMutableString *initials = [NSMutableString stringWithCapacity:separatedDisplayName.count];
        for (int i = 0; i < separatedDisplayName.count && i < 2; ++i) {
            
            NSString *separatedString = separatedDisplayName[i];
            if (separatedString.length > 0) {
                [initials appendFormat:@"%c", [separatedString characterAtIndex:0]];
            }
        }
        self.initialsLabel.hidden = NO;
        self.initialsLabel.text = initials;
    }
    else {
        self.initialsLabel.hidden = YES;
    }
}

- (void)updateLastMessageWithMessage:(NSString *)lastMessage withUnreadMessagesCount:(NSUInteger)unreadMessagesCount {
    
    self.lastMessageLabel.hidden = !(BOOL)lastMessage;
    
    if (lastMessage) {
        
        if (unreadMessagesCount > 0) {
            
            self.lastMessageLabel.textColor = [UIColor colorWithRed:0.854 green:0.2743 blue:0.0719 alpha:1.0];
            self.unreadMessagesCountIndicatorView.hidden = NO;
            self.unreadMessagesCountLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)unreadMessagesCount];
        }
        else {
            
            self.lastMessageLabel.textColor = [UIColor lightGrayColor];
            self.unreadMessagesCountIndicatorView.hidden = YES;
        }
        
        self.lastMessageLabel.text = lastMessage;
    }
}


- (void)updateProfileImage:(UIImage *)image {
    
    self.profileImageView.image = image;
    self.initialsLabel.hidden = (BOOL)image;
}


- (void)updateMessageDate:(NSDate *)date {
    
    self.messageDateLabel.hidden = !(BOOL)date;
    
    if (date) {
        
        NSDate *currentDate = [NSDate date];
        NSCalendar *gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *components = [gregorianCalendar components:NSCalendarUnitDay
                                                            fromDate:date
                                                              toDate:currentDate
                                                             options:NSCalendarWrapComponents];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        if (components.day == 0) {
//            time with 12 format
            dateFormatter.AMSymbol = @"am";
            dateFormatter.PMSymbol = @"pm";
            dateFormatter.dateFormat = @"hh:mma";
        }
        else if (components.day > 0 && components.day < 8) {
//            day of week
            dateFormatter.dateFormat = @"EEE.";
        }
        else {
//            Day and mont
            dateFormatter.dateFormat =  @"M/d";
        }
        
        NSString *messageDate = [dateFormatter stringFromDate:date];
        self.messageDateLabel.hidden = !messageDate;
        self.messageDateLabel.text = messageDate;
    }
}

@end
