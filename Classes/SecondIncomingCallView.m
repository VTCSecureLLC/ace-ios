//
//  InCallNewCallNotificationView.m
//  linphone
//
//  Created by Ruben Semerjyan on 3/3/16.
//
//

#import "SecondIncomingCallView.h"
#import "LinphoneManager.h"
#import "UILinphone.h"


#define kAnimationDuration 0.5f
static NSString *BackgroundAnimationKey = @"animateBackground";


@interface SecondIncomingCallView ()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewTopConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *callStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *ringCountLabel;
@property (nonatomic, assign) LinphoneCall *call;
@property (nonatomic, strong) NSTimer *ringsCountTimer;

@end


@implementation SecondIncomingCallView

#pragma mark - Life Cycle
- (instancetype)initWithCoder:(NSCoder *)coder {
    
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    
    return self;
}


#pragma mark - Private Methods
- (void)setupView {
    
    self.profileImageView.layer.cornerRadius = CGRectGetHeight(self.profileImageView.frame)/2;
    self.profileImageView.layer.masksToBounds = YES;
    self.profileImageView.layer.borderWidth = 1.f;
    self.profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
}

- (void)startBackgroundColorAnimation {
    
    CABasicAnimation *theAnimation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
    theAnimation.duration = 0.7f;
    theAnimation.repeatCount = HUGE_VAL;
    theAnimation.autoreverses = YES;
    theAnimation.toValue = (id)[UIColor colorWithRed:0.1843 green:0.1961 blue:0.1961 alpha:1.0].CGColor;
    [self.backgroundView.layer addAnimation:theAnimation forKey:BackgroundAnimationKey];
}

- (void)stopBackgroundColorAnimation {
    
    [self.backgroundView.layer removeAnimationForKey:BackgroundAnimationKey];
}



#pragma mark - Action Methods
- (IBAction)notificationViewAction:(UIButton *)sender {
    
    if (self.notificationViewActionBlock) {
        self.notificationViewActionBlock(self.call);
    }
}


#pragma mark - Instance Methods
- (void)fillWithCallModel:(LinphoneCall *)linphoneCall {
    
    self.call = linphoneCall;
    
    [[LinphoneManager instance] fetchProfileImageWithCall:linphoneCall withCompletion:^(UIImage *image) {
        
        _profileImageView.image = image;
    }];
    _nameLabel.text = [[LinphoneManager instance] fetchAddressWithCall:linphoneCall];
}

- (void)showNotificationWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.viewState = VS_Animating;
    NSTimeInterval duration = animation ? kAnimationDuration : 0;
    self.alpha = 1;
    [self startBackgroundColorAnimation];
    
    [UIView animateWithDuration:duration
                     animations:^{
                         
                         self.backgroundViewTopConstraint.constant = 0;
                         [self layoutIfNeeded];
                         
                     } completion:^(BOOL finished) {
                         
                         self.viewState = VS_Opened;
                         [self startCalculatingRingsCount];
                         if (completion && finished) {
                             completion();
                         }
                     }];
}

- (void)hideNotificationWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.viewState = VS_Animating;
    NSTimeInterval duration = animation ? kAnimationDuration : 0;
    [self stopBackgroundColorAnimation];
    if (animation) {
        [UIView animateWithDuration:duration
                         animations:^{
                             self.backgroundViewTopConstraint.constant = -CGRectGetHeight(self.frame);
                             [self layoutIfNeeded];
                             
                         } completion:^(BOOL finished) {
                             
                             self.alpha = 0;
                             self.viewState = VS_Closed;
                             [self stopAndResetRingsCount];
                             if (completion && finished) {
                                 completion();
                             }
                         }];
    }
    else {
        self.alpha = 0;
    }
}

- (void)displayIncrementedRingCount {
    
    self.ringCountLabel.hidden = NO;
    self.ringCountLabel.hidden = NO;
    [UIView transitionWithView:self.ringCountLabel
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.ringCountLabel.text = [@(self.ringCountLabel.text.intValue + 1) stringValue];
                    }
                    completion:nil];
}

- (void)startCalculatingRingsCount {
    
    NSTimeInterval timeInterval = [[LinphoneManager instance] lpConfigFloatForKey:@"incoming_vibrate_frequency" forSection:@"vtcsecure"];
    self.ringsCountTimer = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                            target:self
                                                          selector:@selector(displayIncrementedRingCount)
                                                          userInfo:nil
                                                           repeats:YES];
}

- (void)stopAndResetRingsCount {
    
    self.ringCountLabel.text = @"0";
    if (self.ringsCountTimer) {
        [self.ringsCountTimer invalidate];
        self.ringsCountTimer = nil;
    }
}

@end
