//
//  InCallViewControllerNew.m
//  linphone
//
//  Created by Hrachya Stepanyan on 3/1/16.
//
//

#import "InCallViewControllerNew.h"
#import "LinphoneManager.h"
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
#import "CRToast.h"
#include <math.h>
#import "ReasonErrorHandler.h"

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


@interface InCallViewControllerNew () <UITableViewDelegate, UITableViewDataSource, BubbleTableViewCellDataSource, UITextInput> {
    NSString *declinedMessage;
}

@property (weak, nonatomic) IBOutlet UILabel *ringCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *callStateLabel;
@property (weak, nonatomic) IBOutlet UIView *viewCallDeclinedWithMessage;
@property (weak, nonatomic) IBOutlet UILabel *callDeclineMessageLabel;

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
@property (weak, nonatomic) IBOutlet UIView *inCallDialpadViewContainer;
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
@property (strong) NSTimer *ringIncrementTimer;
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
    [self checkRTT];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    declinedMessage = nil;
    
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
    [self orientationUpdate:self.interfaceOrientation];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [self removeNotifications];
    [self resetVideoViews];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[ReasonErrorHandler sharedInstance] closeErrorView];
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
    [self callUpdate:linphoneCall state:linphoneCallState animated:TRUE notification:notification];
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
        
//        CGFloat remote_video_delta = (self.videoView.frame.origin.y +
//                              self.videoView.frame.size.height) - keyboardPos;
        CGFloat chat_delta = (self.tableView.frame.origin.y + self.tableView.frame.size.height) - keyboardPos;
        
        self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y,
                                          self.tableView.frame.size.width,
                                          self.tableView.frame.size.height - chat_delta);
        //[self showLatestMessage];
    //    CGPoint remote_video_center = CGPointMake(self.videoView.center.x, self.videoView.center.y - remote_video_delta);
      //  [self.videoView setCenter:remote_video_center];
        
        self.incomingTextView.text = @"";
        [self.incomingTextView setHidden:YES];
        [self.closeChatButton setHidden:YES];
        
        self.isChatMode = YES;
        [self.tableView setHidden:NO];
        //[self hideControls];
       // [self sortChatEntriesArray];
        [self.tableView reloadData];
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {
    CGRect keyboardFrame =  [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardPos = keyboardFrame.origin.y;
    CGFloat chat_delta = (self.tableView.frame.origin.y + self.tableView.frame.size.height) + keyboardPos;
    
    
    self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y,
                                      self.tableView.frame.size.width,
                                      self.tableView.frame.size.height + chat_delta);
//    CGFloat remote_video_delta = (self.videoView.frame.origin.y +
//                          self.videoView.frame.size.height) - keyboardPos;
//    
//    CGPoint remote_video_center = CGPointMake(self.videoView.center.x, self.videoView.center.y - remote_video_delta);
//    [self.videoView setCenter:remote_video_center];
    [self.incomingTextView setHidden:YES];
    [self.closeChatButton setHidden:YES];
    
    self.isChatMode = NO;
}


