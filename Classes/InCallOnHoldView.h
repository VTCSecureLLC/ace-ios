//
//  InCallOnHoldView.h
//  linphone
//
//  Created by Misha Torosyan on 3/3/16.
//
//

#import "BaseView.h"
#include "linphone/linphonecore.h"

typedef NS_ENUM(BOOL, AnimationDirection) {
    AnimationDirectionRight,
    AnimationDirectionLeft
};

/**
 *  @brief Callback for view's buttons
 *
 *  @param sender Pressed button
 */
typedef void (^HoldViewActionCallback)(LinphoneCall *linphoneCall);


@interface InCallOnHoldView : BaseView

@property (nonatomic, strong) HoldViewActionCallback holdViewActionBlock;

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
 *  @param direction Showing direction
 */
- (void)showWithAnimation:(BOOL)animation direction:(AnimationDirection)direction;

/**
 *  @brief Hides view
 *
 *  @param animation Hide with animation or not
 *  @param direction Hide direction
 */
- (void)hideWithAnimation:(BOOL)animation direction:(AnimationDirection)direction;

@end
