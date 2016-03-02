//
//  UIManager.m
//  Diagnosis
//
//  Created by Hrachya Stepanyan on 10/27/15.
//  Copyright © 2015 Hrachya Stepanyan. All rights reserved.
//

#import "UIManager.h"


@implementation UIManager

#pragma mark - Class Methods
+ (instancetype)sharedManager {
    
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}


#pragma mark - Private Methods
- (void)transitionToViewController:(UIViewController *)viewController withTransition:(UIViewAnimationOptions)transition {
    
    UIViewController* rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    [UIView transitionFromView:rootViewController.view
                        toView:viewController.view
                      duration:0.65
                       options:transition
                    completion:^(BOOL finished){
                        [UIApplication sharedApplication].delegate.window.rootViewController = viewController;
                        [[UIApplication sharedApplication].delegate.window makeKeyAndVisible];
                    }];
}

- (void)changeRootViewControllerWithController:(UIViewController *)viewController {
    
    [self transitionToViewController:viewController withTransition:UIViewAnimationOptionTransitionNone];
}

- (IncomingCallViewControllerNew *)incomingCallViewController {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:kStoryboardIncomingCall bundle:nil];
    IncomingCallViewControllerNew *viewController = [storyboard instantiateViewControllerWithIdentifier:@"IncomingCallViewController"];
    
    return viewController;
}

- (InCallViewControllerNew *)incallViewController {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:kStoryboardInCall bundle:nil];
    InCallViewControllerNew *incallViewController = [storyboard instantiateViewControllerWithIdentifier:@"InCallViewControllerNew"];
    
    return incallViewController;
}

@end
