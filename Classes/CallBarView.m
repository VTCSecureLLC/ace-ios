//
//  CallBarView.m
//  linphone
//
//  Created by Misha Torosyan on 3/4/16.
//
//

#import "CallBarView.h"

#define kAnimationDuration 0.5f

@interface CallBarView ()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIView *bottomButtonsContainer;
@property (weak, nonatomic) IBOutlet UIView *moreMenuContainer;
@property (weak, nonatomic) IBOutlet UIButton *videoButton;
@property (weak, nonatomic) IBOutlet UIButton *voiceButton;
@property (weak, nonatomic) IBOutlet UIButton *keypadButton;
@property (weak, nonatomic) IBOutlet UIButton *soundButton;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIButton *endCallButton;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraButton;
@property (weak, nonatomic) IBOutlet UIButton *changeVideoLayoutButton;
@property (nonatomic, strong) NSTimer *hideTimer;

@end

@implementation CallBarView

#pragma mark - Override Methods
- (instancetype)initWithCoder:(NSCoder *)coder {
    
    self = [super initWithCoder:coder];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)dealloc {
    
    [self.hideTimer invalidate];
    self.hideTimer = nil;
}


#pragma mark - Private Methods
- (void)setupView {
    
    self.bottomButtonsContainer.layer.borderWidth = 0.5f;
    self.bottomButtonsContainer.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.moreMenuContainer.layer.borderWidth = 0.5f;
    self.moreMenuContainer.layer.borderColor = [UIColor lightGrayColor].CGColor;
}


#pragma mark - Hide Timer
- (void)startHideTimerWithDelay:(NSTimeInterval)delay {
    
    if (delay > 0) {
        
        [self.hideTimer invalidate];
        self.hideTimer = nil;
        
        _hideTimer = [NSTimer scheduledTimerWithTimeInterval:delay
                                                      target:self
                                                    selector:@selector(hideTimerHandler:)
                                                    userInfo:nil
                                                     repeats:YES];
    }
}

- (void)hideTimerHandler:(NSTimer *)timer {
    
    [self hideWithAnimation:YES completion:nil];
}

//Resets timer which hides the view with animation
- (void)resetHideTimer {
    
    [self startHideTimerWithDelay:self.hideAfterDelay];
}


#pragma mark - Animations
//Showes view
- (void)showWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.backgroundViewBottomConstraint.constant = 0;
    self.tag = 1;
    [self resetHideTimer];
    if (animation) {
        if (self.callBarWillShowWithDurationBlock) {
            self.callBarWillShowWithDurationBlock(kAnimationDuration);
        }
        [UIView animateWithDuration:kAnimationDuration
                         animations:^{
                             
                             self.alpha = 1;
                             [self layoutIfNeeded];
                         } completion:^(BOOL finished) {
                             
                             if (completion && finished) {
                                 completion();
                             }
                         }];
    }
    else {
        if (self.callBarWillShowWithDurationBlock) {
            self.callBarWillShowWithDurationBlock(0);
        }
    }
}

//Hides view
- (void)hideWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.backgroundViewBottomConstraint.constant = -CGRectGetHeight(self.backgroundView.frame);
    [self hideMoreMenu];
    self.tag = 0;
    if (animation) {
        if (self.callBarWillHideWithDurationBlock) {
            self.callBarWillHideWithDurationBlock(kAnimationDuration);
        }
        [UIView animateWithDuration:kAnimationDuration
                         animations:^{
                             
                             self.alpha = 0;
                             [self layoutIfNeeded];
                         } completion:^(BOOL finished) {
                             
                             if (completion && finished) {
                                 completion();
                             }
                         }];
    }
    else {
        if (self.callBarWillHideWithDurationBlock) {
            self.callBarWillHideWithDurationBlock(0);
        }
    }
}

