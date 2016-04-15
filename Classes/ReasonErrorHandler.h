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

typedef void(^AlertViewWillDismissComplitionHandler)(ReasonError *error);

@interface ReasonErrorHandler : NSObject

@property (nonatomic, copy) AlertViewWillDismissComplitionHandler alertViewWillDismissComplitionBlock;

#pragma mark - Lifecycle Methods
+ (instancetype)sharedInstance;

#pragma mark - Instance Methods
- (void)showErrorForLinphoneReason:(LinphoneReason)reason;

@end
