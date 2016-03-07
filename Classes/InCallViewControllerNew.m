//
//  InCallViewControllerNew.m
//  linphone
//
//  Created by Hrachya Stepanyan on 3/1/16.
//
//

#import "InCallViewControllerNew.h"
#import "LinphoneManager.h"
#import "IncallButton.h"
#import "UIManager.h"
#import "SecondIncomingCallBarView.h"
#import "IncomingCallViewControllerNew.h"
#import "SecondIncomingCallView.h"
#import "InCallOnHoldView.h"
#import "CallBarView.h"


#define kBottomButtonsAnimationDuration 0.3f

@interface InCallViewControllerNew ()

@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UIView *videoPreviewView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *videoPreviewViewBottomConstraint;
@property (weak, nonatomic) IBOutlet CallBarView *callBarView;
@property (weak, nonatomic) IBOutlet SecondIncomingCallBarView *secondIncomingCallBarView;
@property (weak, nonatomic) IBOutlet SecondIncomingCallView *secondIncomingCallView;
@property (weak, nonatomic) IBOutlet InCallOnHoldView *inCallOnHoldView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inCallNewCallViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *holdByRemoteImageView;
@property (weak, nonatomic) IBOutlet UIImageView *cameraImageView;

@end


@implementation InCallViewControllerNew

#pragma mark - Life Cycle Methods
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setupCallBarView];
    [self setupSecondIncomingCallView];
    [self setupSecondIncomingCallBarView];
    [self setupInCallOnHoldView];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    [self setupNotifications];
    [self resetSpeakerWithSettings];
    [self resetMicrophoneWithSettings];
    [self setupVideo];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [self removeNotifications];
    [self resetVideoViews];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:animated];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}


#pragma mark - Event Methods
- (void)callUpdateEvent:(NSNotification *)notification {
    
    LinphoneCall *linphoneCall = [[notification.userInfo objectForKey:@"call"] pointerValue];
    LinphoneCallState linphoneCallState = [[notification.userInfo objectForKey:@"state"] intValue];
    [self callUpdate:linphoneCall state:linphoneCallState animated:TRUE];
}

- (void)videoModeUpdate:(NSNotification *)notification {
    
    NSString *videoMode = [notification.userInfo objectForKey: @"videoModeStatus"];
    if ([videoMode isEqualToString:@"camera_mute_off"]) {
        _cameraImageView.hidden = NO;
    }
    
    if ([videoMode isEqualToString:@"isCameraMuted"] || [videoMode isEqualToString:@"camera_mute_on"]) {
        _cameraImageView.hidden = YES;
    }
}


