//
//  IncomingCallViewControllerNew.m
//  linphone
//
//  Created by Hrachya Stepanyan on 3/1/16.
//
//

#import "IncomingCallViewControllerNew.h"
#import "IncomingCallMessageTableViewController.h"
#import "InCallViewController.h"
#import "UIManager.h"
#import "UILinphone.h"
#import <AVFoundation/AVFoundation.h>


#define kMessagesAnimationDuration   0.5f
#define kBackgroundAnimationDuration 1.f


@interface IncomingCallViewControllerNew ()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *answerMessagesContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *answerMessagesViewStatusArrow;
@property (weak, nonatomic) IBOutlet UILabel *ringCountLabel;
@property (nonatomic, strong) NSTimer *cameraLedFlasherTimer;
@property (nonatomic, strong) NSTimer *vibratorTimer;
@property (nonatomic, strong) AVCaptureDevice *device;

@end


@implementation IncomingCallViewControllerNew

#pragma mark - Override Methods
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setupController];
    [self updateWithCall:_call];
    [self setupRinging];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self setupNotifications];
    [self startRinging];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [self removeNotifications];
    [self stopRinging];
}

- (void)viewWillLayoutSubviews {
    
    [super viewWillLayoutSubviews];
    
//    [self setupProfileImageView];
}

- (void)viewDidLayoutSubviews {
    
    [super viewDidLayoutSubviews];
    [self.profileImageView layoutIfNeeded];
    [self setupProfileImageView];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:NSStringFromClass([IncomingCallMessageTableViewController class])]) {
        
        IncomingCallMessageTableViewController *incomingCallMessageTableViewController = [segue destinationViewController];
        incomingCallMessageTableViewController.messageDidSelectedCallback = ^(NSUInteger index) {
            
            switch (index) {
                case 0:
                    //Can't talk now. Call me later?
                    break;
                    
                case 1:
                    //Can't talk now. What's up?
                    break;
                    
                case 2:
                    //I'm in a meeting.
                    break;
            }
            
        };
    }
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}


#pragma mark - Private Methods

- (void)displayIncrementedRingCount {
    self.ringCountLabel.hidden = NO;
    [UIView transitionWithView: self.ringCountLabel
                      duration:[[LinphoneManager instance] lpConfigFloatForKey:@"outgoing_ring_duration" forSection:@"vtcsecure"]
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                    }
                    completion:^(BOOL finished) {
                        self.ringCountLabel.text = [@(self.ringCountLabel.text.intValue + 1) stringValue];
                    }];
}


- (void)setupProfileImageView {
    
    [self.profileImageView.layer setMasksToBounds:YES];
    [self.profileImageView.layer setCornerRadius:self.profileImageView.frame.size.width/2];
    [self.profileImageView.layer setBorderColor:[UIColor colorWithRed:0.9176 green:0.498 blue:0.2275 alpha:1.0].CGColor];
    [self.profileImageView.layer setBorderWidth:6.f];
}

- (void)setupController {
    
    [self animateBackgroundColor];
    
}

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callUpdate:)
                                                 name:kLinphoneCallUpdate
                                               object:nil];
}

- (void)removeNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
}

- (void)showOrHideMessagesContainerAnimated:(BOOL)animated withCompletion:(void (^)())completion {
    
    [UIView animateWithDuration:kMessagesAnimationDuration
                     animations:^{
                         if (self.answerMessagesContainerView.tag == 0) {
                             
                             [self.answerMessagesContainerView setHidden:NO];
                             [self.answerMessagesContainerView setAlpha:1.f];
                             [self.answerMessagesContainerView setTag:1];
                             [self.answerMessagesViewStatusArrow setImage:[UIImage imageNamed:@"down_arrow"]];
                         }
                         else {
                             
                             [self.answerMessagesContainerView setAlpha:0.f];
                             [self.answerMessagesContainerView setTag:0];
                             [self.answerMessagesViewStatusArrow setImage:[UIImage imageNamed:@"up_arrow"]];
                         }
                     }
                     completion:^(BOOL finished) {
                         
                         if (finished && completion) {
                             completion();
                         }
                     }];
}

- (void)animateBackgroundColor {
    
    CABasicAnimation *theAnimation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
    theAnimation.duration = 0.8f;
    theAnimation.repeatCount = HUGE_VAL;
    theAnimation.autoreverses = YES;
    
    theAnimation.toValue = (id)[UIColor colorWithRed:1 green:0.7 blue:0 alpha:1].CGColor;
    [self.backgroundView.layer addAnimation:theAnimation forKey:@"animateBackground"];
}

- (void)displayInCallViewController {
    
    UIViewController *inCallViewController = (UIViewController *)[[UIManager sharedManager] inCallViewController];
    [self.navigationController pushViewController:inCallViewController
                                         animated:NO];
}

- (void)updateWithCall:(LinphoneCall *)linphoneCall {
    
    [[LinphoneManager instance] fetchProfileImageWithCall:linphoneCall withCompletion:^(UIImage *image) {
        
        _profileImageView.image = image;
    }];
    _nameLabel.text = [[LinphoneManager instance] fetchAddressWithCall:linphoneCall];
}


#pragma mark - Ringing
- (void)setupRinging {
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    self.device = nil;
    if (captureDeviceClass != nil) {
        self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (![self.device hasTorch] || ![self.device hasFlash]) {
            self.device = nil;self.device = nil;
        }
    }
}

