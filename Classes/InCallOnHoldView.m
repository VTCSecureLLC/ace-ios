//
//  InCallOnHoldView.m
//  linphone
//
//  Created by Ruben Semerjyan on 3/3/16.
//
//

#import "InCallOnHoldView.h"
#import "LinphoneManager.h"


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
@property (nonatomic, strong) NSTimer *holdTimer;
@property (nonatomic, strong) NSDate *holdDate;

@end


@implementation InCallOnHoldView

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
    self.profileImageView.layer.borderWidth = 1.f;
    self.profileImageView.layer.masksToBounds = YES;
    self.profileImageView.layer.borderColor = [UIColor whiteColor].CGColor;
}

- (NSString *)elapsedTime:(NSTimeInterval)time {
    
    NSString *timeString = nil;
    
    NSInteger timeInterval = (NSInteger)fabs(time);
    NSInteger seconds = timeInterval % 60;
    NSInteger minutes = (timeInterval / 60) % 60;
    NSInteger hours = (timeInterval / 3600);
    if (hours > 0) {
        timeString = [NSString stringWithFormat:@"%02li:%02li:%02li", (long)hours, (long)minutes, (long)seconds];
    }
    else {
        timeString = [NSString stringWithFormat:@"%02li:%02li", (long)minutes, (long)seconds];
    }
    
    return timeString;
}

- (void)holdTimerFired:(NSTimer *)timer {
    
    NSTimeInterval elapsedTime = [[NSDate new] timeIntervalSinceDate:_holdDate];
    _timerLabel.text = [self elapsedTime:elapsedTime];
}

- (IBAction)holdViewAction:(UIButton *)sender {
    
    if (self.holdViewActionBlock) {
        self.holdViewActionBlock(self.call);
    }
}


#pragma mark - Instance Methods
- (void)startTimeCounting {
    
    _holdDate = [NSDate new];
    _holdTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(holdTimerFired:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)stopTimeCounting {
    
    _holdDate = nil;
    [_holdTimer invalidate];
    _holdTimer = nil;
    _timerLabel.text = @"00:00";
}

- (void)resetTimeCounting {
    
    [self stopTimeCounting];
    [self startTimeCounting];
}

- (void)fillWithCallModel:(LinphoneCall *)linphoneCall {
    
    self.call = linphoneCall;
    
    [self stopTimeCounting];
    [self startTimeCounting];
    [[LinphoneManager instance] fetchProfileImageWithCall:linphoneCall withCompletion:^(UIImage *image) {
        
        _profileImageView.image = image;
    }];
    _nameLabel.text = [[LinphoneManager instance] fetchAddressWithCall:linphoneCall];
}

- (void)showWithAnimation:(BOOL)animation
                direction:(AnimationDirection)direction
               completion:(void(^)())completion {
    
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

- (void)hideWithAnimation:(BOOL)animation
                direction:(AnimationDirection)direction
               completion:(void(^)())completion {
    
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

@end
