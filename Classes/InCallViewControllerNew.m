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
#import "InCallNewCallView.h"
#import "InCallNewCallNotificationView.h"


#define kBottomButtonsAnimationDuration 0.3f

@interface InCallViewControllerNew ()

@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UIView *videoPreviewView;
@property (weak, nonatomic) IBOutlet UIView *bottomButtonsContainer;
@property (weak, nonatomic) IBOutlet UIView *moreMenuContainer;
@property (weak, nonatomic) IBOutlet UIButton *videoButton;
@property (weak, nonatomic) IBOutlet UIButton *voiceButton;
@property (weak, nonatomic) IBOutlet UIButton *keypadButton;
@property (weak, nonatomic) IBOutlet UIButton *soundButton;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIButton *endCallButton;
@property (weak, nonatomic) IBOutlet InCallNewCallView *inCallNewCallView;
@property (weak, nonatomic) IBOutlet InCallNewCallNotificationView *inCallNewCallNotificationView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inCallNewCallViewBottomConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *endCallBottomConstraint;
@property (nonatomic, strong) NSTimer *bottomButtonsAnimationTimer;

@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *videoPreviewAfterAnimationConstraints;
@property (strong, nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *videoPreviewBeforeAnimationConstraints;

@end


@implementation InCallViewControllerNew

#pragma mark - Life Cycle Methods
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setupBottomButtonsContainer];
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
    
    [self startVideoPreviewAnimaton];
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
            
            NSAssert(0, @"LinphoneCallIncomingReceived: Just need to check this state");
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
            break;
        }
        case LinphoneCallPausing: {
            
            NSAssert(0, @"LinphoneCallPausing: Just need to check this state");
            break;
        }
        case LinphoneCallPaused: {
            
            NSAssert(0, @"LinphoneCallPaused: Just need to check this state");
            break;
        }
        case LinphoneCallResuming: {
            
            NSAssert(0, @"LinphoneCallResuming: Just need to check this state");
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
            
            [[UIManager sharedManager] hideInCallViewControllerAnimated:YES];
            break;
        }
        case LinphoneCallPausedByRemote: {
            
            NSAssert(0, @"LinphoneCallPausedByRemote: Just need to check this state");
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

- (void)showBottomButtons {
    
    [UIView animateWithDuration:kBottomButtonsAnimationDuration
                     animations:^{
                         
                         self.endCallBottomConstraint.constant = 40;
                         [self.bottomButtonsContainer setAlpha:1];
                         [self.endCallButton setAlpha:1];
                         [self.view layoutIfNeeded];
                         
                     } completion:^(BOOL finished) {
                         
                         if (finished) {
                             self.bottomButtonsContainer.tag = 1;
                             [self updateBottomButtonsTimer];
                         }
                     }];
    }

- (void)hideBottomButtons {
    
    if (self.bottomButtonsContainer.tag == 1) {
        
        [UIView animateWithDuration:kBottomButtonsAnimationDuration
                         animations:^{
                             
                             self.endCallBottomConstraint.constant = -(CGRectGetHeight(self.view.frame) - self.bottomButtonsContainer.frame.origin.y) + 40;
                             [self.bottomButtonsContainer setAlpha:0];
                             [self.endCallButton setAlpha:0];
                             [self hideMoreMenu];
                             [self.view layoutIfNeeded];
                         } completion:^(BOOL finished) {
                             
                             if (finished) {
                                 self.bottomButtonsContainer.tag = 0;
                             }
                         }];
    }
}

- (void)showMoreMenu {
    
    self.moreMenuContainer.hidden = NO;
    self.moreMenuContainer.tag = 1;
    [UIView animateWithDuration:kBottomButtonsAnimationDuration
                     animations:^{
                         self.moreMenuContainer.alpha = 1;
                     }];
}

- (void)hideMoreMenu {
    
     self.moreMenuContainer.tag = 0;
    [UIView animateWithDuration:kBottomButtonsAnimationDuration
                     animations:^{
                         self.moreMenuContainer.alpha = 0;
                         [self.moreButton setSelected:NO];
                     }];
}

- (void)updateBottomButtonsTimer {
    
    [self.bottomButtonsAnimationTimer invalidate];
    self.bottomButtonsAnimationTimer = nil;
    self.bottomButtonsAnimationTimer = [NSTimer scheduledTimerWithTimeInterval:3.f
                                                                        target:self
                                                                      selector:@selector(hideBottomButtons)
                                                                      userInfo:nil
                                                                    repeats:NO];
}

- (void)setupBottomButtonsContainer {
    self.bottomButtonsContainer.layer.borderWidth = 0.3f;
    self.bottomButtonsContainer.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.moreMenuContainer.layer.borderWidth = 0.5f;
    self.moreMenuContainer.layer.borderColor = [UIColor lightGrayColor].CGColor;
}

- (void)setupVideoButtonState {
    
    if ([[LinphoneManager instance] isCameraEnabledForCurrentCall]) {
        
        _videoButton.selected = YES;
    }
    else {
        
        _videoButton.selected = NO;
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
        
        _voiceButton.selected = YES;
    }
    else {
        
        _voiceButton.selected = NO;
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
        
        _soundButton.selected = YES;
    }
    else {
        
        _soundButton.selected = NO;
    }
}

- (void)startVideoPreviewAnimaton {
    
    [UIView animateWithDuration:2
                     animations:^{
                         [self hideBottomButtons];
                         self.videoView.userInteractionEnabled = NO;
                         [self.view removeConstraints:self.videoPreviewBeforeAnimationConstraints];
                         [self.view addConstraints:self.videoPreviewAfterAnimationConstraints];
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             self.videoView.userInteractionEnabled = YES;
                         }
                     }];
    
}