- (void)startRinging {
    
    [self stopRinging];
    
    self.cameraLedFlasherTimer = [NSTimer scheduledTimerWithTimeInterval:[[LinphoneManager instance] lpConfigFloatForKey:@"incoming_flashlight_frequency" forSection:@"vtcsecure"]
                                                                  target:self
                                                                selector:@selector(toggleCameraLed)
                                                                userInfo:nil
                                                                 repeats:YES];
    [self.cameraLedFlasherTimer fire];
    
    self.vibratorTimer = [NSTimer scheduledTimerWithTimeInterval:[[LinphoneManager instance] lpConfigFloatForKey:@"incoming_vibrate_frequency" forSection:@"vtcsecure"]
                                                          target:self
                                                        selector:@selector(vibrate)
                                                        userInfo:nil
                                                         repeats:YES];
    [self.vibratorTimer fire];
}

- (void)toggleCameraLed {
    if (self.device != nil){
        [self.device lockForConfiguration:nil];
        if (self.device.torchMode == AVCaptureTorchModeOff){
            [self.device setTorchMode:AVCaptureTorchModeOn];
            [self.device setFlashMode:AVCaptureFlashModeOn];
        } else {
            [self.device setTorchMode:AVCaptureTorchModeOff];
            [self.device setFlashMode:AVCaptureFlashModeOff];
        }
        [self.device unlockForConfiguration];
    }
}

- (void)stopFlashCameraLed {
    if (self.cameraLedFlasherTimer != nil) {
        [self.cameraLedFlasherTimer invalidate];
        self.cameraLedFlasherTimer = nil;
        Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
        if (captureDeviceClass != nil) {
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            if ([device hasTorch] && [device hasFlash]){
                [device lockForConfiguration:nil];
                if (device.torchMode == AVCaptureTorchModeOn) {
                    [device setTorchMode:AVCaptureTorchModeOff];
                    [device setFlashMode:AVCaptureFlashModeOff];            }
                [device unlockForConfiguration];
            }
        }
    }
}

- (void) vibrate {
    [self displayIncrementedRingCount];
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void)stopRinging {
    
    [self stopFlashCameraLed];
    [self.vibratorTimer invalidate];
    
    self.vibratorTimer = nil;
    self.cameraLedFlasherTimer = nil;
}

#pragma mark - Actions Methods
- (IBAction)messageAnswerViewButtonAction:(UIButton *)sender {
    
    [self showOrHideMessagesContainerAnimated:YES
                               withCompletion:nil];
}

- (IBAction)acceptButtonAction:(UIButton *)sender {
    
    [[LinphoneManager instance] acceptCall:[[LinphoneManager instance] currentCall]];
}

- (IBAction)rejectButtonAction:(UIButton *)sender {
    
    [[LinphoneManager instance] declineCall:[[LinphoneManager instance] currentCall]];
}


#pragma mark - Linphone Notifications
- (void)callUpdate:(NSNotification *)notification {
    
    LinphoneCallState state = [[notification.userInfo objectForKey:@"state"] intValue];
    
    switch (state) {
        case LinphoneCallIncomingReceived: {
            
            NSAssert(1, @"LinphoneCallIncomingReceived: Just need to check this state");
            NSUInteger callCount = [[LinphoneManager instance] callsCountForLinphoneCore:[LinphoneManager getLc]];
            if (callCount == 2) {
                [[LinphoneManager instance] declineCall:[[LinphoneManager instance] holdCall]];
            }
            break;
        }
        case LinphoneCallIncomingEarlyMedia: {
            
            NSAssert(1, @"LinphoneCallIncomingEarlyMedia: Just need to check this state");
            break;
        }
        case LinphoneCallOutgoingInit: {
            
            NSAssert(1, @"LinphoneCallOutgoingInit: Just need to check this state");
            break;
        }
        case LinphoneCallPausedByRemote: {
            
            NSAssert(1, @"LinphoneCallPausedByRemote: Just need to check this state");
            break;
        }
        case LinphoneCallConnected: {
            
            // Open In call view controller
            [self displayInCallViewController];
            break;
        }
        case LinphoneCallStreamsRunning: {
            
            NSAssert(1, @"LinphoneCallStreamsRunning: Just need to check this state");
            break;
        }
        case LinphoneCallUpdatedByRemote: {
            
            NSAssert(1, @"LinphoneCallUpdatedByRemote: Just need to check this state");
            break;
        }
        case LinphoneCallError: {
            
            // Show error
            break;
        }
        case LinphoneCallEnd: {
            
            // Dismiss controller
            NSUInteger callCount = [[LinphoneManager instance] callsCountForLinphoneCore:[LinphoneManager getLc]];
            if (callCount == 0) {
                [[UIManager sharedManager] hideIncomingCallViewControllerAnimated:YES];
            }
            break;
        }
        case LinphoneCallReleased: {
            
            // Dismiss controller
            NSUInteger callCount = [[LinphoneManager instance] callsCountForLinphoneCore:[LinphoneManager getLc]];
            if (callCount == 0) {
                [[UIManager sharedManager] hideIncomingCallViewControllerAnimated:YES];
            }
            else if ([[LinphoneManager instance] holdCall]) {
                [self updateWithCall:[[LinphoneManager instance] holdCall]];
            }
            break;
        }
        default:
            break;
    }
}

@end
