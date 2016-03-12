//
//  IncomingCallNavigationController.m
//  linphone
//
//  Created by Gagik Martirosyan on 3/2/16.
//
//

#import "IncomingCallNavigationController.h"
#import "InCallViewControllerNew.h"

@interface IncomingCallNavigationController ()

@end

@implementation IncomingCallNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if ([self.visibleViewController isKindOfClass:[InCallViewControllerNew class]]) {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape;
    }
    return UIInterfaceOrientationMaskPortrait;
}

@end
