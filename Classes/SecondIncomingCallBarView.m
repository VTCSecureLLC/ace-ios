//
//  SecondIncomingCallBar.m
//  linphone
//
//  Created by Ruben Semerjyan on 3/3/16.
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

- (instancetype)initWithCoder:(NSCoder *)coder {
    
    self = [super initWithCoder:coder];
    if (self) {
        [self hideWithAnimation:NO completion:nil];
    }
    
    return self;
}


#pragma mark - Private Methods
- (void)showWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.alpha = 1;
    self.viewState = VS_Animating;
    NSTimeInterval duration = animation ? kAnimationDuration : 0;

    if (animation) {
        [UIView animateWithDuration:duration
                         animations:^{
                             self.backgroundViewBottomConstraint.constant = 0;
                             [self layoutIfNeeded];
                             
                         } completion:^(BOOL finished) {
                             
                             self.viewState = VS_Opened;
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
    
    self.viewState = VS_Animating;
    NSTimeInterval duration = animation ? kAnimationDuration : 0;
    
    if (animation) {
        [UIView animateWithDuration:duration
                         animations:^{
                             self.backgroundViewBottomConstraint.constant = -CGRectGetHeight(self.backgroundView.frame);
                             [self layoutIfNeeded];
                             
                         } completion:^(BOOL finished) {
                             
                             self.alpha = 0;
                             self.viewState = VS_Closed;
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
    
    if (self.messageButtonBlock) {
        self.messageButtonBlock(_linphoneCall);
    }
}

- (IBAction)declineButtonAction:(UIButton *)sender {
    
    if (self.declineButtonBlock) {
        self.declineButtonBlock(_linphoneCall);
    }
}

- (IBAction)acceptButtonAction:(UIButton *)sender {
    
    if (self.acceptButtonBlock) {
        self.acceptButtonBlock(_linphoneCall);
    }
}

@end
