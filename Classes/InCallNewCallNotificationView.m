//
//  InCallNewCallNotificationView.m
//  linphone
//
//  Created by Misha Torosyan on 3/3/16.
//
//

#import "InCallNewCallNotificationView.h"

#define kAnimationDuration 0.5f


@interface InCallNewCallNotificationView ()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewTopConstraint;

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *callStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *ringCountLabel;

@property (nonatomic, assign) LinphoneCall *call;

@end

@implementation InCallNewCallNotificationView

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

- (IBAction)notificationViewAction:(UIButton *)sender {
    
    if (self.notificationViewActionBlock) {
        self.notificationViewActionBlock(self.call);
    }
}


#pragma mark - Animations

//Showes view
- (void)showNotificationWithAnimation:(BOOL)animation {
    
    self.backgroundViewTopConstraint.constant = 0;
    self.alpha = 1;
    if (animation) {
        [UIView animateWithDuration:kAnimationDuration
                         animations:^{
                             [self layoutIfNeeded];
                         }];
    }
}

//Hides view
- (void)hideNotificationWithAnimation:(BOOL)animation {
    
    self.backgroundViewTopConstraint.constant = -CGRectGetHeight(self.frame);
    
    if (animation) {
        [UIView animateWithDuration:kAnimationDuration
                         animations:^{
                             [self layoutIfNeeded];
                         } completion:^(BOOL finished) {
                             self.alpha = 0;
                         }];
    } else {
        self.alpha = 0;
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
