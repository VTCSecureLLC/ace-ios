//
//  InCallNewCallNotificationView.h
//  linphone
//
//  Created by Ruben Semerjyan on 3/3/16.
//
//

#import "BaseView.h"
#include "linphone/linphonecore.h"
#import "InCallViewConstants.h"

/**
 *  @brief Callback for view's buttons
 *
 *  @param sender Pressed button
 */
typedef void (^NotificationActionCallback)(LinphoneCall *linphoneCall);


@interface SecondIncomingCallView : BaseView

@property (nonatomic, assign) ViewState viewState;
@property (nonatomic, copy) NotificationActionCallback notificationViewActionBlock;


/**
 *  @brief Increments rings count
 */
- (void)startCalculatingRingsCount;

/**
 *  @brief Stops and resets rings count
 */
- (void)stopAndResetRingsCount;

/**
 *  @brief Filles notification data with LinphoneCall model
 *
 *  @param linphoneCall Caller's LinphoneCall model
 */
- (void)fillWithCallModel:(LinphoneCall *)linphoneCall;

/**
 *  @brief Showes view
 *
 *  @param animation Show with animation or not
 *  @param completion Animation completion block
 */
- (void)showNotificationWithAnimation:(BOOL)animation
                           completion:(Completion)completion;

/**
 *  @brief Hides view
 *
 *  @param animation Hide with animation or not
 *  @param completion Animation completion block
 */
- (void)hideNotificationWithAnimation:(BOOL)animation
                           completion:(Completion)completion;

@end
