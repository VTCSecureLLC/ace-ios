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
#import "InCallDialpadView.h"
#import "RTTMessageModel.h"
#import "BubbleTableViewCell.h"
#import "StatusBar.h"
#import "UICallCellDataNew.h"
#import "CallInfoView.h"
#import "PhoneMainView.h"

#define kBottomButtonsAnimationDuration     0.3f
#define kRTTContainerAnimationDuration      0.3f
#define RTT_MAX_PARAGRAPH_CHAR              250
#define RTT_SOFT_MAX_PARAGRAPH_CHAR         200

#define NO_TEXT     -1
#define RTT         0
#define SIP_SIMPLE  1

typedef NS_ENUM(NSInteger, CallQualityStatus) {
    CallQualityStatusBad,
    CallQualityStatusMedium,
    CallQualityStatusGood,
    CallQualityStatusNone
};


@interface InCallViewControllerNew () <UITableViewDelegate, UITableViewDataSource, BubbleTableViewCellDataSource, UITextInput>

@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UIView *videoPreviewView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *videoPreviewViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *videoPreviewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *videoPreviewWidthConstraint;
@property (weak, nonatomic) IBOutlet CallBarView *callBarView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *callBarViewBottomConstraint;
@property (weak, nonatomic) IBOutlet SecondIncomingCallBarView *secondIncomingCallBarView;
@property (weak, nonatomic) IBOutlet SecondIncomingCallView *secondIncomingCallView;
@property (weak, nonatomic) IBOutlet InCallOnHoldView *inCallOnHoldView;
@property (weak, nonatomic) IBOutlet InCallDialpadView *inCallDialpadView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inCallNewCallViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *holdByRemoteImageView;
@property (weak, nonatomic) IBOutlet UIImageView *cameraImageView;
@property (weak, nonatomic) IBOutlet UIImageView *qualityImageView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSTimer *callQualityTimer;
@property (strong, nonatomic) NSMutableArray *chatEntries;
@property (assign, nonatomic) BOOL isRTTLocallyEnabled;
@property (assign, nonatomic) BOOL isRTTEnabled;
@property (assign, nonatomic) BOOL isChatMode;
@property (assign, nonatomic) BOOL hasStartedStream;
@property (strong, nonatomic) RTTMessageModel *localTextBuffer;
@property (strong, nonatomic) RTTMessageModel *remoteTextBuffer;
@property (assign, nonatomic) int localTextBufferIndex;
@property (assign, nonatomic) int remoteTextBufferIndex;
@property (assign, nonatomic) NSTimeInterval year2037TimeStamp;
@property (assign, nonatomic) NSTimeInterval year2036TimeStamp;
@property (strong, nonatomic) UIColor *localColor;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *rttMessageContainerViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIView *rttMessageContainerView;
@property (weak, nonatomic) IBOutlet UITextView *incomingTextView;
@property (weak, nonatomic) IBOutlet UIButton *closeChatButton;
@property (strong, nonatomic) NSMutableString *msgBuffer;
@property (strong, nonatomic) NSMutableString *minimizedTextBuffer;
@property (weak, nonatomic) IBOutlet StatusBar *statusBar;
@property (weak, nonatomic) IBOutlet CallInfoView *callInfoView;

@end


@implementation InCallViewControllerNew

#pragma mark - Life Cycle Methods
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setupCallInfoView];
    [self setupCallBarView];
    [self setupSecondIncomingCallView];
    [self setupSecondIncomingCallBarView];
    [self setupInCallOnHoldView];
    [self setupInCallDialpadView];
    [self setupRTT];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    [self setupNotifications];
    [self resetSpeakerWithSettings];
    [self resetMicrophoneWithSettings];
    [self setupVideo];
    [self hideRTTContainer];
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

