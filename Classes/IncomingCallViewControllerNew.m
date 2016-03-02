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
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
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

#pragma mark - Instance methods

- (void)setupProfileImageView {
    
    [self.profileImageView.layer setMasksToBounds:YES];
    [self.profileImageView.layer setCornerRadius:self.profileImageView.frame.size.width/2];
    [self.profileImageView.layer setBorderColor:[UIColor colorWithRed:0.9176 green:0.498 blue:0.2275 alpha:1.0].CGColor];
    [self.profileImageView.layer setBorderWidth:6.f];
}

- (void)setupController {
    
    [self animateBackgroundColor];
    
}

- (void)showOrHideMessagesContainerAnimated:(BOOL)animated
                             withCompletion:(void (^)())completion {
    
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
    theAnimation.duration     = 1.f;
    theAnimation.repeatCount  = HUGE_VAL;
    theAnimation.autoreverses = YES;
    theAnimation.toValue      = (id)[UIColor colorWithRed:0.9255 green:0.5412 blue:0.1569 alpha:1.0].CGColor;
    [self.backgroundView.layer addAnimation:theAnimation forKey:@"animateBackground"];
}


- (void)acceptToCall {
    
    UIViewController *inCallViewController = (UIViewController *)[[UIManager sharedManager] inCallViewController];
    [self.navigationController pushViewController:inCallViewController
                                         animated:NO];
}


#pragma mark - Actions
- (IBAction)messageAnswerViewButtonAction:(UIButton *)sender {
    
    [self showOrHideMessagesContainerAnimated:YES
                               withCompletion:nil];
}

- (IBAction)acceptButtonAction:(UIButton *)sender {
    
    [self acceptToCall];
    
}

- (IBAction)rejectButtonAction:(UIButton *)sender {
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
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


@end
