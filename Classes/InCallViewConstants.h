//
//  InCallViewConstants.h
//  linphone
//
//  Created by Ruben Semerjyan on 3/4/16.
//
//

#ifndef InCallViewConstants_h
#define InCallViewConstants_h


typedef enum {
    
    VS_None = 0,
    VS_Animating,
    VS_Opened,
    VS_Closed
} ViewState;

/**
 *  @brief Callback for view's buttons
 *
 *  @param sender Pressed button
 */
typedef void (^ButtonActionHandler)(UIButton *sender);

/**
 *  @brief Completion block
 */
typedef void (^Completion)();

#endif /* InCallViewConstants_h */