- (void)keyboardWillShow:(NSNotification *)notification {
    if (self.isRTTEnabled) {
        CGRect keyboardFrame =  [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGFloat keyboardPos = keyboardFrame.origin.y;
        
        CGFloat remote_video_delta = (self.videoView.frame.origin.y +
                              self.videoView.frame.size.height) - keyboardPos;
        CGFloat chat_delta = (self.tableView.frame.origin.y + self.tableView.frame.size.height) - keyboardPos;
        
        self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y,
                                          self.tableView.frame.size.width,
                                          self.tableView.frame.size.height - chat_delta);
        [self showLatestMessage];
        CGPoint remote_video_center = CGPointMake(self.videoView.center.x, self.videoView.center.y - remote_video_delta);
        [self.videoView setCenter:remote_video_center];
        
        self.incomingTextView.text = @"";
        [self.incomingTextView setHidden:YES];
        [self.closeChatButton setHidden:YES];
        
        self.isChatMode = YES;
        [self.tableView setHidden:NO];
//        [self hideControls];
        [self sortChatEntriesArray];
        [self.tableView reloadData];
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {
    CGRect keyboardFrame =  [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardPos = keyboardFrame.origin.y;
    CGFloat remote_video_delta = (self.videoView.frame.origin.y +
                          self.videoView.frame.size.height) - keyboardPos;
    
    CGPoint remote_video_center = CGPointMake(self.videoView.center.x, self.videoView.center.y - remote_video_delta);
    [self.videoView setCenter:remote_video_center];
    [self.incomingTextView setHidden:YES];
    [self.closeChatButton setHidden:YES];
    
    self.isChatMode = NO;
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
            
            if (!self.isRTTLocallyEnabled) {
                [[LinphoneManager instance] changeRTTStateForCall:call avtive:NO];
            }
            
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
            [self showQualityIndicator];
            // check video
            if (linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
                const LinphoneCallParams *params = linphone_call_get_current_params(call);
                if(params != NULL){
                    //If H.263, rotate video sideways when in portrait to work around codec limitations
                    if(strcmp(linphone_call_params_get_used_video_codec(params)->mime_type, "H263") == 0){
                        if(linphone_core_get_device_rotation([LinphoneManager getLc]) != 90 &&
                           linphone_core_get_device_rotation([LinphoneManager getLc]) != 270){
                            
                            linphone_core_set_device_rotation([LinphoneManager getLc], 270);
                            linphone_core_update_call([LinphoneManager getLc], call, NULL);
                        }
                    }
                    else{
                        [[PhoneMainView instance] orientationUpdate:self.interfaceOrientation];
                    }
                }
            }
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
            [self.callInfoView stopDataUpdating];
            [self hideQualityIndicator];
            break;
        }
        case LinphoneCallEnd: {
            
            [self.inCallOnHoldView hideWithAnimation:YES direction:AnimationDirectionLeft completion:nil];
            [self.callInfoView stopDataUpdating];
            NSUInteger callsCount = [[LinphoneManager instance] callsCountForLinphoneCore:[LinphoneManager getLc]];
            if (callsCount == 0) {
                [self hideQualityIndicator];
                [[UIManager sharedManager] hideInCallViewControllerAnimated:YES];
            }
            else if (callsCount == 1) {
                LinphoneCall *holdCall = [[LinphoneManager instance] holdCall];
                if (holdCall && [[LinphoneManager instance] callStateForCall:holdCall] == LinphoneCallIncomingReceived) {
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
//    [self setupMicriphoneButtonState];
//    [self setupSpeakerButtonState];
    [self checkRTTForCall:call];
}

- (void)checkHoldCall {
    
    LinphoneCall *holdCall = [[LinphoneManager instance] holdCall];
    if (holdCall) {
        LinphoneCallState holdCallState = [[LinphoneManager instance] callStateForCall:holdCall];
        if (holdCallState != LinphoneCallIncomingReceived && holdCallState != LinphoneCallIdle) {
            [self.inCallOnHoldView fillWithCallModel:holdCall];
            [self.inCallOnHoldView showWithAnimation:YES direction:AnimationDirectionLeft completion:nil];
        }
    }
}

- (void)checkRTTForCall:(LinphoneCall *)call {

    if (self.isRTTLocallyEnabled) {
        if ([[LinphoneManager instance] isChatEnabledForCall:call]) {
            self.isRTTEnabled = YES;
        }
        else {
            self.isRTTEnabled = NO;
        }
    }
    else {
        self.isRTTEnabled = NO;
    }
    self.hasStartedStream = YES;
    
    [self.callBarView changeChatButtonVisibility:!self.isRTTEnabled];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textComposeEvent:)
                                                 name:kLinphoneTextComposeEvent
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)removeNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneVideModeUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneTextComposeEvent object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
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
        
        
        LinphoneCore *lc = [LinphoneManager getLc];
        LinphoneCall *currentCall = linphone_core_get_current_call(lc);
        
   
        if (linphone_call_get_state(currentCall) != LinphoneCallStreamsRunning) {
            return;
        }

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
        
        if (self.inCallDialpadView.viewState == VS_Closed) {
            
            sender.selected = YES;
            [weakSelf.inCallDialpadView showWithAnimation:YES completion:nil];
        }
        else if (self.inCallDialpadView.viewState == VS_Opened) {
            
            sender.selected = NO;
            [weakSelf.inCallDialpadView hideWithAnimation:YES completion:nil];
        }
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
    
    self.callBarView.chatButtonActionHandler = ^(UIButton *sender) {
        
        if (self.isRTTEnabled) {
            self.isChatMode = YES;
            self.tableView.hidden = NO;
            [self.tableView reloadData];
            [self becomeFirstResponder];
        }
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

- (void)showRTTContainer {
    
    self.incomingTextView.hidden = NO;
    self.rttMessageContainerViewBottomConstraint.constant = 120;
    [UIView animateWithDuration:kRTTContainerAnimationDuration
                     animations:^{
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                    
                     }];
}

- (void)hideRTTContainer {
    
    self.rttMessageContainerViewBottomConstraint.constant = -self.rttMessageContainerView.frame.size.height;;
    [UIView animateWithDuration:kRTTContainerAnimationDuration
                     animations:^{
                         [self.view layoutIfNeeded];
                     }
                     completion:^(BOOL finished) {
                         
                         self.incomingTextView.hidden = YES;
                     }];
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

    BOOL isCallAudioEnabled = (![[NSUserDefaults standardUserDefaults] boolForKey:@"mute_microphone_preference"] ||
                                [[NSUserDefaults standardUserDefaults] boolForKey:@"mute_microphone_preference"] == 0);
    
    if (isCallAudioEnabled) {
        [[LinphoneManager instance] enableMicrophone];
        self.callBarView.voiceButtonSelected = NO;
    }
    else {
        [[LinphoneManager instance] disableMicrophone];
        self.callBarView.voiceButtonSelected = YES;
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

    BOOL isSpeakerEnabled = (![[NSUserDefaults standardUserDefaults] boolForKey:@"mute_speaker_preference"] ||
                          [[NSUserDefaults standardUserDefaults] boolForKey:@"mute_speaker_preference"] == 0);
    if (isSpeakerEnabled) {
        linphone_core_set_playback_gain_db([LinphoneManager getLc], 0);
        self.callBarView.soundButtonSelected = NO;
    }
    else {
        linphone_core_set_playback_gain_db([LinphoneManager getLc], -1000.0f);
        self.callBarView.soundButtonSelected = YES;
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

- (void)setupInCallDialpadView {
    
    [self.inCallDialpadView hideWithAnimation:NO completion:nil];
    
    self.inCallDialpadView.oneButtonHandler = ^(UIButton *sender) {
        
    };
    
    self.inCallDialpadView.twoButtonHandler = ^(UIButton *sender) {
        
    };
    
    self.inCallDialpadView.threeButtonHandler = ^(UIButton *sender) {
        
    };
    
    self.inCallDialpadView.fourButtonHandler = ^(UIButton *sender) {
        
    };
    
    self.inCallDialpadView.fiveButtonHandler = ^(UIButton *sender) {
        
    };
    
    self.inCallDialpadView.sixButtonHandler = ^(UIButton *sender) {
        
    };
    
    self.inCallDialpadView.sevenButtonHandler = ^(UIButton *sender) {
        
    };

    self.inCallDialpadView.eightButtonHandler = ^(UIButton *sender) {
        
    };
    
    self.inCallDialpadView.nineButtonHandler = ^(UIButton *sender) {
        
    };
    
    self.inCallDialpadView.starButtonHandler = ^(UIButton *sender) {
        
    };
    
    self.inCallDialpadView.zeroButtonHandler = ^(UIButton *sender) {
        
    };
    
    self.inCallDialpadView.sharpButtonHandler = ^(UIButton *sender) {
        
    };
}

- (void)setupRTT {

    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init] ;
    [dateFormatter setDateFormat:@"yyyy-MM-dd"] ;
    NSDate *date2037 = [dateFormatter dateFromString:@"2037-01-01"];
    NSDate *date2036 = [dateFormatter dateFromString:@"2036-01-01"];
    self.year2037TimeStamp = [date2037 timeIntervalSince1970];
    self.year2036TimeStamp = [date2036 timeIntervalSince1970];
    
    self.chatEntries = [[NSMutableArray alloc] init];
    self.localTextBufferIndex = -1;
    self.remoteTextBufferIndex = -1;
    
    self.localTextBuffer = nil;
    self.remoteTextBuffer = nil;
    self.minimizedTextBuffer = nil;
    
    self.isChatMode = NO;
    if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"enable_rtt"]) {
        self.isRTTLocallyEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_rtt"];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"enable_rtt"];
        self.isRTTLocallyEnabled = YES;
    }
}

- (void)setupCallInfoView {
    
    [self.callInfoView hideWithAnimation:NO completion:nil];
    
    __weak InCallViewControllerNew *weakSelf = self;
    self.statusBar.statusBarActionHandler = ^(UIButton *sender) {
        if (weakSelf.callInfoView.viewState == VS_Closed) {
            [weakSelf.callInfoView showWithAnimation:YES completion:nil];
        }
        else if (weakSelf.callInfoView.viewState == VS_Opened) {
            [weakSelf.callInfoView hideWithAnimation:YES completion:nil];
        }
        
    };
    
    UICallCellDataNew *data = nil;
    LinphoneCall *call = [[LinphoneManager instance] currentCall];
    if (call != NULL) {
        LinphoneCallAppData *appData = (__bridge LinphoneCallAppData *)linphone_call_get_user_pointer(call);
        if (appData != NULL) {
            data = [[UICallCellDataNew alloc] init:call minimized:NO];
        }
    }
    
    self.callInfoView.data = data;
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                duration:(NSTimeInterval)duration {
    
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self updateVideoPreviewFrameWithOrientation:toInterfaceOrientation];
    [self orientationUpdate:toInterfaceOrientation];
    
    if (toInterfaceOrientation == UIDeviceOrientationLandscapeRight || toInterfaceOrientation == UIDeviceOrientationLandscapeLeft) {
        self.callBarViewBottomConstraint.constant = 5;
    }
    else {
        self.callBarViewBottomConstraint.constant = 40;
    }
}

- (void)updateVideoPreviewFrameWithOrientation:(UIInterfaceOrientation)orientation {
    
    CGFloat tempValue = 0;
    if (orientation == UIDeviceOrientationPortrait) {
        tempValue = self.videoPreviewHeightConstraint.constant;
        self.videoPreviewHeightConstraint.constant = self.videoPreviewWidthConstraint.constant;
        self.videoPreviewWidthConstraint.constant = tempValue;
        
        if (self.callBarView.viewState == VS_Opened) {
            self.videoPreviewViewBottomConstraint.constant = 160;
        }
        else if (self.callBarView.viewState == VS_Closed) {
            self.videoPreviewViewBottomConstraint.constant = 20;
        }
    }
    else {
        tempValue = self.videoPreviewWidthConstraint.constant;
        self.videoPreviewWidthConstraint.constant = self.videoPreviewHeightConstraint.constant;
        self.videoPreviewHeightConstraint.constant = tempValue;
        
        if (self.callBarView.viewState == VS_Opened) {
            self.videoPreviewViewBottomConstraint.constant = 120;
        }
        else if (self.callBarView.viewState == VS_Closed) {
            self.videoPreviewViewBottomConstraint.constant = 20;
        }
    }
    
    __weak InCallViewControllerNew *weakSelf = self;
    [UIView animateWithDuration:0.2 animations:^{
        [weakSelf.view layoutIfNeeded];
    }];
}

- (BOOL)canBecomeFirstResponder {
    
    return [[LinphoneManager instance] isChatEnabledForCall:[[LinphoneManager instance] currentCall]] && self.isChatMode;
}

- (void)closeRTTChat {

    self.isChatMode = NO;
    self.tableView.hidden = YES;
    [self resignFirstResponder];
    [self.view endEditing:YES];
}

- (IBAction)singleTapped:(UITapGestureRecognizer *)sender {
    
    if (self.isChatMode) {
        [self closeRTTChat];
    }
    else {
        if (self.callBarView.viewState == VS_Closed) {
            
            [self.callBarView showWithAnimation:YES completion:nil];
        }
        else if (self.callBarView.viewState == VS_Opened) {
            
            [self.callBarView hideWithAnimation:YES completion:nil];
            
            if (self.inCallDialpadView.viewState == VS_Opened) {
                self.callBarView.keypadButtonSelected = NO;
                [self.inCallDialpadView hideWithAnimation:YES completion:nil];
            }
        }
        
        if (self.callInfoView.viewState == VS_Opened) {
            [self.callInfoView hideWithAnimation:YES completion:nil];
        }
    }
}

- (IBAction)closeButtonAction:(id)sender {

    [self hideRTTContainer];
}


#pragma mark - Call Quality
- (void)showQualityIndicator {
    
    _qualityImageView.hidden = NO;
    _callQualityTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                        target:self
                                                      selector:@selector(callQualityTimerBody)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)hideQualityIndicator {
    
    _qualityImageView.hidden = YES;
    [_callQualityTimer invalidate];
    _callQualityTimer = nil;
}

- (void)callQualityTimerBody {
    
    LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
    if (call) {
        CallQualityStatus quality = linphone_call_get_current_quality(call);
        UIImage *image = nil;
        if (quality <= CallQualityStatusBad) {
            
            image = [UIImage imageNamed:@"RTPquality_bad.png"];
        } else if (quality == CallQualityStatusMedium) {
            
            image = [UIImage imageNamed:@"RTPquality_medium.png"];
        } else if (quality < CallQualityStatusMedium) {
            
            image = nil;
        }
        
        [_qualityImageView setImage:image];
    }
}


#pragma mark - BubbleTableViewCellDataSource methods
- (CGFloat)minInsetForCell:(BubbleTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
    {
        return 80.0f;
    }
    
    return 20.0f;
}



#pragma mark - RTT Methods
/* A field that must be implemented for the text protocol */
- (BOOL)hasText {
    
    return YES;
}

/* Text Mode RTT or SIP SIMPLE duplicate with Android*/
- (int)getTextMode {
    //SET TO RTT BY DEFAULT, THIS WILL CHANGE IN GLOBAL SETTINGS.
    int TEXT_MODE=RTT;
    
    //prefs = PreferenceManager.getDefaultSharedPreferences(LinphoneActivity.instance());
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    //String text_mode=prefs.getString(getString(R.string.pref_text_settings_send_mode_key), "RTT");
    NSString* text_mode_string=[defaults stringForKey:@"pref_text_settings_send_mode_key"];
    
    //Log.d("Text Send Mode" + prefs.getString(getString(R.string.pref_text_settings_send_mode_key), "RTT"));
    NSLog(@"Text mode is %@",text_mode_string);
    //    if(text_mode.equals("SIP_SIMPLE")) {
    //        TEXT_MODE=SIP_SIMPLE;
    //    }else if(text_mode.equals("RTT")) {
    //        TEXT_MODE=RTT;
    //
    //    }
    
    if([text_mode_string isEqualToString:@"SIP_SIMPLE"]) {
        TEXT_MODE=SIP_SIMPLE;
    }else if([text_mode_string isEqualToString:@"RTT"]) {
        TEXT_MODE=RTT;
    }
    NSLog(@"Text mode is %d",TEXT_MODE);
    //Log.d("TEXT_MODE ", TEXT_MODE);
    return TEXT_MODE;
}

- (void)sortChatEntriesArray {
    
    if (self.chatEntries.count > 0) {
        NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"modifiedTimeInterval" ascending:YES];
        NSArray *descriptors = [NSArray arrayWithObject:descriptor];
        [self.chatEntries sortUsingDescriptors:descriptors];
    }
    //    NSMutableArray *reverseOrder = [[self.chatEntries sortedArrayUsingDescriptors:descriptors] mutableCopy];
    //    [self.chatEntries removeAllObjects];
    //    for (RTTMessageModel *msgModel in reverseOrder) {
    //        [self.chatEntries addObject:msgModel];
    //    }
}

- (void)showLatestMessage {
    
    if (self.tableView && self.chatEntries) {
        NSUInteger indexArr[] = {self.chatEntries.count-1, 0};
        NSIndexPath *index = [[NSIndexPath alloc] initWithIndexes:indexArr length:2];
        if (index.section >= 0 && index.section < (int)self.chatEntries.count) {
            [self.tableView scrollToRowAtIndexPath:index atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
    }
}


#pragma mark - UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return self.chatEntries.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *CellIdentifier = [[NSString alloc] initWithFormat:@"%ld", (long)indexPath.section];
    BubbleTableViewCell *cell = (BubbleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[BubbleTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = self.tableView.backgroundColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.dataSource = self;
    }
    
    RTTMessageModel *msg = [self.chatEntries objectAtIndex:indexPath.section];
    
    if ([msg.color isEqual:[UIColor colorWithRed:0 green:0.55 blue:0.6 alpha:0.8]]) {
        cell.authorType = BubbleTableViewCellTypeSelf;
        cell.bubbleColor = BubbleColorBlue;
    } else {
        cell.authorType = BubbleTableViewCellTypeOther;
        cell.bubbleColor = BubbleColorGray;
    }
    
    if (msg.msgString.length > 1) {
        
        NSString *firstCharacter = [msg.msgString substringToIndex:1];
        NSString *stringWithoutNewLine = [msg.msgString substringFromIndex:1];
        if ([firstCharacter isEqualToString:@"\n"]) {
            cell.textLabel.text = stringWithoutNewLine;
        } else {
            cell.textLabel.text = msg.msgString;
        }
    } else {
        cell.textLabel.text = msg.msgString;
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate methods
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    return 20;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor clearColor];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    CGSize size;
    
    RTTMessageModel *msg = [self.chatEntries objectAtIndex:indexPath.section];
    
    if ([msg.msgString isEqualToString:@"\n"] || [msg.msgString isEqualToString:@""]) {
        return 17;
    } else {
        
        size = [cell.textLabel.text boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - [self minInsetForCell:nil atIndexPath:indexPath] - 30.0f, CGFLOAT_MAX)
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0f]}
                                                 context:nil].size;
    }
    
    return size.height;
}


#pragma mark Outgoing Text Logic
- (void)createNewLocalChatBuffer:(NSString *)text {
    
    self.localTextBuffer = [[RTTMessageModel alloc] initWithString:text];
    self.localTextBuffer.modifiedTimeInterval = self.year2037TimeStamp;
    self.localTextBuffer.color = [UIColor colorWithRed:0 green:0.55 blue:0.6 alpha:0.8];
    self.localColor = self.localTextBuffer.color;
    self.localTextBufferIndex = (int)self.chatEntries.count;
    [self.chatEntries addObject:self.localTextBuffer];
    if(self.isChatMode){
        [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 20, 0)];
        [self sortChatEntriesArray];
        [self.tableView reloadData];
        [self showLatestMessage];
    }
}

- (void)insertTextIntoBuffer:(NSString *)text {
    
    int asciiCode = [text characterAtIndex:0];
    if (asciiCode == 0) {
        return;
    }
    
    int indx;
    if ((int)self.chatEntries.count == 0) {
        indx = 0;
    } else {
        indx = (int)self.chatEntries.count - 1;
    }
    
    if(!self.localTextBuffer|| [text isEqualToString:@"\n"] ||[text isEqualToString:@"0x2028"]){
        
        RTTMessageModel *currentRttModel = [self.chatEntries lastObject];
        NSString *currentCharacter = currentRttModel.msgString;
        
        
        BOOL enter_pressed=[currentCharacter isEqualToString:@"\n"];
        // if the last one is not mine and it's not a first my messages
        if ([currentRttModel.color isEqual:[UIColor colorWithRed:0 green:0.55 blue:0.6 alpha:0.8]] && (indx != 0) && enter_pressed) {
            return;
        }
        
        if (!enter_pressed) { // do not add row if previous mine is empty
            if (indx == 0) { // if it's the first message
                [self createNewLocalChatBuffer:text];
                return;
            } else {
                self.localTextBuffer = [self.chatEntries objectAtIndex:indx];
            }
            
            // If the previous is my message
            if ([currentRttModel.color isEqual:[UIColor colorWithRed:0 green:0.55 blue:0.6 alpha:0.8]]) {
                self.localTextBuffer.modifiedTimeInterval = [[NSDate new] timeIntervalSince1970];
            }
            
            [self createNewLocalChatBuffer:text];
            return;
        }
        
        
        
    }
    
    if (self.localTextBufferIndex == -1) { // if it's the first message after others
        [self createNewLocalChatBuffer:text];
        return;
    }
    
    self.localTextBuffer = [self.chatEntries objectAtIndex:indx];
    if(self.localTextBuffer){
        if(self.localTextBuffer.msgString.length + text.length >= RTT_MAX_PARAGRAPH_CHAR){
            [self createNewLocalChatBuffer:text];
            return;
        }
        if(self.localTextBuffer.msgString.length + text.length >= RTT_SOFT_MAX_PARAGRAPH_CHAR){
            if([text isEqualToString:@"."] || [text isEqualToString:@"!"] || [text isEqualToString:@"?"] || [text isEqualToString:@","]){
                [self.localTextBuffer.msgString appendString: text];
                [self.chatEntries setObject:self.localTextBuffer atIndexedSubscript:indx];
                [self createNewLocalChatBuffer:@""];
                return;
            }
        }
        [self.localTextBuffer.msgString appendString: text];
        [self.chatEntries setObject:self.localTextBuffer atIndexedSubscript:indx];
        
        if(self.isChatMode){
            [self sortChatEntriesArray];
            [self.tableView reloadData];
            [self showLatestMessage];
        }
    }
}

- (void)backspaceInLocalBuffer {
    
    if(!self.localTextBuffer){
        return;
    }
    self.localTextBuffer = [self.chatEntries objectAtIndex:self.localTextBufferIndex];
    if(self.localTextBuffer){
        if(self.localTextBuffer.msgString.length > 0){
            [self.localTextBuffer removeLast];
            [self.chatEntries setObject:self.localTextBuffer atIndexedSubscript:self.localTextBufferIndex];
            if(self.isChatMode){
                [self sortChatEntriesArray];
                [self.tableView reloadData];
                [self showLatestMessage];
            }
        }
    }
}

/* Called when text is inserted */
- (void)insertText:(NSString *)theText {
    
    // Send a character.
    bool enter_pressed=false;
    unichar c = [theText characterAtIndex:0];
    /* A Line Separator that should be added. */
    if (c == '\n'){
        c = 0x2028;
        enter_pressed=true;
    }
    
    NSLog(@"theText %@",theText);
    NSLog(@"Add characters. %@ Core %s", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
          linphone_core_get_version());
    NSLog(@"insertText %@",self.localTextBuffer.msgString);
    LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
    LinphoneChatRoom* room = linphone_call_get_chat_room(call);
    LinphoneChatMessage* msg = linphone_chat_room_create_message(room, "");
    
    
    int TEXT_MODE=[self getTextMode];
    
    if(TEXT_MODE==RTT){
        linphone_chat_message_put_char(msg, c);
    }else if(TEXT_MODE==SIP_SIMPLE){
        NSLog(@"self.localTextBuffer.msgString %@",self.localTextBuffer.msgString);
        if(enter_pressed){
            NSLog(@"enter_pressed");
            for (int j = 0; j != self.localTextBuffer.msgString.length; j++){
                NSLog(@"Sending char %hu",[self.localTextBuffer.msgString characterAtIndex:j]);
                unichar c1 = [self.localTextBuffer.msgString characterAtIndex:j];
                if (c1 == '\n'){
                    c1 = 0x2028;
                }
                linphone_chat_message_put_char(msg, c1);
            }
        }
    }
    [self insertTextIntoBuffer:theText];
    
}

/* Called when backspace is inserted */
- (void)deleteBackward {
    
    // Send a backspace.
    NSLog(@"Remove one sign. %@ Core %s", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
          linphone_core_get_version());
    
    LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
    LinphoneChatRoom* room = linphone_call_get_chat_room(call);
    LinphoneChatMessage* msg = linphone_chat_room_create_message(room, "");
    linphone_chat_message_put_char(msg, (char)8);
    
    [self backspaceInLocalBuffer];
}


#pragma mark Incoming Text Logic
- (void)insertTextIntoMinimizedTextBuffer:(NSString *)text {
    
    if (!self.isChatMode) {
        if (![text isEqualToString:@""]) {
            if ([self.incomingTextView isHidden] && self.isRTTEnabled) {
                [self showRTTContainer];
                [self.closeChatButton setEnabled:YES];
                
                [self.incomingTextView setHidden:NO];
                [self.closeChatButton setHidden:NO];
                
                self.msgBuffer = [[NSMutableString alloc] initWithString:@""];
                [self.incomingTextView setText:self.msgBuffer];
            }
            
            [self.msgBuffer appendString:text];
            [self.incomingTextView setText:self.msgBuffer];
            if(self.incomingTextView.text.length > 0 ) {
                NSRange range = NSMakeRange(self.incomingTextView.text.length-1, 1);
                [self.incomingTextView scrollRangeToVisible:range];
                
            }
        }
    }
}

- (void)orientationUpdate:(UIInterfaceOrientation)orientation {
    int oldLinphoneOrientation = linphone_core_get_device_rotation([LinphoneManager getLc]);
    int newRotation = 0;
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            newRotation = 0;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            newRotation = 180;
            break;
        case UIInterfaceOrientationLandscapeRight:
            newRotation = 270;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            newRotation = 90;
            break;
        default:
            newRotation = oldLinphoneOrientation;
    }
    if (oldLinphoneOrientation != newRotation) {
        linphone_core_set_device_rotation([LinphoneManager getLc], newRotation);
        LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
        if (call && linphone_call_params_video_enabled(linphone_call_get_current_params(call)) && linphone_call_camera_enabled(call)) {
            // Liz E. - is there any way to trigger the recipient UI to update for the new device rotation wihtout
            //    calling linphone_core_update_call? Not yet is the answer. This is how Linphone docs say to do it.
            // Orientation has changed, must call update call
            
            
            const LinphoneCallParams *params = linphone_call_get_current_params(call);
            if(params != NULL){
                if(strcmp(linphone_call_params_get_used_video_codec(params)->mime_type, "H263") == 0){
                    if(orientation == UIInterfaceOrientationPortrait){
                        linphone_core_set_device_rotation([LinphoneManager getLc], 270);
                    }
                    else if(orientation == UIInterfaceOrientationPortraitUpsideDown){
                        linphone_core_set_device_rotation([LinphoneManager getLc], 90);
                    }
                }
            }
            
            linphone_core_update_call([LinphoneManager getLc], call, NULL);
        }
    }
}

- (void)runonmainthread:(NSString *)text {
    
    [self insertTextIntoRemoteBuffer:text];
}

- (void)runonmainthreadremove {
    
    [self backspaceInRemoteBuffer];
}

- (void)textComposeEvent:(NSNotification *)notif {
    LinphoneChatRoom *room = [[[notif userInfo] objectForKey:@"room"] pointerValue];
    if (room) {
        uint32_t c = linphone_chat_room_get_char(room);
        
        if (c == 0x2028 || c == 10){ // In case of enter.
            [self performSelectorOnMainThread:@selector(runonmainthread:) withObject:@"\n" waitUntilDone:NO];
        }
        else if (c == '\b' || c == 8){ // In case of backspace.
            [self performSelectorOnMainThread:@selector(runonmainthreadremove) withObject:nil waitUntilDone:NO];
        }
        else// In case of everything else except empty.
        {
            NSLog(@"The logging: %d", c);
            NSString * string = [NSString stringWithFormat:@"%C", (unichar)c];
            [self performSelectorOnMainThread:@selector(runonmainthread:) withObject:string waitUntilDone:NO];
        }
    }
}

- (void)createNewRemoteChatBuffer:(NSString *)text {
    
    self.remoteTextBuffer = [[RTTMessageModel alloc] initWithString:text];
    self.remoteTextBuffer.color = [UIColor lightGrayColor];
    self.remoteTextBuffer.modifiedTimeInterval = self.year2036TimeStamp;
    
    self.remoteTextBufferIndex = (int)self.chatEntries.count;
    
    [self.chatEntries addObject:self.remoteTextBuffer];
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 20, 0)];
    [self sortChatEntriesArray];
    [self.tableView reloadData];
    [self showLatestMessage];
    [self insertTextIntoMinimizedTextBuffer:text];
}

