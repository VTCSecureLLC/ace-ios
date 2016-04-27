//
//  ReasonErrorHandler.h
//  linphone
//
//  Created by Misha Torosyan on 4/15/16.
//
//

#import <Foundation/Foundation.h>
#import "LinphoneManager.h"
#import "ReasonError.h"

typedef void(^PopUpWillDismissComplitionHandler)();

@interface ReasonErrorHandler : NSObject

@property (nonatomic, copy) PopUpWillDismissComplitionHandler popUpViewWillDismissComplitionBlock;

#pragma mark - Lifecycle Methods
+ (instancetype)sharedInstance;

#pragma mark - Instance Methods
- (void)showErrorForLinphoneReason:(LinphoneReason)reason;

- (void)closeErrorView;

@end