#pragma mark - Private Methods
- (void)callUpdate:(LinphoneCall *)call state:(LinphoneCallState)state animated:(BOOL)animated {
    
//    LinphoneCore *lc = [LinphoneManager getLc];
//    if (hiddenVolume) {
//        [[PhoneMainView instance] setVolumeHidden:FALSE];
//        hiddenVolume = FALSE;
//    }
    
    NSAssert(call, @"Call cannot be NULL");
    
    switch (state) {
        case LinphoneCallIdle: {
            
            NSAssert(0, @"LinphoneCallIdle: Just need to check this state");
            break;
        }
        case LinphoneCallIncomingReceived: {
            
            [self incomingReceivedWithCall:call];
            // This is second call
            break;
        }
        case LinphoneCallOutgoingInit: {
            
            //            NSAssert(0, @"LinphoneCallOutgoingInit: Just need to check this state");
            break;
        }
        case LinphoneCallOutgoingProgress: {
            
            //            NSAssert(0, @"LinphoneCallOutgoingProgress: Just need to check this state");
            break;
        }
        case LinphoneCallOutgoingRinging: {
            
            //            NSAssert(0, @"LinphoneCallOutgoingRinging: Just need to check this state");
            break;
        }
        case LinphoneCallOutgoingEarlyMedia: {
            
            NSAssert(0, @"LinphoneCallOutgoingEarlyMedia: Just need to check this state");
            break;
        }
        case LinphoneCallConnected: {
            
            //            NSAssert(0, @"LinphoneCallConnected: Just need to check this state");
            break;
        }
        case LinphoneCallStreamsRunning: {
            
            _holdByRemoteImageView.hidden = YES;
            // Show first call in hold view
            
            [self checkHoldCall];
            
            break;
        }
        case LinphoneCallPausing: {
            
            //            NSAssert(0, @"LinphoneCallPausing: Just need to check this state");
            break;
        }
        case LinphoneCallPaused: {
            
            //            NSAssert(0, @"LinphoneCallPaused: Just need to check this state");
            break;
        }
        case LinphoneCallResuming: {
            
            //            NSAssert(0, @"LinphoneCallResuming: Just need to check this state");
            break;
        }
        case LinphoneCallRefered: {
            
            NSAssert(0, @"LinphoneCallRefered: Just need to check this state");
            break;
        }
        case LinphoneCallError: {
            
            [[UIManager sharedManager] hideInCallViewControllerAnimated:YES];
            break;
        }
        case LinphoneCallEnd: {
            
            [self.inCallOnHoldView hideWithAnimation:YES direction:AnimationDirectionLeft completion:nil];
            NSUInteger callsCount = [[LinphoneManager instance] callsCountForLinphoneCore:[LinphoneManager getLc]];
            if (callsCount == 0) {
                [[UIManager sharedManager] hideInCallViewControllerAnimated:YES];
            }
            else if (callsCount == 1) {
                LinphoneCall *holdCall = [[LinphoneManager instance] holdCall];
                if ([[LinphoneManager instance] callStateForCall:holdCall] == LinphoneCallIncomingReceived) {
                    if ([self.navigationController.rotatingFooterView isKindOfClass:[IncomingCallViewControllerNew class]]) {
                        [(IncomingCallViewControllerNew *)self.navigationController.rotatingFooterView setCall:holdCall];
                    }
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
            
            break;
        }
        case LinphoneCallPausedByRemote: {
            
            _holdByRemoteImageView.hidden = NO;
            break;
        }
        case LinphoneCallUpdatedByRemote: {
            
            //            NSAssert(0, @"LinphoneCallUpdatedByRemote: Just need to check this state");
            break;
        }
        case LinphoneCallIncomingEarlyMedia: {
            
            NSAssert(0, @"LinphoneCallIncomingEarlyMedia: Just need to check this state");
            break;
        }
        case LinphoneCallUpdating: {
            
            //            NSAssert(0, @"LinphoneCallUpdating: Just need to check this state");
            break;
        }
        case LinphoneCallReleased: {
            
            [self hideSecondIncomingCallUI];
            break;
        }
        case LinphoneCallEarlyUpdatedByRemote: {
            
            NSAssert(0, @"LinphoneCallEarlyUpdatedByRemote: Just need to check this state");
            break;
        }
        case LinphoneCallEarlyUpdating: {
            
            NSAssert(0, @"LinphoneCallEarlyUpdating: Just need to check this state");
            break;
        }
        default:
            break;
    }
    
    [self setupVideoButtonState];
    [self setupMicriphoneButtonState];
    [self setupSpeakerButtonState];
}

- (void)checkHoldCall {
    
    LinphoneCall *holdCall = [[LinphoneManager instance] holdCall];
    if (holdCall) {
        [self.inCallOnHoldView fillWithCallModel:holdCall];
        [self.inCallOnHoldView showWithAnimation:YES direction:AnimationDirectionLeft completion:nil];
    }
}

- (void)setupNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callUpdateEvent:)
                                                 name:kLinphoneCallUpdate
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoModeUpdate:)
                                                 name:kLinphoneVideModeUpdate
                                               object:nil];
}

- (void)removeNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneVideModeUpdate object:nil];
}

