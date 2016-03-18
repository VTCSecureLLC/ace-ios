//
//  StatusBar.h
//  linphone
//
//  Created by Ruben Semerjyan on 3/14/16.
//
//

#import "BaseView.h"
#import "InCallViewConstants.h"

@interface StatusBar : BaseView

@property (nonatomic, copy) ButtonActionHandler statusBarActionHandler;

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
 *  @param completion Completion block
 */
- (void)hideWithAnimation:(BOOL)animation completion:(void(^)())completion;

@end
