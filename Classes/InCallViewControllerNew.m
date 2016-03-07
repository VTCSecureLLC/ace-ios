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

@end


@implementation InCallViewControllerNew

#pragma mark - Life Cycle Methods
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setupCallBarView];
    [self setupInCallNewCallNotificationView];
    [self setupInCallNewCallView];
    [self setupInCallOnHoldView];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    [self setupNotifications];
    [self resetSpeakerWithSettings];
    [self resetMicrophoneWithSettings];
    [self setupVideo];
    
//    LinphoneCall *linphoneCall = [[LinphoneManager instance] currentCall];
//    LinphoneCallState linphoneCallState = 0;
//    if (linphoneCall != NULL) {
//        linphoneCallState = [[LinphoneManager instance] callStateForCall:linphoneCall];
//    }
//    [self callUpdate:linphoneCall state:linphoneCallState animated:FALSE];
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
    
//    NSString *videoMode = [notification.userInfo objectForKey: @"videoModeStatus"];
//    if ([videoMode isEqualToString:@"camera_mute_off"]) {
//        [_cameraStatusModeImageView setImage:[UIImage imageNamed:@"camera_mute.png"]];
//        [_blackCurtain addSubview:_cameraStatusModeImageView];
//        [self.videoGroup insertSubview:_blackCurtain belowSubview:self.videoPreview];
//    }
//    if ([videoMode isEqualToString:@"isCameraMuted"] || [videoMode isEqualToString:@"camera_mute_on"]) {
//        [_blackCurtain removeFromSuperview];
//    }
}


