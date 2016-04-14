//
//  StatusBar.m
//  linphone
//
//  Created by Ruben Semerjyan on 3/14/16.
//
//

#import "StatusBar.h"
#import "LinphoneManager.h"
#import "DTActionSheet.h"
#import "PhoneMainView.h"
#import "InCallViewConstants.h"

#define kAnimationDuration 0.5f

@interface StatusBar () <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UIImageView *registrationStatusImageView;
@property (weak, nonatomic) IBOutlet UIImageView *callQualityImageView;
@property (weak, nonatomic) IBOutlet UIImageView *callSecurityImageView;
@property (weak, nonatomic) IBOutlet UILabel *registrationStatusLabel;
@property (weak, nonatomic) IBOutlet UIButton *callSecurityButton;
@property (nonatomic, strong) DTActionSheet *securitySheet;
@property (nonatomic, strong) NSTimer *callQualityTimer;
@property (nonatomic, strong) NSTimer *callSecurityTimer;


@end

@implementation StatusBar

#pragma mark - Overridden Methods
- (void)awakeFromNib {

    [self setupView];
}

- (void)dealloc {
    
    [self stopTimers];
    [self removeObservers];
}


#pragma mark - Instance Methods
- (void)setupView {
    
    [self registerObservers];
    [self startTimers];
    
    [self.callQualityImageView setHidden:true];
    [self.callSecurityImageView setHidden:true];
    
    // Update to default state
    LinphoneProxyConfig *config = NULL;
    linphone_core_get_default_proxy([LinphoneManager getLc], &config);
    
    //Linphone msg count - remove for now in favor of NSUserDefaults
    //	messagesUnreadCount =
    //		lp_config_get_int(linphone_core_get_config([LinphoneManager getLc]), "app", "voice_mail_messages_count", 0);
    
    [self proxyConfigUpdate:config];
    //[self updateVoicemail];

}

- (void)registrationUpdate:(NSNotification *)notif {
    LinphoneProxyConfig *config = NULL;
    linphone_core_get_default_proxy([LinphoneManager getLc], &config);
    [self proxyConfigUpdate:config];
}

- (void)proxyConfigUpdate:(LinphoneProxyConfig *)config {
    LinphoneRegistrationState state = LinphoneRegistrationNone;
    NSString *message = nil;
    UIImage *image = nil;
    LinphoneCore *lc = [LinphoneManager getLc];
    LinphoneGlobalState gstate = linphone_core_get_global_state(lc);
    
    if (gstate == LinphoneGlobalConfiguring) {
        message = NSLocalizedString(@"Fetching remote configuration", nil);
    } else if (config == NULL) {
        state = LinphoneRegistrationNone;
        if (linphone_core_is_network_reachable([LinphoneManager getLc]))
            message = NSLocalizedString(@"No SIP account configured", nil);
        else
            message = NSLocalizedString(@"Network down", nil);
    } else {
        state = linphone_proxy_config_get_state(config);
        
        switch (state) {
            case LinphoneRegistrationOk:
                message = NSLocalizedString(@"Registered", nil);
                break;
            case LinphoneRegistrationNone:
            case LinphoneRegistrationCleared:
                message = NSLocalizedString(@"Not registered", nil);
                break;
            case LinphoneRegistrationFailed:
                message = NSLocalizedString(@"Registration failed", nil);
                break;
            case LinphoneRegistrationProgress:
                message = NSLocalizedString(@"Registration in progress", nil);
                break;
            default:
                break;
        }
    }
    
    self.registrationStatusLabel.hidden = NO;
    switch (state) {
        case LinphoneRegistrationFailed:
            self.registrationStatusImageView.hidden = NO;
            image = [UIImage imageNamed:@"led_error.png"];
            break;
        case LinphoneRegistrationCleared:
        case LinphoneRegistrationNone:
            self.registrationStatusImageView.hidden = NO;
            image = [UIImage imageNamed:@"led_disconnected.png"];
            break;
        case LinphoneRegistrationProgress:
            self.registrationStatusImageView.hidden = NO;
            image = [UIImage imageNamed:@"led_inprogress.png"];
            break;
        case LinphoneRegistrationOk:
            self.registrationStatusImageView.hidden = NO;
            image = [UIImage imageNamed:@"led_connected.png"];
            break;
    }
    [self.registrationStatusLabel setText:message];
    self.registrationStatusLabel.accessibilityValue = self.registrationStatusImageView.accessibilityValue = message;
    [self.registrationStatusImageView setImage:image];
}

#pragma mark -

