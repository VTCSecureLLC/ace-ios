//
//  InCallNewCallNotificationView.m
//  linphone
//
//  Created by Misha Torosyan on 3/3/16.
//
//

#import "InCallNewCallNotificationView.h"


@interface InCallNewCallNotificationView ()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *callStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *ringCount;

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

#pragma mark - Action Methods

- (IBAction)notificationViewAction:(UIButton *)sender {
    if (self.notificationViewActionBlock) {
        self.notificationViewActionBlock(sender);
    }
}


//Filles notification data with LinphoneCall model
- (void)fillWithCallModel:(LinphoneCall *)linphoneCall {
    //TODO: Fill with passed method's param
}


- (void)showNotificationWithAnimation:(BOOL)animation {

}




/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