- (void)setupVideo {
    
    [[LinphoneManager instance] setVideoWindowForLinphoneCore:[LinphoneManager getLc] toView:_videoView];
    [[LinphoneManager instance] setPreviewWindowForLinphoneCore:[LinphoneManager getLc] toView:_videoPreviewView];
}

- (void)resetVideoViews {
    
    [[LinphoneManager instance] setVideoWindowForLinphoneCore:[LinphoneManager getLc] toView:nil];
    [[LinphoneManager instance] setPreviewWindowForLinphoneCore:[LinphoneManager getLc] toView:nil];
}

- (void)incomingReceivedWithCall:(LinphoneCall *)call {
    
    [self showSecondIncomingCallUIWithCall:(LinphoneCall *)call];
}

- (void)setupCallBarView {
    
    // Automatic hiding
//    self.callBarView.hideAfterDelay = 3.f;
    __weak InCallViewControllerNew *weakSelf = self;
    
    self.callBarView.callBarWillHideWithDurationBlock = ^(NSTimeInterval duration) {
        
        [weakSelf animateToBottomVideoPreviewViewWithDuration:duration];
    };
    
    self.callBarView.callBarWillShowWithDurationBlock = ^(NSTimeInterval duration) {
        
        [weakSelf animateToTopVideoPreviewViewWithDuration:duration];
    };
    
    
    self.callBarView.videoButtonActionHandler = ^(UIButton *sender) {
        
        if ([[LinphoneManager instance] isCameraEnabledForCurrentCall]) {
            [[LinphoneManager instance] disableCameraForCurrentCall];
        }
        else {
            [[LinphoneManager instance] enableCameraForCurrentCall];
        }
        
        [weakSelf setupVideoButtonState];
    };
    
    self.callBarView.voiceButtonActionHandler = ^(UIButton *sender) {
        
        if ([[LinphoneManager instance] isMicrophoneEnabled]) {
            [[LinphoneManager instance] disableMicrophone];
        }
        else {
            [[LinphoneManager instance] enableMicrophone];
        }
        
        [weakSelf setupMicriphoneButtonState];
    };
    
    self.callBarView.keypadButtonActionHandler = ^(UIButton *sender) {
        
    };
    
    self.callBarView.soundButtonActionHandler = ^(UIButton *sender) {
        
        if ([[LinphoneManager instance] isSpeakerEnabled]) {
            [[LinphoneManager instance] disableSpeaker];
        }
        else {
            [[LinphoneManager instance] enableSpeaker];
        }
        
        [weakSelf setupSpeakerButtonState];
    };
    
    self.callBarView.switchCameraButtonActionHandler = ^(UIButton *sender) {
        
        [[LinphoneManager instance] switchCamera];
    };
    
    self.callBarView.changeVideoLayoutButtonActionHandler = ^(UIButton *sender) {
        
    };
    
    self.callBarView.endCallButtonActionHandler = ^(UIButton *sender) {
        
        [[LinphoneManager instance] terminateCurrentCall];
    };
}

- (void)showSecondIncomingCallUIWithCall:(LinphoneCall *)call {
    
    [self.callBarView hideWithAnimation:NO completion:nil];
    self.secondIncomingCallBarView.linphoneCall = call;
    [self.secondIncomingCallBarView showWithAnimation:YES completion:nil];
    [self.secondIncomingCallView showNotificationWithAnimation:YES completion:nil];
    [self.secondIncomingCallView fillWithCallModel:call];
}

- (void)hideSecondIncomingCallUI {
    
    [self.secondIncomingCallBarView hideWithAnimation:YES completion:nil];
    [self.secondIncomingCallView hideNotificationWithAnimation:YES completion:nil];
}

- (void)setupVideoButtonState {
    
    if ([[LinphoneManager instance] isCameraEnabledForCurrentCall]) {
        
        self.callBarView.videoButtonSelected = NO;
    }
    else {
        
        self.callBarView.videoButtonSelected = YES;
    }
}