- (void)callSecurityUpdate {
    BOOL pending = false;
    BOOL security = true;
    
    const MSList *list = linphone_core_get_calls([LinphoneManager getLc]);
    
    if (list == NULL) {
        if (self.securitySheet) {
            [self.securitySheet dismissWithClickedButtonIndex:self.securitySheet.destructiveButtonIndex animated:TRUE];
        }
        [self.callSecurityImageView setHidden:true];
        return;
    }
    while (list != NULL) {
        LinphoneCall *call = (LinphoneCall *)list->data;
        LinphoneMediaEncryption enc = linphone_call_params_get_media_encryption(linphone_call_get_current_params(call));
        if (enc == LinphoneMediaEncryptionNone)
            security = false;
        else if (enc == LinphoneMediaEncryptionZRTP) {
            if (!linphone_call_get_authentication_token_verified(call)) {
                pending = true;
            }
        }
        list = list->next;
    }
    
    if (security) {
        if (pending) {
            [self.callSecurityImageView setImage:[UIImage imageNamed:@"security_pending"]];
        } else {
            
            UIImage *image = [UIImage imageNamed:@"security_ok"];
            self.callSecurityImageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [self.callSecurityImageView setTintColor:[UIColor colorWithRed:0.3614 green:0.8557 blue:0.1629 alpha:1.0]];
        }
    } else {
        [self.callSecurityImageView setImage:[UIImage imageNamed:@"security_ko.png"]];
    }
    [self.callSecurityImageView setHidden:false];
}

- (void)callQualityUpdate {
    UIImage *image = nil;
    LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
    if (call != NULL) {
        // FIXME double check call state before computing, may cause core dump
        float quality = linphone_call_get_average_quality(call);
        if (quality < 1) {
            image = [UIImage imageNamed:@"call_quality_indicator_0.png"];
        } else if (quality < 2) {
            image = [UIImage imageNamed:@"call_quality_indicator_1.png"];
        } else if (quality < 3) {
            image = [UIImage imageNamed:@"call_quality_indicator_2.png"];
        } else {
            image = [UIImage imageNamed:@"call_quality_indicator_3.png"];
        }
    }
    if (image != nil) {
        [self.callQualityImageView setHidden:false];
        [self.callQualityImageView setImage:image];
    } else {
        [self.callQualityImageView setHidden:true];
    }
}


- (void)globalStateUpdate:(NSNotification *)notif {
    [self registrationUpdate:notif];
}
//Update linphone voicemail count - remove in favor of NSUserDefaults
//- (void)updateVoicemail {
//	if (messagesUnreadCount > 0) {
//		self.voicemailCount.hidden = (linphone_core_get_calls([LinphoneManager getLc]) != NULL);
//		self.voicemailCount.text = [[NSString
//			stringWithFormat:NSLocalizedString(@"%d unread messages", @"%d"), messagesUnreadCount] uppercaseString];
//	} else {
//		self.voicemailCount.hidden = TRUE;
//	}
//}

- (void)callUpdate:(NSNotification *)notif {
    // show voice mail only when there is no call
    //[self updateVoicemail];
}

#pragma mark - Notifications

- (void)registerObservers {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationUpdate:)
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(globalStateUpdate:)
                                                 name:kLinphoneGlobalStateUpdate
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callUpdate:)
                                                 name:kLinphoneCallUpdate
                                               object:nil];
}

- (void)removeObservers {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Timers
- (void)startTimers {
    self.callQualityTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                             target:self
                                                           selector:@selector(callQualityUpdate)
                                                           userInfo:nil
                                                            repeats:YES];
    
    // Set callQualityTimer
    self.callSecurityTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                              target:self
                                                            selector:@selector(callSecurityUpdate)
                                                            userInfo:nil
                                                             repeats:YES];
}

- (void)stopTimers {
    
    [self.callQualityTimer invalidate];
    self.callQualityTimer = nil;
    
    [self.callSecurityTimer invalidate];
    self.callSecurityTimer = nil;
}


#pragma mark - Animations

- (void)showWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.viewState = VS_Animating;
    NSTimeInterval duration = animation ? kAnimationDuration : 0;
    
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



#pragma mark - Action Methods
- (IBAction)callSecurityButtonAction:(UIButton *)sender {
    
    if (linphone_core_get_calls_nb([LinphoneManager getLc])) {
        LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
        if (call != NULL) {
            LinphoneMediaEncryption enc =
            linphone_call_params_get_media_encryption(linphone_call_get_current_params(call));
            if (enc == LinphoneMediaEncryptionZRTP) {
                bool valid = linphone_call_get_authentication_token_verified(call);
                NSString *message = nil;
                if (valid) {
                    message = NSLocalizedString(@"Remove trust in the peer?", nil);
                } else {
                    message = [NSString
                               stringWithFormat:NSLocalizedString(@"Confirm the following SAS with the peer:\n%s", nil),
                               linphone_call_get_authentication_token(call)];
                }
                if (self.securitySheet == nil) {
                    __block __strong StatusBar *weakSelf = self;
                    self.securitySheet = [[DTActionSheet alloc] initWithTitle:message];
                    [self.securitySheet setDelegate:self];
                    [self.securitySheet addButtonWithTitle:NSLocalizedString(@"Ok", nil)
                                                block:^() {
                                                    linphone_call_set_authentication_token_verified(call, !valid);
                                                    weakSelf.securitySheet = nil;
                                                }];
                    
                    [self.securitySheet addDestructiveButtonWithTitle:NSLocalizedString(@"Cancel", nil)
                                                           block:^() {
                                                               weakSelf.securitySheet = nil;
                                                           }];
                    [self.securitySheet showInView:[PhoneMainView instance].view];
                }
            }
        }
    }
}

- (IBAction)statusBarAction:(UIButton *)sender {
    
    if (self.statusBarActionHandler) {
        self.statusBarActionHandler(sender);
    }
}

@end