- (void)textReceived:(NSNotification *)notif {
    
    NSDictionary *messageInfo = notif.userInfo;
    NSString *userName = [messageInfo objectForKey:@"userName"];
    NSString *message = [messageInfo objectForKey:@"simpleMessage"];
    
    if ([message hasPrefix:CALL_DECLINE_PREFIX]) {
        NSString *caller_username = [[LinphoneManager instance] getLastCalledUsername];

        if (caller_username && ![caller_username isEqualToString:userName]) {
            return;
        }
        
        [self stopRingCount];

        declinedMessage = [message substringFromIndex:CALL_DECLINE_PREFIX.length];
        
        UIFont *smallFont = [UIFont systemFontOfSize:18];
        NSDictionary *smallDict = [NSDictionary dictionaryWithObject:smallFont forKey:NSFontAttributeName];
        NSMutableAttributedString *aAttrString = [[NSMutableAttributedString alloc] initWithString:@"Call declined with message \n" attributes:smallDict];
        NSDictionary *textColor = [NSDictionary dictionaryWithObjectsAndKeys:[UIColor lightGrayColor], NSForegroundColorAttributeName, nil];
        [aAttrString addAttributes:textColor range:NSMakeRange(0, @"Call declined with message \n".length)];
        
        UIFont *bigFont = [UIFont systemFontOfSize:37];
        NSDictionary *verdanaDict = [NSDictionary dictionaryWithObject:bigFont forKey:NSFontAttributeName];
        NSMutableAttributedString *vAttrString = [[NSMutableAttributedString alloc] initWithString:declinedMessage attributes:verdanaDict];
        
        [aAttrString appendAttributedString:vAttrString];
        
        self.viewCallDeclinedWithMessage.hidden = YES;
        self.callDeclineMessageLabel.hidden = YES;
        self.callDeclineMessageLabel.attributedText = aAttrString;
        
        [UIView animateKeyframesWithDuration:1.0 delay:0.0 options:UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat animations:^{
            self.viewCallDeclinedWithMessage.alpha = 0;
        } completion:nil];
//    } else {
//        NSString *messageFullText = [[userName stringByAppendingString:@": "] stringByAppendingString:message];
//        NSMutableDictionary *options = [@{
//                                          kCRToastTextKey : messageFullText,
//                                          kCRToastTextAlignmentKey : @(0),
//                                          kCRToastBackgroundColorKey : [UIColor colorWithRed:228.0/255.0 green:92.0/255.0 blue:50.0/255.0 alpha:1.0],
//                                          kCRToastAnimationInTypeKey : @(0),
//                                          kCRToastAnimationOutTypeKey : @(0),
//                                          kCRToastAnimationInDirectionKey : @(0),
//                                          kCRToastAnimationOutDirectionKey : @(0),
//                                          kCRToastImageAlignmentKey : @(0),
//                                          kCRToastNotificationPreferredPaddingKey : @(0),
//                                          kCRToastNotificationPresentationTypeKey : @(0),
//                                          kCRToastNotificationTypeKey : @(1),
//                                          kCRToastTimeIntervalKey : @(3),
//                                          kCRToastUnderStatusBarKey : @(0)} mutableCopy];
//        options[kCRToastImageKey] = [UIImage imageNamed:@"app_icon_29.png"];
//        options[kCRToastImageAlignmentKey] = @(0);
//        options[kCRToastInteractionRespondersKey] = @[[CRToastInteractionResponder interactionResponderWithInteractionType:CRToastInteractionTypeAll
//                                                                                                      automaticallyDismiss:YES
//                                                                                                                     block:^(CRToastInteractionType interactionType){}]];
//        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
//            [CRToastManager dismissNotification:YES];
//            [CRToastManager showNotificationWithOptions:options
//                                        completionBlock:^{}];
//        }
    }
}