#pragma mark - Private Methods
- (void)callUpdate:(LinphoneCall *)call state:(LinphoneCallState)state animated:(BOOL)animated {
    
    //    LinphoneCore *lc = [LinphoneManager getLc];
    //    if (hiddenVolume) {
    //        [[PhoneMainView instance] setVolumeHidden:FALSE];
    //        hiddenVolume = FALSE;
    //    }
    //
    //    // Update table
    //    [callTableView reloadData];
    //
    //    // Fake call update
    //    if (call == NULL) {
    //        return;
    //    }
    //
    //    if(state == LinphoneCallPausedByRemote){
    //        UIImage *img = [UIImage imageNamed:@"Hold.png"];
    //        callOnHoldImageView = [[UIImageView alloc] initWithImage:img];
    //        [callOnHoldImageView setCenter:self.videoView.center];
    //        [callOnHoldImageView setHidden:NO];
    //        [callOnHoldImageView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
    //        [self.view addSubview:callOnHoldImageView];
    //        [self.videoView setHidden:YES];
    //    }
    //    else{
    //        if(callOnHoldImageView){
    //            [callOnHoldImageView removeFromSuperview];
    //        }
    //        [self.videoView setHidden:NO];
    //    }
    
    
    switch (state) {
        case LinphoneCallIdle: {
            
            NSAssert(0, @"LinphoneCallIdle: Just need to check this state");
            break;
        }
        case LinphoneCallIncomingReceived: {
            
            [self incomingReceivedWithCall:call];
            // This is second call
            //            NSAssert(0, @"LinphoneCallIncomingReceived: Just need to check this state");
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
            
            //            NSAssert(0, @"LinphoneCallStreamsRunning: Just need to check this state");
            _holdByRemoteImageView.hidden = YES;
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
            
            NSUInteger callsCount = [[LinphoneManager instance] callsCountForLinphoneCore:[LinphoneManager getLc]];
            if (callsCount == 0) {
                [[UIManager sharedManager] hideInCallViewControllerAnimated:YES];
            }
            else {
                [[LinphoneManager instance] declineCall:call];
            }
            break;
        }
        case LinphoneCallPausedByRemote: {
            
            _holdByRemoteImageView.hidden = NO;
//            NSAssert(0, @"LinphoneCallPausedByRemote: Just need to check this state");
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
            
            //            NSAssert(0, @"LinphoneCallReleased: Just need to check this state");
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
    
    //    switch (state) {
    //        case LinphoneCallIncomingReceived:
    //        case LinphoneCallOutgoingInit: {
    //            [self callOutgoingInit];
    //        }
    //        case LinphoneCallConnected:
    //        case LinphoneCallStreamsRunning: {
    //            [self callStreamsRunning];
    //            break;
    //        }
    //        case LinphoneCallUpdatedByRemote: {
    //            [self callUpdatedByRemote];
    //            break;
    //        }
    //        case LinphoneCallPausing:
    //        case LinphoneCallPaused:
    //        case LinphoneCallPausedByRemote: {
    //            [self callPausedByRemote];
    //            break;
    //        }
    //        case LinphoneCallEnd:
    //        case LinphoneCallError: {
    //            [self callError];
    //            break;
    //        }
    //        default:
    //            break;
    //    }
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

- (void)callOutgoingInit {
    
//    if (linphone_core_get_calls_nb(lc) > 1) {
//        [callTableController minimizeAll];
//    }
//    
//    if(!self.isRTTLocallyEnabled){
//        linphone_call_params_enable_realtime_text(linphone_core_create_call_params([LinphoneManager getLc], call), FALSE);
//    }
//    
//    callQualityImageView.hidden = YES;
}

- (void)callStreamsRunning {
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceOrientationDidChangeNotification
//                                                        object:nil];
//    if(state == LinphoneCallStreamsRunning){
//        if(self.isRTTLocallyEnabled){
//            if (linphone_call_params_realtime_text_enabled(linphone_call_get_remote_params(call))){
//                self.isRTTEnabled = YES;
//            }
//            else{
//                self.isRTTEnabled = NO;
//            }
//        }
//        else{
//            self.isRTTEnabled = NO;
//        }
//        hasStartedStream = YES;
//    }
//    else{
//        self.isRTTEnabled = YES;
//    }
//    // check video
//    if (linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
//        [self displayVideoCall:animated];
//        const LinphoneCallParams *params = linphone_call_get_current_params(call);
//        if(params != NULL){
//            if(strcmp(linphone_call_params_get_used_video_codec(params)->mime_type, "H263") == 0){
//                linphone_core_set_device_rotation([LinphoneManager getLc], 270);
//                linphone_core_update_call([LinphoneManager getLc], call, NULL);
//            }
//            else{
//                [[PhoneMainView instance] orientationUpdate:self.interfaceOrientation];
//            }
//        }
//    } else {
//        [self displayTableCall:animated];
//        const LinphoneCallParams *param = linphone_call_get_current_params(call);
//        const LinphoneCallAppData *callAppData =
//        (__bridge const LinphoneCallAppData *)(linphone_call_get_user_pointer(call));
//        if (state == LinphoneCallStreamsRunning && callAppData->videoRequested &&
//            linphone_call_params_low_bandwidth_enabled(param)) {
//            // too bad video was not enabled because low bandwidth
//            UIAlertView *alert = [[UIAlertView alloc]
//                                  initWithTitle:NSLocalizedString(@"Low bandwidth", nil)
//                                  message:NSLocalizedString(@"Video cannot be activated because of low bandwidth "
//                                                            @"condition, only audio is available",
//                                                            nil)
//                                  delegate:nil
//                                  cancelButtonTitle:NSLocalizedString(@"Continue", nil)
//                                  otherButtonTitles:nil];
//            [alert show];
//            callAppData->videoRequested = FALSE; /*reset field*/
//        }
//    }
//    
//    timerCallQuality = [NSTimer scheduledTimerWithTimeInterval:1.0
//                                                        target:self
//                                                      selector:@selector(callQualityTimerBody)
//                                                      userInfo:nil
//                                                       repeats:YES];
//    
//    [self createCallQuality];
//    callQualityImageView.hidden = NO;
}

- (void)callUpdatedByRemote {
    
//    const LinphoneCallParams *current = linphone_call_get_current_params(call);
//    const LinphoneCallParams *remote = linphone_call_get_remote_params(call);
//    /* remote wants to add video */
//    if (linphone_core_video_enabled(lc) && !linphone_call_params_video_enabled(current) &&
//        linphone_call_params_video_enabled(remote) && !linphone_core_get_video_policy(lc)->automatically_accept) {
//        linphone_core_defer_call_update(lc, call);
//        [self displayAskToEnableVideoCall:call];
//    }
//    else if (linphone_call_params_video_enabled(current) && !linphone_call_params_video_enabled(remote)) {
//        [self displayTableCall:animated];
//    }
}

- (void)callPausedByRemote {
    
//    [self displayTableCall:animated];
}

- (void)callError {
    
//    if(self.incomingTextView){
//        self.incomingTextView.text = @"";
//    }
//    //        if(self.outgoingTextLabel){
//    //            self.outgoingTextLabel.text = @"";
//    //        }
//    if (linphone_core_get_calls_nb(lc) <= 2 && !videoShown) {
//        [callTableController maximizeAll];
//    }
//    
//    [timerCallQuality invalidate];
//    timerCallQuality = nil;
//    
//    callQualityImageView.hidden = YES;
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

- (void)setupInCallNewCallView {
    
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

- (void)setupInCallNewCallNotificationView {
    
    [self.secondIncomingCallView hideNotificationWithAnimation:NO completion:nil];
    
    self.secondIncomingCallView.notificationViewActionBlock = ^(LinphoneCall *call) {
        
        // TODO switch between calls
    };
}

- (void)setupInCallOnHoldView {
    
    [self.inCallOnHoldView hideWithAnimation:NO direction:AnimationDirectionLeft completion:nil];
    
    self.inCallOnHoldView.holdViewActionBlock = ^(LinphoneCall *call) {
        
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
