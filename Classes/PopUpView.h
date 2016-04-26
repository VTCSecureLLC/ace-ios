//
//  PopUpView.h
//  linphone
//
//  Created by Misha Torosyan on 12/10/15.
//
//

#import <UIKit/UIKit.h>


typedef void (^CompletionBlock)();


@interface PopUpView : UIView

@property (strong, nonatomic, readonly, nonnull) UIWindow *window;

+ (nullable instancetype)loadFromXib;


#pragma mark - Animations
- (void)attachShowingAnimationWithCompletion:(nullable CompletionBlock)completion;

- (void)attachHidingAnimationWithCompletion:(nullable CompletionBlock)completion;


- (void)hideWithCompletion:(nullable CompletionBlock)completion;

- (void)hideAfterDelay:(NSTimeInterval)delay withCompletion:(nullable CompletionBlock)completion;


@end
