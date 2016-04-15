//
//  NewChatHeaderView.m
//  linphone
//
//  Created by Misha Torosyan on 4/15/16.
//
//

#import "NewChatHeaderView.h"

@interface NewChatHeaderView ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation NewChatHeaderView

#pragma mark - Instance Methods
- (void)setNewChatName:(NSString *)chatName {
    
    _titleLabel.text = [NSString stringWithFormat:@"Start texting with %@", chatName];
}

- (IBAction)headerButtonAction:(UIButton *)sender {
    
    if (self.headerActionBlock) {
        self.headerActionBlock();
    }
}

@end
