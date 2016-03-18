//
//  InCallDialpadView.h
//  linphone
//
//  Created by Hrachya Stepanyan on 3/9/16.
//
//

#import "BaseView.h"
#import "InCallViewConstants.h"

@interface InCallDialpadView : BaseView

@property (nonatomic, copy) ButtonActionHandler oneButtonHandler;
@property (nonatomic, copy) ButtonActionHandler twoButtonHandler;
@property (nonatomic, copy) ButtonActionHandler threeButtonHandler;
@property (nonatomic, copy) ButtonActionHandler fourButtonHandler;
@property (nonatomic, copy) ButtonActionHandler fiveButtonHandler;
@property (nonatomic, copy) ButtonActionHandler sixButtonHandler;
@property (nonatomic, copy) ButtonActionHandler sevenButtonHandler;
@property (nonatomic, copy) ButtonActionHandler eightButtonHandler;
@property (nonatomic, copy) ButtonActionHandler nineButtonHandler;
@property (nonatomic, copy) ButtonActionHandler zeroButtonHandler;
@property (nonatomic, copy) ButtonActionHandler starButtonHandler;
@property (nonatomic, copy) ButtonActionHandler sharpButtonHandler;

@property (nonatomic, assign) ViewState viewState;

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
 *  @param completion Animation completion block
 */
- (void)hideWithAnimation:(BOOL)animation completion:(Completion)completion;

@end