#pragma mark - Private Methods
- (void)callUpdate:(LinphoneCall *)call state:(LinphoneCallState)state animated:(BOOL)animated notification:(NSNotification *)notification {
    
//    LinphoneCore *lc = [LinphoneManager getLc];
//    if (hiddenVolume) {
//        [[PhoneMainView instance] setVolumeHidden:FALSE];
//        hiddenVolume = FALSE;
//    }
    
    switch (state) {
        case LinphoneCallIdle: {
            break;
        }
        case LinphoneCallIncomingReceived: {
            [self incomingReceivedWithCall:call];
            [self closeRTTChat];
            
            [[LinphoneManager instance] changeRTTStateForCall:call avtive:self.isRTTLocallyEnabled];
           
            // This is second call
            break;
        }
        case LinphoneCallOutgoingInit: {
            
            if (!self.isRTTLocallyEnabled) {
                [[LinphoneManager instance] changeRTTStateForCall:call avtive:NO];
            }
            break;
        }
        case LinphoneCallOutgoingRinging:
        {
            self.callStateLabel.text = @"Ringing...";
            self.callStateLabel.hidden = NO;
            
            if(!self.ringIncrementTimer){
                [self stopRingCount];
                self.ringIncrementTimer = [NSTimer scheduledTimerWithTimeInterval:[[LinphoneManager instance] lpConfigFloatForKey:@"outgoing_ring_duration" forSection:@"vtcsecure"]
                                                                           target:self
                                                                         selector:@selector(displayIncrementedRingCount)
                                                                         userInfo:nil
                                                                          repeats:YES];
                [self.ringIncrementTimer fire];
            }
            break;
        }
        case LinphoneCallOutgoingProgress: {

            self.callStateLabel.text = @"Connecting...";
            self.callStateLabel.hidden = NO;
            
            break;
        }
            
        case LinphoneCallOutgoingEarlyMedia: {
             [self stopRingCount];
            break;
        }
        case LinphoneCallConnected: {
            [self stopRingCount];
            break;
        }
        case LinphoneCallStreamsRunning: {
//            [self stopRingCount];
            _holdByRemoteImageView.hidden = YES;
            // Show first call in hold view
            
            [self checkHoldCall];
            [self showQualityIndicator];

            // check video
            if (linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
                const LinphoneCallParams *params = linphone_call_get_current_params(call);
                if(params != NULL){
                    LinphonePayloadType *payloadType = (LinphonePayloadType *)linphone_call_params_get_used_video_codec(params);
                    if (payloadType != NULL) {
                        const char *mimeType = payloadType->mime_type;
                        if (mimeType != NULL && strlen(mimeType)) {
                            //If H.263, rotate video sideways when in portrait to work around codec limitations
                            if(strcmp(mimeType, "H263") == 0) {
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
                }
            }
            [self checkRTT];
            if(self.chatEntries && self.chatEntries.count > 0){
                NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init] ;
                [dateFormatter setDateFormat:@"yyyy-MM-dd"] ;
                NSDate *date2037 = [dateFormatter dateFromString:@"2037-01-01"];
                NSDate *date2036 = [dateFormatter dateFromString:@"2036-01-01"];
                self.year2037TimeStamp = [date2037 timeIntervalSince1970];
                self.year2036TimeStamp = [date2036 timeIntervalSince1970];
                
                self.chatEntries = [[NSMutableArray alloc] init];
                self.localTextBufferIndex = 0;
                self.remoteTextBufferIndex = 0;
                
                self.localTextBuffer = nil;
                self.remoteTextBuffer = nil;
                self.minimizedTextBuffer = nil;
                
                [self.tableView setContentInset:UIEdgeInsetsMake(80, 0, 100, 0)];
            }

            self.inCallOnHoldView.userInteractionEnabled = YES;
            
            
                        const LinphoneAddress *remoteAddr = linphone_call_get_remote_address(call);
            
                        if(strcmp(linphone_address_get_username(remoteAddr), "911") == 0){
                            [[LinphoneManager instance] enableMicrophone];
                            [[LinphoneManager instance] enableCameraForCurrentCall];
                            [self setupMicriphoneButtonState];
                            [self setupVideoButtonState];
                        }
            break;
        }
        case LinphoneCallPausing: {
             [self stopRingCount];
            break;
        }
        case LinphoneCallPaused: {
            [self stopRingCount];
            [self updateCallStateWithButtonsState];
            break;
        }
        case LinphoneCallResuming: {
             [self stopRingCount];
            break;
        }
        case LinphoneCallRefered: {
             [self stopRingCount];
            break;
        }
        case LinphoneCallError: {
            NSString *message = [notification.userInfo objectForKey:@"message"];
            [self displayCallError:call message:message];
            [self stopRingCount];
            [self.callInfoView stopDataUpdating];
            [self hideQualityIndicator];
            break;
        }
        case LinphoneCallEnd: {
            [self stopRingCount];
            
            [self.inCallOnHoldView hideWithAnimation:YES direction:AnimationDirectionLeft completion:nil];
            [self.callInfoView stopDataUpdating];
            NSUInteger callsCount = [[LinphoneManager instance] callsCountForLinphoneCore:[LinphoneManager getLc]];
            if (callsCount == 0) {
                
                void (^endCall)(void) = ^(void) {
                    [self hideQualityIndicator];
                    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"fromEvents", nil];
                    [self performSelector:@selector(closeCallWindow:) withObject:dict afterDelay:1.0];
                };
                
                
                LinphoneReason callReason = linphone_call_get_reason(call);
                if (callReason == LinphoneReasonDeclined) {
                    
                    [[ReasonErrorHandler sharedInstance] showErrorForLinphoneReason:callReason];
                    [ReasonErrorHandler sharedInstance].popUpViewWillDismissComplitionBlock = ^(ReasonError *error){
                        endCall();
                    };
                }
                else {
                    endCall();
                }
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
            
            break;
        }
        case LinphoneCallIncomingEarlyMedia: {
             [self stopRingCount];
            break;
        }
        case LinphoneCallUpdating: {
             [self stopRingCount];
            break;
        }
        case LinphoneCallReleased: {
            [self stopRingCount];
            [self hideSecondIncomingCallUI];
            break;
        }
        case LinphoneCallEarlyUpdatedByRemote: {
             [self stopRingCount];
            break;
        }
        case LinphoneCallEarlyUpdating: {
             [self stopRingCount];
            break;
        }
        default:
            break;
    }
    
    [self setupVideoButtonState];
//    [self setupMicriphoneButtonState];
//    [self setupSpeakerButtonState];
    [self checkRTT];
}

- (void) closeCallWindow:(NSDictionary*)dict {
    LinphoneCore *lc = [LinphoneManager getLc];
    BOOL fromEvents = [[dict objectForKey:@"fromEvents"] boolValue];
    
    if (!linphone_core_get_calls(lc)) {
        if (!fromEvents) {
            [self close];
        } else {
            if (declinedMessage) {
                NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"fromEvents", nil];
                [self performSelector:@selector(closeCallWindow:) withObject:dict afterDelay:3.0];
            } else {
                [self close];
            }
        }
    }
}

- (void)close {
    
    [[UIManager sharedManager] hideInCallViewControllerAnimated:YES];
    self.callDeclineMessageLabel.hidden = YES;
    self.viewCallDeclinedWithMessage.hidden = YES;
}

- (void)displayCallError:(LinphoneCall *)call message:(NSString *)message {
    
    [self.callBarView disableCallOptions];
    [self.statusBar setUserInteractionEnabled:NO];
    [[ReasonErrorHandler sharedInstance] showErrorForLinphoneReason:linphone_call_get_reason(call)];
    [ReasonErrorHandler sharedInstance].popUpViewWillDismissComplitionBlock = ^(ReasonError *error) {
        [self close];
    };
}

- (void)checkHoldCall {
    
    LinphoneCall *holdCall = [[LinphoneManager instance] holdCall];
    if (holdCall) {
        LinphoneCallState holdCallState = [[LinphoneManager instance] callStateForCall:holdCall];
        if (holdCallState != LinphoneCallIncomingReceived && holdCallState != LinphoneCallIdle) {
            [self.inCallOnHoldView fillWithCallModel:holdCall];
            [self.inCallOnHoldView showWithAnimation:YES direction:AnimationDirectionLeft completion:nil];
        }
        else {
            
        }
    }
    
}

- (void)checkRTT {
    
    LinphoneCall *call = [[LinphoneManager instance] currentCall];
    if (call != NULL) {
        if ([[LinphoneManager instance] callStateForCall:call] == LinphoneCallStreamsRunning) {
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
        }
        else {
            self.isRTTEnabled = NO;
        }
    }
    else {
        self.isRTTEnabled = NO;
    }
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textReceived:)
                                                 name:kLinphoneTextReceived
                                               object:nil];
}

