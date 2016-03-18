//
//  SecondIncomingCallBar.h
//  linphone
//
//  Created by Ruben Semerjyan on 3/3/16.
//
//

#import "BaseView.h"
#import "InCallViewConstants.h"
#import "LinphoneManager.h"


/**
 *  @brief Callback for view's buttons
 *
 *  @param sender Pressed button
 */
typedef void (^ButtonActionCallback)(LinphoneCall *linphoneCall);

@interface SecondIncomingCallBarView : BaseView

@property (nonatomic, copy) ButtonActionCallback messageButtonBlock;
@property (nonatomic, copy) ButtonActionCallback declineButtonBlock;
@property (nonatomic, copy) ButtonActionCallback acceptButtonBlock;
@property (nonatomic, assign) ViewState viewState;
@property (nonatomic, assign) LinphoneCall *linphoneCall;


/**
 *  @brief Showes view
 *
 *  @param animation  Show with animation or not
 *  @param completion Completion block
 */
- (void)showWithAnimation:(BOOL)animation completion:(Completion)completion;

/**
 *  @brief Hides view
 *
 *  @param animation  Hide with animation or not
 *  @param completion Completion block
 */
- (void)hideWithAnimation:(BOOL)animation completion:(Completion)completion;

@end
