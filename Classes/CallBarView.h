//
//  CallBarView.h
//  linphone
//
//  Created by Ruben Semerjyan on 3/4/16.
//
//

#import "BaseView.h"
#include "linphone/linphonecore.h"
#import "InCallViewConstants.h"

/**
 *  @brief Calles when call bar will hides
 *
 *  @param duration Animation duration
 */
typedef void (^CallBarWillStartAnimateWithDurationCallback)(NSTimeInterval duration);


@interface CallBarView : BaseView

@property (nonatomic, copy) ButtonActionHandler videoButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler voiceButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler keypadButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler soundButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler moreButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler switchCameraButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler changeVideoLayoutButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler chatButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler endCallButtonActionHandler;
@property (nonatomic, copy) CallBarWillStartAnimateWithDurationCallback callBarWillHideWithDurationBlock;
@property (nonatomic, copy) CallBarWillStartAnimateWithDurationCallback callBarWillShowWithDurationBlock;
@property (nonatomic, assign, getter=isVideoButtonSelected) BOOL videoButtonSelected;
@property (nonatomic, assign, getter=isVoiceButtonSelected) BOOL voiceButtonSelected;
@property (nonatomic, assign, getter=isKeypadButtonSelected) BOOL keypadButtonSelected;
@property (nonatomic, assign, getter=isSoundButtonSelected) BOOL soundButtonSelected;
@property (nonatomic, assign, getter=isMoreButtonSelected) BOOL moreButtonSelected;
// NOTICE: [Gagik] Hiding automatic bar closing 
//@property (nonatomic, assign) NSTimeInterval hideAfterDelay;
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

/**
 *  @brief Resets timer which hides the view with animation
 */
// Automatic hiding
//- (void)resetHideTimer;

- (void)changeChatButtonVisibility:(BOOL)hidden;

@end