- (void)insertTextIntoRemoteBuffer:(NSString *)text {
    
    int asciiCode = [text characterAtIndex:0];
    if (asciiCode == 0) {
        return;
    }
    int index;
    if ((int)self.chatEntries.count == 0) {
        index = 0;
    } else if (self.localTextBufferIndex < 0) { // no local message
        index = (int)self.chatEntries.count - 1;
    } else {
        index = (int)self.chatEntries.count - 2;
    }
    
    if(!self.remoteTextBuffer|| [text isEqualToString:@"\n"] || [text isEqualToString:@"0x2028"]) {
        
        if (![self.remoteTextBuffer.msgString isEqualToString:@"\n"]) { // do not add row if previous is empty
            
            if (index == 0 && ((int)self.chatEntries.count == 0)) {
                [self createNewRemoteChatBuffer:text];
                return;
            }
            
            if (index >= 0) {
                self.remoteTextBuffer = [self.chatEntries objectAtIndex:index];
                self.remoteTextBuffer.modifiedTimeInterval = [[NSDate new] timeIntervalSince1970];
            }
            
            [self createNewRemoteChatBuffer:text];
            
        }
        return;
    }
    
    self.remoteTextBuffer = [self.chatEntries objectAtIndex:index];
    
    if(self.remoteTextBuffer){
        if(self.remoteTextBuffer.msgString.length + text.length >= RTT_MAX_PARAGRAPH_CHAR){
            [self createNewRemoteChatBuffer:text];
            return;
        }
        if(self.remoteTextBuffer.msgString.length + text.length >= RTT_SOFT_MAX_PARAGRAPH_CHAR && self.remoteTextBuffer.msgString.length + text.length < RTT_MAX_PARAGRAPH_CHAR){
            
            if([text isEqualToString:@"."] || [text isEqualToString:@"!"] || [text isEqualToString:@"?"] || [text isEqualToString:@","]){
                [self.remoteTextBuffer.msgString appendString: text];
                [self.chatEntries setObject:self.remoteTextBuffer atIndexedSubscript:index];
                [self createNewRemoteChatBuffer:@""];
                return;
            }
        }
        // [self.remoteTextBuffer.msgString appendString:text];
        self.remoteTextBuffer.msgString = [[self.remoteTextBuffer.msgString stringByAppendingString:text] mutableCopy];
        
        [self.chatEntries setObject:self.remoteTextBuffer atIndexedSubscript:index];
        
        [self sortChatEntriesArray];
        [self.tableView reloadData];
        [self insertTextIntoMinimizedTextBuffer:text];
        [self showLatestMessage];
    }
}

