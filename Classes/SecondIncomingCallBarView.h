//
//  SecondIncomingCallBar.h
//  linphone
//
//  Created by Misha Torosyan on 3/3/16.
//
//

#import "BaseView.h"

/**
 *  @brief Callback for view's buttons
 *
 *  @param sender Pressed button
 */
typedef void (^ButtonActionCallback)(UIButton *sender);

@interface SecondIncomingCallBarView : BaseView

@property (nonatomic, copy) ButtonActionCallback messageButtonBlock;
@property (nonatomic, copy) ButtonActionCallback declineButtonBlock;
@property (nonatomic, copy) ButtonActionCallback acceptButtonBlock;

/**
 *  @brief Showes view
 *
 *  @param animation  Show with animation or not
 *  @param completion Completion block
 */
- (void)showWithAnimation:(BOOL)animation completion:(void(^)())completion;

/**
 *  @brief Hides view
 *
 *  @param animation  Hide with animation or not
 *  @param completion Completion block
 */
- (void)hideWithAnimation:(BOOL)animation completion:(void(^)())completion;

@end
