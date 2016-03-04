//
//  InCallNewCallNotificationView.h
//  linphone
//
//  Created by Misha Torosyan on 3/3/16.
//
//

#import "BaseView.h"
#include "linphone/linphonecore.h"

/**
 *  @brief Callback for view's buttons
 *
 *  @param sender Pressed button
 */
typedef void (^NotificationActionCallback)(LinphoneCall *linphoneCall);

@interface SecondIncomingCallView : BaseView


@property (nonatomic, copy) NotificationActionCallback notificationViewActionBlock;

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
 */
- (void)showNotificationWithAnimation:(BOOL)animation;

/**
 *  @brief Hides view
 *
 *  @param animation Hide with animation or not
 */
- (void)hideNotificationWithAnimation:(BOOL)animation;

@end
