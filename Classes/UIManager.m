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

- (UIViewController*)topViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController {
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
    } else if (rootViewController.presentedViewController) {
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    } else {
        return rootViewController;
    }
}

#pragma mark - Private methods

- (IncomingCallViewControllerNew *)incomingCallViewController {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:kStoryboardIncomingCall bundle:nil];
    IncomingCallViewControllerNew *viewController = (IncomingCallViewControllerNew *)[storyboard instantiateViewControllerWithIdentifier:@"IncomingCallViewController"];
    
    return viewController;
}


//Returns InCallViewContorller
- (InCallViewControllerNew *)inCallViewController {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:kStoryboardInCall bundle:nil];
    InCallViewControllerNew *inCallViewController = (InCallViewControllerNew *)[storyboard instantiateInitialViewController];
    
    return inCallViewController;
}


//Shows incoming call view controller
- (UIViewController *)showIncomingCallViewControllerAnimated:(BOOL)animated {

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:kStoryboardIncomingCall bundle:nil];
    UINavigationController *incomingCallNavigationController = [storyboard instantiateInitialViewController];
    
    UIViewController* rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    
    [rootViewController presentViewController:incomingCallNavigationController
                                     animated:animated
                                   completion:nil];
    
    return [incomingCallNavigationController.viewControllers firstObject];
}

- (void)showInCallViewControllerAnimated:(BOOL)animated {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:kStoryboardInCall bundle:nil];
    UIViewController *inCallViewController = [storyboard instantiateViewControllerWithIdentifier:@"InCallViewControllerNew"];
    
    UIViewController* rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    
    [rootViewController presentViewController:inCallViewController
                                     animated:animated
                                   completion:nil];
}

- (void)hideIncomingCallViewControllerAnimated:(BOOL)animated {
    
    UIViewController* rootViewController = [self topViewController];
    [rootViewController dismissViewControllerAnimated:animated completion:nil];
}

- (void)hideInCallViewControllerAnimated:(BOOL)animated {
    
    UIViewController* rootViewController = [self topViewController];
    [rootViewController dismissViewControllerAnimated:animated completion:nil];
}

@end
