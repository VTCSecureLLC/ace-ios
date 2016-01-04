//
//  AcceptanceVC.m
//  linphone
//
//  Created by User on 29/12/15.
//
//

#import "AcceptanceVC.h"

@interface AcceptanceVC () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation AcceptanceVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.textView.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onAcceptClick:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *myStr = @"AcceptanceScreen";
    [defaults setObject:myStr forKey:@"AcceptanceScreen"];
    [defaults synchronize];
    if ([self.delegate respondsToSelector:@selector(didAccept)]) {
        [self.delegate didAccept];
    }
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

- (IBAction)onExitClick:(id)sender {
    exit(0);
}

-(void)scrollViewDidScroll: (UIScrollView*)scrollView {
    float scrollViewHeight = scrollView.frame.size.height;
    float scrollContentSizeHeight = scrollView.contentSize.height;
    float scrollOffset = scrollView.contentOffset.y;
    
    if (scrollOffset == 0) {
    } else if (scrollOffset + scrollViewHeight > scrollContentSizeHeight - 20) {
        self.acceptButton.userInteractionEnabled = YES;
        [self.acceptButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}

@end
