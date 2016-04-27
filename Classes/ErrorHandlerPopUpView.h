//
//  ErrorHandlerPopUpView.h
//  linphone
//
//  Created by Misha Torosyan on 4/26/16.
//
//

#import "PopUpView.h"

@class ReasonError;

@interface ErrorHandlerPopUpView : PopUpView

+ (nonnull instancetype)popUpView;

- (void)showWithCompletion:(nullable CompletionBlock)completion;

- (void)fillWithMessage:(nonnull NSString *)message;

@end