- (void)showInCallNewCallView {
    
    self.inCallNewCallView.hidden = NO;
    self.inCallNewCallView.alpha = 1.f;
    [UIView animateWithDuration:1.f
                     animations:^{
                         self.inCallNewCallViewBottomConstraint.constant = 0;
                         [self.view layoutIfNeeded];
                     }];
}

- (void)hideInCallNewCallView {
        [UIView animateWithDuration:1.f
                     animations:^{
                         self.inCallNewCallViewBottomConstraint.constant = -CGRectGetHeight(self.inCallNewCallView.frame);
                         self.inCallNewCallView.alpha = 0.f;
                         [self.view layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         self.inCallNewCallView.hidden = YES;
                     }];
}

- (void)setupInCallNewCallView {
    
    self.inCallNewCallView.messageButtonBlock = ^(UIButton *sender) {
        
    };
    
    self.inCallNewCallView.declineButtonBlock = ^(UIButton *sender) {
        
    };
    
    self.inCallNewCallView.acceptButtonBlock = ^(UIButton *sender) {
        
    };
}

- (void)setupInCallNewCallNotificationView {
    
    self.inCallNewCallNotificationView.notificationViewActionBlock = ^(UIButton *sender) {
        
    };
}

// TODO: Create separated logic for call bar
#pragma mark - Actions Methods
- (IBAction)videoButtonAction:(IncallButton *)sender {

    if ([[LinphoneManager instance] isCameraEnabledForCurrentCall]) {
        [[LinphoneManager instance] disableCameraForCurrentCall];
    }
    else {
        [[LinphoneManager instance] enableCameraForCurrentCall];
    }
    
    [self setupVideoButtonState];
    [self updateBottomButtonsTimer];
}

- (IBAction)voiceButtonAction:(IncallButton *)sender {
    
    if ([[LinphoneManager instance] isMicrophoneEnabled]) {
        [[LinphoneManager instance] disableMicrophone];
    }
    else {
        [[LinphoneManager instance] enableMicrophone];
    }
    
    [self setupMicriphoneButtonState];
    [self updateBottomButtonsTimer];
}

- (IBAction)keypadButtonAction:(IncallButton *)sender {
    
    [sender setSelected:!sender.selected];
    
    [self updateBottomButtonsTimer];
}

- (IBAction)soundButtonAction:(IncallButton *)sender {
    
    if ([[LinphoneManager instance] isSpeakerEnabled]) {
        [[LinphoneManager instance] disableSpeaker];
    }
    else {
        [[LinphoneManager instance] enableSpeaker];
    }
    
    [self setupSpeakerButtonState];
    [self updateBottomButtonsTimer];
}

- (IBAction)moreButtonAction:(IncallButton *)sender {
    
    [sender setSelected:!sender.selected];
    
    [self updateBottomButtonsTimer];
    
    if (self.moreMenuContainer.tag == 0) {
        
        [self showMoreMenu];
    }
    else {
        
        [self hideMoreMenu];
    }
}

- (IBAction)endCallButtonAction:(UIButton *)sender {
    
    [[LinphoneManager instance] terminateCurrentCall];
}

- (IBAction)videoViewAction:(UITapGestureRecognizer *)sender {
    
    if (self.bottomButtonsContainer.tag == 0) {
        
        [self showBottomButtons];
        [self hideInCallNewCallView];
    }
    else {
        
        [self hideBottomButtons];
        [self showInCallNewCallView];
    }
}

- (IBAction)switchCameraButtonAction:(UIButton *)sender {
    
    [[LinphoneManager instance] switchCamera];
    [self updateBottomButtonsTimer];
}

- (IBAction)changeVideoLayoutButtonAction:(UIButton *)sender {
    
    [self updateBottomButtonsTimer];
}

- (void)dealloc {
    [self.bottomButtonsAnimationTimer invalidate];
    self.bottomButtonsAnimationTimer = nil;
}

@end
