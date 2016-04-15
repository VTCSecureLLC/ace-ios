//
//  NewChatHeaderView.h
//  linphone
//
//  Created by Misha Torosyan on 4/15/16.
//
//

#import <UIKit/UIKit.h>

typedef void(^HeaderActionHandler)(void);

@interface NewChatHeaderView : UITableViewHeaderFooterView

@property (nonatomic, copy) HeaderActionHandler headerActionBlock;

- (void)setNewChatName:(NSString *)chatName;

@end