- (void)resetMicrophoneWithSettings {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL isCallAudioMuted = [userDefaults boolForKey:@"isCallAudioMuted"];
    if (isCallAudioMuted) {
        
        [[LinphoneManager instance] disableMicrophone];
    }
    else {
        [[LinphoneManager instance] enableMicrophone];
    }
}

- (void)setupMicriphoneButtonState {
    
    if ([[LinphoneManager instance] isMicrophoneEnabled]) {
        
        self.callBarView.voiceButtonSelected = NO;
    }
    else {
        
        self.callBarView.voiceButtonSelected = YES;
    }
}

- (void)resetSpeakerWithSettings {
    
    BOOL isSpeakerEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"isSpeakerEnabled"];
    if (isSpeakerEnabled){
        linphone_core_set_playback_gain_db([LinphoneManager getLc], 0);
    }
    else {
        linphone_core_set_playback_gain_db([LinphoneManager getLc], -1000.0f);
    }
}

- (void)setupSpeakerButtonState {
    
    if ([[LinphoneManager instance] isSpeakerEnabled]) {
        
        self.callBarView.soundButtonSelected = NO;
    }
    else {
        
        self.callBarView.soundButtonSelected = YES;
    }
}

- (void)setupSecondIncomingCallBarView {
    
    self.secondIncomingCallBarView.messageButtonBlock = ^(LinphoneCall *linphoneCall) {
        
        // TODO: Send message to second caller
    };
    
    self.secondIncomingCallBarView.declineButtonBlock = ^(LinphoneCall *linphoneCall) {
        
        [[LinphoneManager instance] declineCall:linphoneCall];
        [self hideSecondIncomingCallUI];
    };
    
    self.secondIncomingCallBarView.acceptButtonBlock = ^(LinphoneCall *linphoneCall) {
        
        [[LinphoneManager instance] acceptCall:linphoneCall];
        
        [self hideSecondIncomingCallUI];
    };
}

- (void)setupSecondIncomingCallView {
    
    [self.secondIncomingCallView hideNotificationWithAnimation:NO completion:nil];
    
    self.secondIncomingCallView.notificationViewActionBlock = ^(LinphoneCall *call) {
        // We don't have any action here
    };
}

- (void)setupInCallOnHoldView {
    
    [self.inCallOnHoldView hideWithAnimation:NO direction:AnimationDirectionLeft completion:nil];
    
    self.inCallOnHoldView.holdViewActionBlock = ^(LinphoneCall *call) {
        
        [self.inCallOnHoldView fillWithCallModel:[[LinphoneManager instance] currentCall]];
        [[LinphoneManager instance] resumeCall:call];
    };
}

- (void)animateToBottomVideoPreviewViewWithDuration:(NSTimeInterval)duration {
    
    __weak InCallViewControllerNew *weakSelf = self;

    [UIView animateWithDuration:duration
                     animations:^{
                         weakSelf.videoPreviewViewBottomConstraint.constant = 20;
                         [weakSelf.view layoutIfNeeded];
                     }];
}

- (void)animateToTopVideoPreviewViewWithDuration:(NSTimeInterval)duration {
    
    __weak InCallViewControllerNew *weakSelf = self;
    [UIView animateWithDuration:duration
                     animations:^{
                         weakSelf.videoPreviewViewBottomConstraint.constant = 160;
                         [weakSelf.view layoutIfNeeded];
                     }];
}

#pragma mark - Actions Methods
- (IBAction)videoViewAction:(UITapGestureRecognizer *)sender {

    if (self.callBarView.viewState == VS_Closed) {
        
        [self.callBarView showWithAnimation:YES completion:nil];
    }
    else if (self.callBarView.viewState == VS_Opened) {
        [self.callBarView hideWithAnimation:YES completion:nil];
    }
}

@end
