//
//  CallBarView.m
//  linphone
//
//  Created by Ruben Semerjyan on 3/4/16.
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
@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (weak, nonatomic) IBOutlet UIButton *endCallButton;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraButton;
@property (weak, nonatomic) IBOutlet UIButton *changeVideoLayoutButton;

// Automatic hiding
//@property (nonatomic, strong) NSTimer *hideTimer;

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
    
    // Automatic hiding
//    [self.hideTimer invalidate];
//    self.hideTimer = nil;
}


#pragma mark - Private Methods
- (void)setupView {
    
    self.bottomButtonsContainer.layer.borderWidth = 0.5f;
    self.bottomButtonsContainer.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.moreMenuContainer.layer.borderWidth = 0.5f;
    self.moreMenuContainer.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.viewState = VS_Opened;
}


#pragma mark - Hide Timer
// Automatic hiding
//- (void)startHideTimerWithDelay:(NSTimeInterval)delay {
//    
//    if (delay > 0) {
//        
//        [self.hideTimer invalidate];
//        self.hideTimer = nil;
//        
//        _hideTimer = [NSTimer scheduledTimerWithTimeInterval:delay
//                                                      target:self
//                                                    selector:@selector(hideTimerHandler:)
//                                                    userInfo:nil
//                                                     repeats:NO];
//    }
//}

// Automatic hiding
//- (void)hideTimerHandler:(NSTimer *)timer {
//    
//    [self hideWithAnimation:YES completion:nil];
//    [self.hideTimer invalidate];
//    self.hideTimer = nil;
//}

// Automatic hiding
////Resets timer which hides the view with animation
//- (void)resetHideTimer {
//    
//    [self startHideTimerWithDelay:self.hideAfterDelay];
//}

#pragma mark - Animations
//Showes view
- (void)showWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.viewState = VS_Animating;
    NSTimeInterval duration = animation ? kAnimationDuration : 0;
// Automatic hiding
//    [self resetHideTimer];
    
    if (self.callBarWillShowWithDurationBlock) {
        self.callBarWillShowWithDurationBlock(duration);
    }
    
    [UIView animateWithDuration:duration
                     animations:^{
                         
                         self.backgroundViewBottomConstraint.constant = 0;
                         self.alpha = 1;
                         [self layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         
                         self.viewState = VS_Opened;
                         if (completion && finished) {
                             completion();
                         }
                     }];
}

//Hides view
- (void)hideWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.viewState = VS_Animating;
    NSTimeInterval duration = animation ? kAnimationDuration : 0;
    [self hideMoreMenu];
    
    if (self.callBarWillHideWithDurationBlock) {
        self.callBarWillHideWithDurationBlock(duration);
    }
    
    [UIView animateWithDuration:duration
                     animations:^{
                         
                         self.backgroundViewBottomConstraint.constant = -CGRectGetHeight(self.backgroundView.frame);
                         self.alpha = 0;
                         [self layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         
                         self.viewState = VS_Closed;
                         if (completion && finished) {
                             completion();
                         }
                     }];
}

- (void)showMoreMenu {
    
    self.moreMenuContainer.hidden = NO;
    self.moreMenuContainer.tag = 1;
    // Automatic hiding
//    [self resetHideTimer];
    [UIView animateWithDuration:kAnimationDuration
                     animations:^{
                         self.moreMenuContainer.alpha = 1;
                         [self.moreButton setSelected:YES];
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
    
// Automatic hiding
//    [self resetHideTimer];
    
    if (self.videoButtonActionHandler) {
        self.videoButtonActionHandler(sender);
    }
    
}

- (IBAction)voiceButtonAction:(UIButton *)sender {
    
    // Automatic hiding
//    [self resetHideTimer];
    
    if (self.voiceButtonActionHandler) {
        self.voiceButtonActionHandler(sender);
    }
}

- (IBAction)keypadButtonAction:(UIButton *)sender {
    
    // Automatic hiding
//    [self resetHideTimer];
    
    if (self.keypadButtonActionHandler) {
        self.keypadButtonActionHandler(sender);
    }
}

- (IBAction)soundButtonAction:(UIButton *)sender {
    
    // Automatic hiding
//    [self resetHideTimer];
    
    if (self.soundButtonActionHandler) {
        self.soundButtonActionHandler(sender);
    }
}

- (IBAction)moreButtonAction:(UIButton *)sender {
    
    // Automatic hiding
//    [self resetHideTimer];
    
    if (self.moreMenuContainer.tag == 0) {
        
        [self showMoreMenu];
    }
    else {
        
        [self hideMoreMenu];
    }
    
    if (self.moreButtonActionHandler) {
        self.moreButtonActionHandler(sender);
    }
}

- (IBAction)switchCameraButtonAction:(UIButton *)sender {
    
    // Automatic hiding
//    [self resetHideTimer];
    
    if (self.switchCameraButtonActionHandler) {
        self.switchCameraButtonActionHandler(sender);
    }
}

- (IBAction)changeVideoLayoutButtonAction:(UIButton *)sender {
    
    // Automatic hiding
//    [self resetHideTimer];
    
    if (self.changeVideoLayoutButtonActionHandler) {
        self.changeVideoLayoutButtonActionHandler(sender);
    }
}

- (IBAction)chatButtonAction:(UIButton *)sender {
    
    if (self.chatButtonActionHandler) {
        self.chatButtonActionHandler(sender);
    }
}

- (IBAction)endCallButtonAction:(UIButton *)sender {
    
    if (self.endCallButtonActionHandler) {
        self.endCallButtonActionHandler(sender);
    }
}


#pragma mark - Setters/Getters
// Automatic hiding
//- (void)setHideAfterDelay:(NSTimeInterval)hideAfterDelay {
//    
//    _hideAfterDelay = hideAfterDelay;
//    
//    [self resetHideTimer];
//}

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

- (void)changeChatButtonVisibility:(BOOL)hidden {
    
    self.chatButton.hidden = hidden;
}


@end
