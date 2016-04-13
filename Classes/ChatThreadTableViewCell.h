//
//  ChatThreadTableViewCell.h
//  linphone
//
//  Created by Misha Torosyan on 4/12/16.
//
//

#import <UIKit/UIKit.h>
#include "linphone/linphonecore.h"

@interface ChatThreadTableViewCell : UITableViewCell

- (void)fillWithChatRoom:(LinphoneChatRoom *)chatRoom;

@end