- (void)removeNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneVideModeUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneTextComposeEvent object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneTextReceived object:nil];
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

- (void)displayIncrementedRingCount {
    self.ringCountLabel.hidden = NO;

    self.callStateLabel.hidden = NO;
    int duration =[[LinphoneManager instance] lpConfigFloatForKey:@"outgoing_ring_duration" forSection:@"vtcsecure"];
    [UIView transitionWithView:self.ringCountLabel
                      duration:duration
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                       
                    }
                    completion:^(BOOL finished) {
                          self.ringCountLabel.text = [@(self.ringCountLabel.text.intValue + 1) stringValue];
                    }];
}

- (void)stopRingCount {
    self.ringCountLabel.hidden = YES;
    self.callStateLabel.hidden = YES;
    self.ringCountLabel.text = @"1";
    if(self.ringIncrementTimer){
        [self.ringIncrementTimer invalidate];
        self.ringIncrementTimer = nil;
    }
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
        const LinphoneAddress *remoteAddr = linphone_call_get_remote_address(currentCall);
        
        if(strcmp(linphone_address_get_username(remoteAddr), "911") == 0){
            [[LinphoneManager instance] enableCameraForCurrentCall];
            [self setupVideoButtonState];
            return;
        }
   
        if (linphone_call_get_state(currentCall) != LinphoneCallStreamsRunning) {
            return;
        }

        const char *currentCamId = (char *)linphone_core_get_video_device([LinphoneManager getLc]);
        
        if (strcmp(currentCamId, "StaticImage: Static picture") != 0) {
            [[LinphoneManager instance] disableCameraForCurrentCall];
        }else {
            [[LinphoneManager instance] enableCameraForCurrentCall];
        }
        
        [weakSelf setupVideoButtonState];
    };
    
    self.callBarView.voiceButtonActionHandler = ^(UIButton *sender) {
        LinphoneCore *lc = [LinphoneManager getLc];
        LinphoneCall *currentCall = linphone_core_get_current_call(lc);
        const LinphoneAddress *remoteAddr = linphone_call_get_remote_address(currentCall);
        
        if(strcmp(linphone_address_get_username(remoteAddr), "911") == 0){
            [[LinphoneManager instance] enableMicrophone];
            [self setupMicriphoneButtonState];
            return;
        }
        
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
            
            self.inCallDialpadViewContainer.hidden = NO;
            sender.selected = YES;
            [weakSelf.inCallDialpadView showWithAnimation:YES completion:nil];
        }
        else if (self.inCallDialpadView.viewState == VS_Opened) {
            
            sender.selected = NO;
            self.inCallDialpadViewContainer.hidden = YES;
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
        [sender setEnabled:NO];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            sleep(3);
            [sender setEnabled:YES];
        });
       
    };

    self.callBarView.switchSpeakerButtonActionHandler = ^(UIButton *sender) {
        
        [[LinphoneManager instance] setSpeakerEnabled:![[LinphoneManager instance] isSpeakerEnabled]];
    };
    
    self.callBarView.changeVideoLayoutButtonActionHandler = ^(UIButton *sender) {
        
    };
    
    self.callBarView.chatButtonActionHandler = ^(UIButton *sender) {
        
        if (self.isRTTEnabled) {
            [self hideRTTContainer];
            self.isChatMode = YES;
            self.tableView.hidden = NO;
            [self.tableView reloadData];
            [self becomeFirstResponder];
        }
    };
    
    self.callBarView.endCallButtonActionHandler = ^(UIButton *sender) {
        
        [[LinphoneManager instance] terminateCurrentCall];
        if(linphone_core_get_calls_nb([LinphoneManager getLc]) == 0){
            [self close];
        }
    };
}

