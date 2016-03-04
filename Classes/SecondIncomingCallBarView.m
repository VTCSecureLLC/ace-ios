//
//  SecondIncomingCallBar.m
//  linphone
//
//  Created by Misha Torosyan on 3/3/16.
//
//

#import "SecondIncomingCallBarView.h"

#define kAnimationDuration 0.5f

@interface SecondIncomingCallBarView ()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIButton *messageButton;
@property (weak, nonatomic) IBOutlet UIButton *declineButton;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewBottomConstraint;

@end

@implementation SecondIncomingCallBarView

#pragma mark - Private Methods
- (void)showWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.backgroundViewBottomConstraint.constant = 0;
    self.alpha = 1;
    
    if (animation) {
        [UIView animateWithDuration:kAnimationDuration
                         animations:^{
                             
                             [self layoutIfNeeded];
                         } completion:^(BOOL finished) {
                             
                             if (completion && finished) {
                                 
                                 completion();
                             }
                         }];
    }
    else {
        
        [self layoutIfNeeded];
    }
}

- (void)hideWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.backgroundViewBottomConstraint.constant = -CGRectGetHeight(self.backgroundView.frame);
    
    if (animation) {
        
        [UIView animateWithDuration:kAnimationDuration
                         animations:^{
                             
                             [self layoutIfNeeded];
                         } completion:^(BOOL finished) {
                             
                             self.alpha = 0;
                             if (completion && finished) {
                                 
                                 completion();
                             }
                         }];
    }
    else {
        
        [self layoutIfNeeded];
    }
}


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
