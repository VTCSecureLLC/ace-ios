//
//  ErrorHandlerPopUpView.m
//  linphone
//
//  Created by Misha Torosyan on 4/26/16.
//
//

#import "ErrorHandlerPopUpView.h"
#import "ReasonError.h"

@interface ErrorHandlerPopUpView ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end

@implementation ErrorHandlerPopUpView

#pragma mark - Static Methods
+ (nonnull instancetype)popUpView {
    
    ErrorHandlerPopUpView *errorHandlerPopUpView = [ErrorHandlerPopUpView loadFromXib];
    [errorHandlerPopUpView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    return errorHandlerPopUpView;
}


#pragma makrk - Public Methods
- (void)showWithCompletion:(CompletionBlock)completion {
    
    [self.window addSubview:self];
    [self setupConstraints];
    [self attachShowingAnimationWithCompletion:completion];
}

- (void)fillWithMessage:(nonnull NSString *)message {
    
    self.titleLabel.text = message;
}


#pragma mark - Private Methods
- (void)setupConstraints {
    
    UIView *window = self.window;
    
    [window addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                       attribute:NSLayoutAttributeLeading
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:window
                                                       attribute:NSLayoutAttributeLeading
                                                      multiplier:1.0
                                                        constant:0.0]];
    
    [window addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                       attribute:NSLayoutAttributeTrailing
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:window
                                                       attribute:NSLayoutAttributeTrailing
                                                      multiplier:1.0
                                                        constant:0.0]];
    
    [window addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                       attribute:NSLayoutAttributeBottom
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:window
                                                       attribute:NSLayoutAttributeBottom
                                                      multiplier:1.0
                                                        constant:0.0]];
    
    [window addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                       attribute:NSLayoutAttributeHeight
                                                       relatedBy:NSLayoutRelationEqual
                                                          toItem:window
                                                       attribute:NSLayoutAttributeHeight
                                                      multiplier:1.0
                                                        constant:0.0]];
    
    [window layoutIfNeeded];
}


@end
