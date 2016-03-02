//
//  IncomingCallViewControllerNew.m
//  linphone
//
//  Created by Hrachya Stepanyan on 3/1/16.
//
//

#import "IncomingCallViewControllerNew.h"
#import "IncomingCallMessageTableViewController.h"

#define kMessagesAnimationDuration 1.5f

@interface IncomingCallViewControllerNew ()

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


#pragma mark - Instance methods

- (void)setupController {
    
    [self.profileImageView.layer setCornerRadius:CGRectGetHeight(self.profileImageView.frame)/2];
    [self.profileImageView.layer setBorderColor:[UIColor colorWithRed:0.9176 green:0.498 blue:0.2275 alpha:1.0].CGColor];
    [self.profileImageView.layer setBorderWidth:4.f];
    
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
                             [self.answerMessagesContainerView setHidden:YES];
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
    
    CABasicAnimation *theAnimation;
    
    theAnimation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
    theAnimation.duration     = 1.f;
    theAnimation.repeatCount  = 4.f;
    theAnimation.autoreverses = YES;
    theAnimation.fromValue    = (id) self.answerMessagesContainerView.backgroundColor;
    theAnimation.toValue      = (id) [UIColor colorWithRed:0.9176 green:0.498 blue:0.2275 alpha:1.0];
    [self.answerMessagesContainerView.layer addAnimation:theAnimation forKey:@"animateBackground"];
    
}


#pragma mark - Actions
- (IBAction)messageAnswerViewButtonAction:(UIButton *)sender {
    
    [self showOrHideMessagesContainerAnimated:YES
                               withCompletion:nil];
    
}

- (IBAction)acceptButtonAction:(UIButton *)sender {
}

- (IBAction)rejectButtonAction:(UIButton *)sender {
}


- (IBAction)profileImageViewAction:(UITapGestureRecognizer *)sender {
    
    [self animateBackgroundColor];
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
