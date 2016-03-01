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


#define kStoryboardInCall           @"InCall"
#define kStoryboardIncomingCall     @"IncomingCall"


@interface UIManager : NSObject

#pragma mark - Class Methods
+ (instancetype)sharedManager;

#pragma mark - Instance Methods

/**
 *  Changes rootViewController of window with given viewController
 *
 *  @param viewController New view controller
 */
- (void)changeRootViewControllerWithController:(UIViewController *)viewController;

/**
 *  Creates an instance of IncomingCallViewController and returns it
 *
 *  @return newly created instance of IncomingCallViewController
 */
- (IncomingCallViewControllerNew *)incomingCallViewController;


@end
