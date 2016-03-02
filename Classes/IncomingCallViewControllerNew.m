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


#define kMessagesAnimationDuration   0.5f
#define kBackgroundAnimationDuration 1.f


@interface IncomingCallViewControllerNew ()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *answerMessagesContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *answerMessagesViewStatusArrow;

@end


@implementation IncomingCallViewControllerNew

#pragma mark - Override Methods
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setupController];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self setupNotifications];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    [self removeNotifications];
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


#pragma mark - Private Methods
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
    theAnimation.duration = 1.f;
    theAnimation.repeatCount = HUGE_VAL;
    theAnimation.autoreverses = YES;
    theAnimation.toValue = (id)[UIColor colorWithRed:0.9255 green:0.5412 blue:0.1569 alpha:1.0].CGColor;
    [self.backgroundView.layer addAnimation:theAnimation forKey:@"animateBackground"];
}


- (void)displayInCallViewController {
    
    UIViewController *inCallViewController = (UIViewController *)[[UIManager sharedManager] inCallViewController];
    [self.navigationController pushViewController:inCallViewController
                                         animated:NO];
}

- (void)update {
    
    [_profileImageView setImage:[UIImage imageNamed:@"avatar_unknown.png"]];
    
    NSString *address = nil;
    const LinphoneAddress *addr = linphone_call_get_remote_address([[LinphoneManager instance] currentCall]);
    if (addr != NULL) {
        BOOL useLinphoneAddress = true;
        // contact name
        char *lAddress = linphone_address_as_string_uri_only(addr);
        if (lAddress) {
            NSString *normalizedSipAddress = [FastAddressBook normalizeSipURI:[NSString stringWithUTF8String:lAddress]];
            ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:normalizedSipAddress];
            if (contact) {
                UIImage *tmpImage = [FastAddressBook getContactImage:contact thumbnail:false];
                if (tmpImage != nil) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL),
                                   ^(void) {
                                       UIImage *tmpImage2 = [UIImage decodedImageWithImage:tmpImage];
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           _profileImageView.image = tmpImage2;
                                       });
                                   });
                }
                address = [FastAddressBook getContactDisplayName:contact];
                useLinphoneAddress = false;
            }
            ms_free(lAddress);
        }
        if (useLinphoneAddress) {
            const char *lDisplayName = linphone_address_get_display_name(addr);
            const char *lUserName = linphone_address_get_username(addr);
            if (lDisplayName)
                address = [NSString stringWithUTF8String:lDisplayName];
            else if (lUserName)
                address = [NSString stringWithUTF8String:lUserName];
        }
    }
    
    // Set Address
    if (address == nil) {
        address = @"Unknown";
    }
    [_nameLabel setText:address];
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


#pragma mark - Navigation
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

#pragma mark - Linphone Notifications
- (void)callUpdate:(NSNotification *)notification {
    
    LinphoneCallState state = [[notification.userInfo objectForKey:@"state"] intValue];
    
    switch (state) {
        case LinphoneCallIncomingReceived: {
            
            NSAssert(1, @"LinphoneCallIncomingReceived: Just need to check this state");
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
            [[UIManager sharedManager] hideIncomingCallViewControllerAnimated:YES];
            break;
        }
        case LinphoneCallReleased: {
            
            // Dismiss controller
            [[UIManager sharedManager] hideIncomingCallViewControllerAnimated:YES];
            break;
        }
        default:
            break;
    }
}


@end