- (void)updateCallStateWithButtonsState {

    //Speaker
    if (self.callBarView.isSoundButtonSelected && [[LinphoneManager instance] isSpeakerEnabled]) {
        [[LinphoneManager instance] disableSpeaker];
    }
    
    //Microphone
    if (self.callBarView.isVoiceButtonSelected && [[LinphoneManager instance] isMicrophoneEnabled]) {
        [[LinphoneManager instance] disableMicrophone];
    }
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
    if(linphone_core_get_current_call([LinphoneManager getLc])){
        if(linphone_call_get_state(linphone_core_get_current_call([LinphoneManager getLc])) != LinphoneCallStreamsRunning){
            self.callBarView.videoButtonSelected = NO;
            return;
        }
    }
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
    
    __weak InCallViewControllerNew *weakSelf = self;
    self.inCallOnHoldView.holdViewActionBlock = ^(LinphoneCall *call) {
        weakSelf.inCallOnHoldView.userInteractionEnabled = NO;
        [weakSelf.inCallOnHoldView fillWithCallModel:[[LinphoneManager instance] currentCall]];
        [[LinphoneManager instance] resumeCall:call];
    };
}

- (void)setupInCallDialpadView {
    
    self.inCallDialpadViewContainer.hidden = YES;
    [self.inCallDialpadView hideWithAnimation:NO completion:nil];

    const int dtmf_length = 250;
    
    self.inCallDialpadView.oneButtonHandler = ^(UIButton *sender) {
        linphone_core_play_dtmf([LinphoneManager getLc], '1', dtmf_length);
        linphone_call_send_dtmf([[LinphoneManager instance] currentCall], '1');
    };
    
    self.inCallDialpadView.twoButtonHandler = ^(UIButton *sender) {
        linphone_core_play_dtmf([LinphoneManager getLc], '2', dtmf_length);
        linphone_call_send_dtmf([[LinphoneManager instance] currentCall], '2');
    };
    
    self.inCallDialpadView.threeButtonHandler = ^(UIButton *sender) {
        linphone_core_play_dtmf([LinphoneManager getLc], '3', dtmf_length);
        linphone_call_send_dtmf([[LinphoneManager instance] currentCall], '3');
    };
    
    self.inCallDialpadView.fourButtonHandler = ^(UIButton *sender) {
        linphone_core_play_dtmf([LinphoneManager getLc], '4', dtmf_length);
        linphone_call_send_dtmf([[LinphoneManager instance] currentCall], '4');
    };
    
    self.inCallDialpadView.fiveButtonHandler = ^(UIButton *sender) {
        linphone_core_play_dtmf([LinphoneManager getLc], '5', dtmf_length);
        linphone_call_send_dtmf([[LinphoneManager instance] currentCall], '5');
    };
    
    self.inCallDialpadView.sixButtonHandler = ^(UIButton *sender) {
        linphone_core_play_dtmf([LinphoneManager getLc], '6', dtmf_length);
        linphone_call_send_dtmf([[LinphoneManager instance] currentCall], '6');
    };
    
    self.inCallDialpadView.sevenButtonHandler = ^(UIButton *sender) {
        linphone_core_play_dtmf([LinphoneManager getLc], '7', dtmf_length);
        linphone_call_send_dtmf([[LinphoneManager instance] currentCall], '7');
    };

    self.inCallDialpadView.eightButtonHandler = ^(UIButton *sender) {
        linphone_core_play_dtmf([LinphoneManager getLc], '8', dtmf_length);
        linphone_call_send_dtmf([[LinphoneManager instance] currentCall], '8');
    };
    
    self.inCallDialpadView.nineButtonHandler = ^(UIButton *sender) {
        linphone_core_play_dtmf([LinphoneManager getLc], '9', dtmf_length);
        linphone_call_send_dtmf([[LinphoneManager instance] currentCall], '9');
    };
    
    self.inCallDialpadView.starButtonHandler = ^(UIButton *sender) {
        linphone_core_play_dtmf([LinphoneManager getLc], '*', dtmf_length);
        linphone_call_send_dtmf([[LinphoneManager instance] currentCall], '*');
    };
    
    self.inCallDialpadView.zeroButtonHandler = ^(UIButton *sender) {
        linphone_core_play_dtmf([LinphoneManager getLc], '0', dtmf_length);
        linphone_call_send_dtmf([[LinphoneManager instance] currentCall], '0');
    };
    
    self.inCallDialpadView.sharpButtonHandler = ^(UIButton *sender) {
        linphone_core_play_dtmf([LinphoneManager getLc], '#', dtmf_length);
        linphone_call_send_dtmf([[LinphoneManager instance] currentCall], '#');
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
    self.localTextBufferIndex = 0;
    self.remoteTextBufferIndex = 0;
    
    self.localTextBuffer = nil;
    self.remoteTextBuffer = nil;
    self.minimizedTextBuffer = nil;
    
    UITapGestureRecognizer *singleFingerTappedIncomingChat = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openChatMessage:)];
    singleFingerTappedIncomingChat.numberOfTouchesRequired = 1;
    singleFingerTappedIncomingChat.numberOfTapsRequired = 1;
    [singleFingerTappedIncomingChat setCancelsTouchesInView:NO];
    [self.incomingTextView addGestureRecognizer:singleFingerTappedIncomingChat];
    
    UIFont *rttFont = [self fontNameForFontFamily:[[DefaultSettingsManager sharedInstance] fontFamilyName]
                                         withSize:16];
    if (rttFont) {
        self.incomingTextView.font = rttFont;
    }
    
    [self.tableView setContentInset:UIEdgeInsetsMake(80, 0, 100, 0)];
    
    self.isChatMode = NO;
    if ([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"enable_rtt"]) {
        self.isRTTLocallyEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_rtt"];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"enable_rtt"];
        self.isRTTLocallyEnabled = YES;
    }
}

