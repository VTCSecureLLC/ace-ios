//
//  PopUpView.m
//  linphone
//
//  Created by Misha Torosyan on 12/10/15.
//  
//

#import "PopUpView.h"

#define kAnimationDuration 0.2f


@interface PopUpView ()

@property (nonatomic, copy) CompletionBlock completionBlock;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation PopUpView

#pragma mark - Static Methods
+ (nullable instancetype)loadFromXib {
    
    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class])
                                                         owner:self
                                                       options:nil];
    
    if ([[nibContents lastObject] isMemberOfClass:[self class]]) {
        return [nibContents lastObject];
    }
    else {
        return nil;
    }
}


#pragma mark - Animations
- (void)attachShowingAnimationWithCompletion:(nullable void (^)())completion {
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        
        self.alpha = 1.f;
        
    } completion:^(BOOL finished) {
        
        if (finished) {
            
            if (completion) {
                completion();
            }
        }
    }];
}


- (void)attachHidingAnimationWithCompletion:(nullable CompletionBlock)completion {
    
    [UIView animateWithDuration:kAnimationDuration animations:^{
        
        self.alpha = 0.f;
        
    } completion:^(BOOL finished) {
        
        if (finished) {
            [self removeFromSuperview];
            
            if (completion) {
                completion();
            }
        }
    }];
}



#pragma mark - Hide
- (void)hide {
    
    [self attachHidingAnimationWithCompletion:self.completionBlock];
}

- (void)hideWithCompletion:(nullable CompletionBlock)completion {
    
    self.completionBlock = completion;
    [self hide];
}

- (void)hideAfterDelay:(NSTimeInterval)delay withCompletion:(nullable CompletionBlock)completion {
    
    self.completionBlock = completion;
    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    if (delay > 0) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:delay
                                                      target:self
                                                    selector:@selector(hide)
                                                    userInfo:nil
                                                     repeats:NO];
    }
    else {
        [self hide];
    }
}

#pragma mark - Window

- (nonnull UIWindow *)window {
    return [[[UIApplication sharedApplication] delegate] window];
}

@end
