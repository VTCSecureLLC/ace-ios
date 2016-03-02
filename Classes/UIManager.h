//
//  UIManager.h
//  Diagnosis
//
//  Created by Hrachya Stepanyan on 10/27/15.
//  Copyright © 2015 Hrachya Stepanyan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "IncomingCallViewControllerNew.h"
#import "InCallViewController.h"


#define kStoryboardInCall           @"InCall"
#define kStoryboardIncomingCall     @"IncomingCall"


@interface UIManager : NSObject

#pragma mark - Class Methods
+ (instancetype)sharedManager;

#pragma mark - Instance Methods

/**
 *  @brief Changes rootViewController of window with given viewController
 *
 *  @param viewController New view controller
 */
- (void)changeRootViewControllerWithController:(UIViewController *)viewController;

/**
 *  @brief Creates an instance of IncomingCallViewController and returns it
 *
 *  @return newly created instance of IncomingCallViewController
 */
- (IncomingCallViewControllerNew *)incomingCallViewController;


/**
 *  @brief Returns InCallViewContorller
 *
 *  @return InCallViewContorller object
 */
- (InCallViewController *)inCallViewController;

/**
 *  @brief Shows incoming call view controller
 *
 *  @param animated Show with animation or not
 */
- (void)showIncomingCallViewControllerAnimated:(BOOL)animated;


/**
 *  @brief Retruns visible view controller
 *
 *  @return Visible view controller
 */
- (UIViewController*)topViewController;

@end
