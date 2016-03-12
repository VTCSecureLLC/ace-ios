//
//  InCallOnHoldView.h
//  linphone
//
//  Created by Ruben Semerjyan on 3/3/16.
//
//

#import "BaseView.h"
#include "linphone/linphonecore.h"
#import "InCallViewConstants.h"


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

@property (nonatomic, assign) ViewState viewState;
@property (nonatomic, copy) HoldViewActionCallback holdViewActionBlock;

#pragma mark - Instance Methods
- (void)startTimeCounting;

- (void)stopTimeCounting;

- (void)resetTimeCounting;

/**
 *  @brief Filles notification data with LinphoneCall model
 *
 *  @param linphoneCall Caller's LinphoneCall model
 */
- (void)fillWithCallModel:(LinphoneCall *)linphoneCall;

/**
 *  @brief Showes view
 *
 *  @param animation  Show with animation or not
 *  @param direction  Animation direction
 *  @param completion Animation completion block
 */
- (void)showWithAnimation:(BOOL)animation
                direction:(AnimationDirection)direction
               completion:(void(^)())completion;

/**
 *  @brief Hides view
 *
 *  @param animation  Hide with animation or not
 *  @param direction  Hide direction
 *  @param completion Animation completion block
 */
- (void)hideWithAnimation:(BOOL)animation
                direction:(AnimationDirection)direction
               completion:(void(^)())completion;

@end
