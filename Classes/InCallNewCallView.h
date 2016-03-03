//
//  InCallNewCallView.h
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

@interface InCallNewCallView : BaseView

@property (nonatomic, copy) ButtonActionCallback messageButtonBlock;
@property (nonatomic, copy) ButtonActionCallback declineButtonBlock;
@property (nonatomic, copy) ButtonActionCallback acceptButtonBlock;

@end