-(void) openChatMessage: (UITapGestureRecognizer *)sender{
    if (self.isRTTEnabled) {
        [self hideRTTContainer];
        self.isChatMode = YES;
        self.tableView.hidden = NO;
        [self.tableView reloadData];
        [self becomeFirstResponder];
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
    
    self.callDeclineMessageLabel.hidden = YES;
    self.viewCallDeclinedWithMessage.hidden = YES;
    
//    if (![[LinphoneManager instance] currentCall]) {
//        [self close];
//    }
    
    if (self.isChatMode) {
        [self closeRTTChat];
    }
    else {
        if (self.callBarView.viewState == VS_Closed) {
            if(self.statusBar.hidden){
                [self.statusBar setHidden:NO];
            }
            [self.callBarView showWithAnimation:YES completion:nil];
            
        }
        else if (self.callBarView.viewState == VS_Opened) {
            
            [self.callBarView hideWithAnimation:YES completion:nil];
            
            if (self.inCallDialpadView.viewState == VS_Opened) {
                self.callBarView.keypadButtonSelected = NO;
                self.inCallDialpadViewContainer.hidden = YES;
                [self.inCallDialpadView hideWithAnimation:YES completion:nil];
            }
            
            if(!self.statusBar.hidden){
                [self.statusBar setHidden:YES];
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
    
//    LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
//    if (call) {
//        CallQualityStatus quality = linphone_call_get_current_quality(call);
//        UIImage *image = nil;
//        if (quality <= CallQualityStatusBad) {
//            
//            image = [UIImage imageNamed:@"RTPquality_bad.png"];
//        } else if (quality == CallQualityStatusMedium) {
//            
//            image = [UIImage imageNamed:@"RTPquality_medium.png"];
//        } else if (quality < CallQualityStatusMedium) {
//            
//            image = nil;
//        }
//        
//        [_qualityImageView setImage:image];
//    }
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
            [self.tableView scrollToRowAtIndexPath:index atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    }
}

- (UIFont *)fontNameForFontFamily:(NSString *)fontFamilyName withSize:(CGFloat)fontSize{
    
    NSArray *fontNames = [UIFont fontNamesForFamilyName:fontFamilyName];
    NSPredicate *mediumFontPredicate = [NSPredicate predicateWithFormat:@"self CONTAINS[cd] 'medium'"];
    
    NSArray *filteredFontNames = [fontNames filteredArrayUsingPredicate:mediumFontPredicate];
    UIFont *font;
    if(filteredFontNames.count > 0) {
        font = [UIFont fontWithName:[filteredFontNames firstObject] size:fontSize];
    }
    else {
        font = [UIFont fontWithName:[fontNames firstObject] size:fontSize];
    }
    
    return font;
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return self.chatEntries.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *CellIdentifier = @"ChatCell";
    BubbleTableViewCell *cell = (BubbleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[BubbleTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = self.tableView.backgroundColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.dataSource = self;
        
        NSString *fontFamilyName = [[DefaultSettingsManager sharedInstance] fontFamilyName];
        UIFont *cellFont = [self fontNameForFontFamily:fontFamilyName withSize:16];
        if (cellFont) {
            cell.textLabel.font = cellFont;
        }
    }
    RTTMessageModel *msg;
    @try{
        if(self.chatEntries.count > 0)
        msg = [self.chatEntries objectAtIndex:indexPath.section];
    }
    @catch(NSError *e){
        NSLog(@"%@",[e debugDescription]);
        return cell;
    }
    
    if ([msg.color isEqual:[UIColor colorWithRed:0 green:0.55 blue:0.6 alpha:0.8]]) {
        cell.authorType = BubbleTableViewCellTypeSelf;
        cell.bubbleColor = BubbleColorBlue;
        cell.bubbleView.tintColor = [UIColor colorWithRed:5.0/255.0 green:8.0/255.0 blue:47.0/255.0 alpha:0.8];
    } else {
        cell.authorType = BubbleTableViewCellTypeOther;
        cell.bubbleColor = BubbleColorGray;
        cell.bubbleView.tintColor = [UIColor colorWithRed:225.0/255.0 green:225.0/255.0 blue:225.0/255.0 alpha:0.8];
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
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"force508"]) {
        if (cell.authorType == BubbleTableViewCellTypeSelf) {
            cell.bubbleView.tintColor = [UIColor blackColor];
            cell.textLabel.textColor = [UIColor whiteColor];
        } else {
            cell.textLabel.textColor = [UIColor blackColor];
        }
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate methods
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor clearColor];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    CGSize size;
    
    RTTMessageModel *msg;
    @try{
        if(self.chatEntries.count > 0)
            msg = [self.chatEntries objectAtIndex:indexPath.section];
    }
    @catch(NSError *e){
        NSLog(@"%@",[e debugDescription]);
        return 16;
    }
    
    if ([msg.msgString isEqualToString:@"\n"] || [msg.msgString isEqualToString:@""]) {
        return 16;
    } else {
        
        size = [cell.textLabel.text boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - [self minInsetForCell:nil atIndexPath:indexPath] - 30.0f, CGFLOAT_MAX)
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16.0f]}
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
        [self.tableView setContentInset:UIEdgeInsetsMake(80, 0, 100, 0)];
        //[self sortChatEntriesArray];
        [self.tableView reloadData];
        [self showLatestMessage];
    }
}
CGSize tempLocalCellSize;
- (void)insertTextIntoBuffer:(NSString *)text {
    
    int asciiCode = [text characterAtIndex:0];
    if (asciiCode == 0) {
        return;
    }
    
    int indx = self.localTextBufferIndex;
//    if ((int)self.chatEntries.count == 0) {
//        indx = 0;
//    } else {
//        indx = (int)self.chatEntries.count - 1;
//    }
    NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:self.localTextBufferIndex];
    BubbleTableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
    
    RTTMessageModel *currentRttModel = [self.chatEntries lastObject];
//    NSString *currentCharacter = currentRttModel.msgString;
    
    
    BOOL enter_pressed=[text containsString:@"\n"] ||[text containsString:@"0x2028"];

    if(!self.localTextBuffer|| [text isEqualToString:@"\n"] ||[text isEqualToString:@"0x2028"]){
              // if the last one is not mine and it's not a first my messages
        if(enter_pressed){
            self.localTextBuffer = nil;
            return;
        }
        
        if ([currentRttModel.color isEqual:[UIColor colorWithRed:0 green:0.55 blue:0.6 alpha:0.8]] && (indx != 0) && enter_pressed) {
            return;
        }
        
        if (!enter_pressed) {
            // If the previous is my message
            if ([currentRttModel.color isEqual:[UIColor colorWithRed:0 green:0.55 blue:0.6 alpha:0.8]]) {
                self.localTextBuffer.modifiedTimeInterval = [[NSDate new] timeIntervalSince1970];
            }
            [self createNewLocalChatBuffer:text];
            return;
        }
    }
    
    if (self.localTextBufferIndex == 0 && !self.localTextBuffer) { // if it's the first message after others
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
        if(![self.tableView.visibleCells containsObject:cell]){
            [self createNewLocalChatBuffer:text];
            return;
        }
        
        [self.localTextBuffer.msgString appendString: text];
        [self.chatEntries setObject:self.localTextBuffer atIndexedSubscript:indx];
        
        cell.textLabel.text = self.localTextBuffer.msgString;
        const CGFloat fontSize = cell.textLabel.font.pointSize;
        const int reloadThreshold = cell.frame.size.width / (float)fontSize;
        if(self.localTextBuffer.msgString.length % reloadThreshold == 0){
            [self.tableView reloadData];
        }
      //  NSIndexSet *set = [NSIndexSet indexSetWithIndex:self.remoteTextBufferIndex];
        //[self.tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
       
        [self showLatestMessage];
        
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
                //[self sortChatEntriesArray];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self.localTextBufferIndex]];
                cell.textLabel.text = self.localTextBuffer.msgString;
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
// Remove verbose logging
//    NSLog(@"theText %@",theText);
//    NSLog(@"Add characters. %@ Core %s", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
//          linphone_core_get_version());
//    NSLog(@"insertText %@",self.localTextBuffer.msgString);
    LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
    if(!call) return;
    if(linphone_call_get_state(call) != LinphoneCallStreamsRunning) return;
    
    LinphoneChatRoom* room = linphone_call_get_chat_room(call);
    LinphoneChatMessage* msg = linphone_chat_room_create_message(room, "");
    
    
    int TEXT_MODE=[self getTextMode];
    
    if(TEXT_MODE==RTT){
        linphone_chat_message_put_char(msg, c);
    }else if(TEXT_MODE==SIP_SIMPLE){
        //NSLog(@"self.localTextBuffer.msgString %@",self.localTextBuffer.msgString);
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
    if(!call) return;
    if(linphone_call_get_state(call) != LinphoneCallStreamsRunning) return;
    
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
    [self.tableView setContentInset:UIEdgeInsetsMake(80, 0, 100, 0)];
    //[self sortChatEntriesArray];
    [self.tableView reloadData];
    [self showLatestMessage];
    [self insertTextIntoMinimizedTextBuffer:text];
}
CGSize tempRemoteCellSize;
- (void)insertTextIntoRemoteBuffer:(NSString *)text {
    
    int asciiCode = [text characterAtIndex:0];
    if (asciiCode == 0) {
        return;
    }
    int index = self.remoteTextBufferIndex;

    NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:self.remoteTextBufferIndex];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
    BOOL enter_pressed=[text containsString:@"\n"] ||[text containsString:@"0x2028"];
    
    if(!self.remoteTextBuffer|| [text isEqualToString:@"\n"] ||[text isEqualToString:@"0x2028"]){
        // if the last one is not mine and it's not a first my messages
        if (index == 0 && ((int)self.chatEntries.count == 0)) {
            [self createNewRemoteChatBuffer:text];
            return;
        }

        if(enter_pressed){
            self.remoteTextBuffer = nil;
            return;
        }
        
        if (!enter_pressed) {
            [self createNewRemoteChatBuffer:text];
            self.remoteTextBuffer.modifiedTimeInterval = [[NSDate new] timeIntervalSince1970];
            return;
        }
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
        if(![self.tableView.visibleCells containsObject:cell]){
            [self createNewRemoteChatBuffer:text];
            return;
        }
        // [self.remoteTextBuffer.msgString appendString:text];
     
        self.remoteTextBuffer.msgString = [[self.remoteTextBuffer.msgString stringByAppendingString:text] mutableCopy];
        
        [self.chatEntries setObject:self.remoteTextBuffer atIndexedSubscript:index];
        
        //[self sortChatEntriesArray];
      
        cell.textLabel.text = self.remoteTextBuffer.msgString;
        
        const CGFloat fontSize = cell.textLabel.font.pointSize;
        const int reloadThreshold = cell.frame.size.width / (float)fontSize;
      
        if(self.remoteTextBuffer.msgString.length % reloadThreshold == 0){
            [self.tableView reloadData];
        }
        [self.tableView setContentInset:UIEdgeInsetsMake(80, 0, 100, 0)];
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
                //[self sortChatEntriesArray];
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:self.remoteTextBufferIndex]];
                
                cell.textLabel.text = self.remoteTextBuffer.msgString;
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
