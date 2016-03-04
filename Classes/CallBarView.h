//
//  CallBarView.h
//  linphone
//
//  Created by Misha Torosyan on 3/4/16.
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

/**
 *  @brief Calles when call bar will hides
 *
 *  @param duration Animation duration
 */
typedef void (^CallBarWillStartAnimateWithDurationCallback)(NSTimeInterval duration);

typedef enum {
    
    VS_None = 0,
    VS_Animating,
    VS_Opened,
    VS_Closed
} ViewState;


@interface CallBarView : BaseView

@property (nonatomic, copy) ButtonActionCallback videoButtonActionBlock;
@property (nonatomic, copy) ButtonActionCallback voiceButtonActionBlock;
@property (nonatomic, copy) ButtonActionCallback keypadButtonActionBlock;
@property (nonatomic, copy) ButtonActionCallback soundButtonActionBlock;
@property (nonatomic, copy) ButtonActionCallback moreButtonActionBlock;
@property (nonatomic, copy) ButtonActionCallback switchCameraButtonActionBlock;
@property (nonatomic, copy) ButtonActionCallback changeVideoLayoutButtonActionBlock;
@property (nonatomic, copy) ButtonActionCallback endCallButtonActionBlock;
@property (nonatomic, copy) CallBarWillStartAnimateWithDurationCallback callBarWillHideWithDurationBlock;
@property (nonatomic, copy) CallBarWillStartAnimateWithDurationCallback callBarWillShowWithDurationBlock;
@property (nonatomic, assign, getter=isVideoButtonSelected) BOOL videoButtonSelected;
@property (nonatomic, assign, getter=isVoiceButtonSelected) BOOL voiceButtonSelected;
@property (nonatomic, assign, getter=isKeypadButtonSelected) BOOL keypadButtonSelected;
@property (nonatomic, assign, getter=isSoundButtonSelected) BOOL soundButtonSelected;
@property (nonatomic, assign, getter=isMoreButtonSelected) BOOL moreButtonSelected;
@property (nonatomic, assign) NSTimeInterval hideAfterDelay;
@property (nonatomic, assign) ViewState viewState;

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

/**
 *  @brief Resets timer which hides the view with animation
 */
- (void)resetHideTimer;

@end
