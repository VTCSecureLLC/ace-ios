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
typedef void (^ButtonActionCallback)(UIButton *sender);


@interface InCallNewCallNotificationView : BaseView

@property (nonatomic, strong) ButtonActionCallback notificationViewActionBlock;

/**
 *  @brief Filles notification data with LinphoneCall model
 *
 *  @param linphoneCall Caller's LinphoneCall model
 */
- (void)fillWithCallModel:(LinphoneCall *)linphoneCall;

@end
