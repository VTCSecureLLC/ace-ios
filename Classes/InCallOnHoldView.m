//
//  InCallOnHoldView.m
//  linphone
//
//  Created by Misha Torosyan on 3/3/16.
//
//

#import "InCallOnHoldView.h"

#define kAnimationDuration 0.5f


@interface InCallOnHoldView ()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewLeadingConstraint;

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *callStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *holdTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *timerLabel;

@property (nonatomic, assign) LinphoneCall *call;

@end

@implementation InCallOnHoldView

#pragma mark - Private Methods

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    
    self.profileImageView.layer.cornerRadius = CGRectGetHeight(self.profileImageView.frame)/2;
    self.profileImageView.layer.borderWidth = 1.f;
    self.profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
    
}

//Filles notification data with LinphoneCall model
- (void)fillWithCallModel:(LinphoneCall *)linphoneCall {
    //TODO: Fill with passed method's param
    
    self.call = linphoneCall;
}

#pragma mark - Action Methods

- (IBAction)holdViewAction:(UIButton *)sender {
    
    if (self.holdViewActionBlock) {
        self.holdViewActionBlock(self.call);
    }
}

#pragma mark - Animations
//Showes view
- (void)showWithAnimation:(BOOL)animation
                direction:(AnimationDirection)direction
               completion:(void(^)())completion{
    
    self.viewState = VS_Animating;
    NSTimeInterval duration = animation ? kAnimationDuration : 0;
    switch (direction) {
        case AnimationDirectionRight: {
            
            self.backgroundViewLeadingConstraint.constant = -CGRectGetWidth(self.frame);
            self.alpha = 1;
            [UIView animateWithDuration:duration
                             animations:^{
                                 
                                 self.backgroundViewLeadingConstraint.constant = 0;
                                 [self layoutIfNeeded];
                             } completion:^(BOOL finished) {
                                 self.viewState = VS_Opened;
                                 if (completion && finished) {
                                     completion();
                                 }
                             }];
            break;
        }
        case AnimationDirectionLeft: {
            
            self.backgroundViewLeadingConstraint.constant = CGRectGetWidth(self.frame);
            self.alpha = 1;
            [UIView animateWithDuration:duration
                             animations:^{
                                 
                                 self.backgroundViewLeadingConstraint.constant = 0;
                                 [self layoutIfNeeded];
                             } completion:^(BOOL finished) {
                                 self.viewState = VS_Opened;
                                 if (completion && finished) {
                                     completion();
                                 }
                             }];
            break;
        }
    }
    
}

//Hides view
- (void)hideWithAnimation:(BOOL)animation
                direction:(AnimationDirection)direction
               completion:(void(^)())completion{
    
    self.viewState = VS_Animating;
    NSTimeInterval duration = animation ? kAnimationDuration : 0;
    
    switch (direction) {
        case AnimationDirectionRight: {
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 
                                 self.backgroundViewLeadingConstraint.constant = CGRectGetWidth(self.frame);
                                 [self layoutIfNeeded];
                             } completion:^(BOOL finished) {
                                 self.alpha = 0;
                                 self.viewState = VS_Closed;
                                 if (completion && finished) {
                                     completion();
                                 }
                             }];
            break;
        }
        case AnimationDirectionLeft: {
            
            [UIView animateWithDuration:duration
                             animations:^{
                                 
                                 self.backgroundViewLeadingConstraint.constant = -CGRectGetWidth(self.frame);
                                 [self layoutIfNeeded];
                             } completion:^(BOOL finished) {
                                 self.alpha = 0;
                                 self.viewState = VS_Closed;
                                 if (completion && finished) {
                                     completion();
                                 }
                             }];
            break;
        }
    }
    
}




/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@end
