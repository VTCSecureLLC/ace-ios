//
//  InCallNewCallView.m
//  linphone
//
//  Created by Misha Torosyan on 3/3/16.
//
//

#import "InCallNewCallView.h"

@interface InCallNewCallView ()

@property (weak, nonatomic) IBOutlet UIButton *messageButton;
@property (weak, nonatomic) IBOutlet UIButton *declineButton;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;


@end

@implementation InCallNewCallView

#pragma mark - Action Methods

- (IBAction)messageButtonAction:(UIButton *)sender {
    
    __weak UIButton *weakSender = sender;
    if (self.messageButtonBlock) {
        self.messageButtonBlock(weakSender);
    }
}

- (IBAction)declineButtonAction:(UIButton *)sender {
    
    __weak UIButton *weakSender = sender;
    if (self.declineButtonBlock) {
        self.declineButtonBlock(weakSender);
    }
}

- (IBAction)acceptButtonAction:(UIButton *)sender {
    
    __weak UIButton *weakSender = sender;
    if (self.acceptButtonBlock) {
        self.acceptButtonBlock(weakSender);
    }
}
@end