- (void)backspaceInRemoteBuffer {
    
    if(!self.remoteTextBuffer){
        return;
    }
    self.remoteTextBuffer = [self.chatEntries objectAtIndex:self.remoteTextBufferIndex];
    if(self.remoteTextBuffer){
        if(self.remoteTextBuffer.msgString.length > 0){
            [self.remoteTextBuffer removeLast];
            [self.chatEntries setObject:self.remoteTextBuffer atIndexedSubscript:self.remoteTextBufferIndex];
            if(self.isChatMode){
                [self sortChatEntriesArray];
                [self.tableView reloadData];
                [self showLatestMessage];
            }
            else if(!self.isChatMode && self.msgBuffer){
                if (self.msgBuffer.length == 0)
                    return;
                [self.msgBuffer deleteCharactersInRange:NSMakeRange(self.msgBuffer.length -1,1)];
                [self.incomingTextView setText:self.msgBuffer];
            }
        }
    }
}


- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction {
    return UITextWritingDirectionLeftToRight;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position {
    return CGRectZero;
}

- (void)unmarkText {
    
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point {
    return nil;
}

- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction {
    return nil;
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point {
    return nil;
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range {
    return nil;
}

- (NSComparisonResult)comparePosition:(UITextPosition *)position toPosition:(UITextPosition *)other {
    return NSOrderedDescending;
}

- (void)dictationRecognitionFailed {
}

- (void)dictationRecordingDidEnd {
    //    LinphoneCall *c = linphone_core_get_current_call([LinphoneManager getLc]);
    //    if (c && linphone_call_get_state(c) == LinphoneCallStreamsRunning) {
    //
    //    }
}

- (CGRect)firstRectForRange:(UITextRange *)range {
    return CGRectZero;
}

- (CGRect)frameForDictationResultPlaceholder:(id)placeholder {
    return CGRectZero;
}

- (void)insertDictationResult:(NSArray *)dictationResult {
    LinphoneCall *c = linphone_core_get_current_call([LinphoneManager getLc]);
    if (c && linphone_call_get_state(c) == LinphoneCallStreamsRunning) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        //String text_mode=prefs.getString(getString(R.string.pref_text_settings_send_mode_key), "RTT");
        [defaults setObject:@"SIP_SIMPLE" forKey:@"pref_text_settings_send_mode_key"];
        [defaults synchronize];
        for(UIDictationPhrase *phrase in dictationResult){
            [self insertText:[phrase text]];
        }
        [self insertText:@"\n"];
        [defaults setObject:@"RTT" forKey:@"pref_text_settings_send_mode_key"];
        [defaults synchronize];
    }
}

- (id)insertDictationResultPlaceholder {
    return @"";
}

- (NSInteger)offsetFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition {
    return 0;
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset {
    return nil;
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position offset:(NSInteger)offset {
    return nil;
}

- (UITextPosition *)positionWithinRange:(UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction {
    return nil;
}

- (void)removeDictationResultPlaceholder:(id)placeholder willInsertResult:(BOOL)willInsertResult {
}

- (void)replaceRange:(UITextRange *)range withText:(NSString *)text {
}

- (NSArray *)selectionRectsForRange:(UITextRange *)range {
    return nil;
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange *)range {
}

- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange {
}

- (NSString *)textInRange:(UITextRange *)range {
    
    return @"";
}

- (UITextRange *)textRangeFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition {
    
    return [[UITextRange alloc] init];
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    
    self.isChatMode = YES;
    [self becomeFirstResponder];
    return NO;
}

@end
