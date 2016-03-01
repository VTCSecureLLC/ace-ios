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

- (void)showAlertInController:(UIViewController *)viewController withTitle:(NSString*)title withMessage:(NSString *)message completion:(void (^)())completion {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAlertAction = [UIAlertAction actionWithTitle:@"OK"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *alertAction) {
                                                              [alertController dismissViewControllerAnimated:YES completion:^{
                                                                  if (completion) {
                                                                      completion();
                                                                  }
                                                              }];
                                                          }];
    [alertController addAction:okAlertAction];
    [viewController presentViewController:alertController animated:YES completion:nil];
}


#pragma mark - Instance Methods
- (UIViewController *)viewControllerWithClass:(Class)controllerClass inStoryboardWithName:(NSString*)storyboardName {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:NSStringFromClass(controllerClass)];
    
    if (![viewController isKindOfClass:controllerClass]) {
        viewController =  nil;
    }

    return viewController;
}

- (UIViewController *)initialViewControllerInStoryboard:(NSString *)storyboardName {
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
    UIViewController *viewController = [storyboard instantiateInitialViewController];
    
    return viewController;
}

@end