- (void)showMoreMenu {
    
    self.moreMenuContainer.hidden = NO;
    self.moreMenuContainer.tag = 1;
    [self resetHideTimer];
    [UIView animateWithDuration:kAnimationDuration
                     animations:^{
                         self.moreMenuContainer.alpha = 1;
                     }];
}

- (void)hideMoreMenu {
    
    self.moreMenuContainer.tag = 0;
    
    [UIView animateWithDuration:kAnimationDuration
                     animations:^{
                         self.moreMenuContainer.alpha = 0;
                         [self.moreButton setSelected:NO];
                     }];
}


#pragma mark - Action methods
- (IBAction)videoButtonAction:(UIButton *)sender {
    
    [self resetHideTimer];
    
    if (self.videoButtonActionBlock) {
        self.videoButtonActionBlock(sender);
    }
    
}

- (IBAction)voiceButtonAction:(UIButton *)sender {
    
    [self resetHideTimer];
    
    if (self.voiceButtonActionBlock) {
        self.voiceButtonActionBlock(sender);
    }
}

- (IBAction)keypadButtonAction:(UIButton *)sender {
    
    [self resetHideTimer];
    
    if (self.keypadButtonActionBlock) {
        self.keypadButtonActionBlock(sender);
    }
}

- (IBAction)soundButtonAction:(UIButton *)sender {
    
    [self resetHideTimer];
    
    if (self.soundButtonActionBlock) {
        self.soundButtonActionBlock(sender);
    }
}

- (IBAction)moreButtonAction:(UIButton *)sender {
    
    [self resetHideTimer];
    
    [sender setSelected:!sender.selected];
    
    if (self.moreMenuContainer.tag == 0) {
        
        [self showMoreMenu];
    }
    else {
        
        [self hideMoreMenu];
    }
    
    if (self.moreButtonActionBlock) {
        self.moreButtonActionBlock(sender);
    }
}

- (IBAction)switchCameraButtonAction:(UIButton *)sender {
    
    [self resetHideTimer];
    
    if (self.switchCameraButtonActionBlock) {
        self.switchCameraButtonActionBlock(sender);
    }
}

- (IBAction)changeVideoLayoutButtonAction:(UIButton *)sender {
    
    [self resetHideTimer];
    
    if (self.changeVideoLayoutButtonActionBlock) {
        self.changeVideoLayoutButtonActionBlock(sender);
    }
}

- (IBAction)endCallButtonAction:(UIButton *)sender {
    
    if (self.endCallButtonActionBlock) {
        self.endCallButtonActionBlock(sender);
    }
}


#pragma mark - Setters/Getters
- (void)setHideAfterDelay:(NSTimeInterval)hideAfterDelay {
    
    _hideAfterDelay = hideAfterDelay;
}

- (void)setVideoButtonSelected:(BOOL)videoButtonSelected {
    
    self.videoButton.selected = videoButtonSelected;
}

- (void)setVoiceButtonSelected:(BOOL)voiceButtonSelected {
    
    self.voiceButton.selected = voiceButtonSelected;
}

- (void)setKeypadButtonSelected:(BOOL)keypadButtonSelected {
    
    self.keypadButton.selected = keypadButtonSelected;
}

- (void)setSoundButtonSelected:(BOOL)soundButtonSelected {
    
    self.soundButton.selected = soundButtonSelected;
}

- (void)setMoreButtonSelected:(BOOL)moreButtonSelected {
    
    self.moreButton.selected = moreButtonSelected;
}

- (BOOL)isVideoButtonSelected {
    
    return self.videoButton.selected;
}

- (BOOL)isVoiceButtonSelected {
    
    return self.voiceButton.selected;
}

- (BOOL)isKeypadButtonSelected {
    
    return self.keypadButton.selected;
}

- (BOOL)isSoundButtonSelected {
    
    return self.soundButton.selected;
}

- (BOOL)isMoreButtonSelected {
    
    return self.moreButton.selected;
}


@end
