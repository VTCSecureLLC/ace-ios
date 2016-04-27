//
//  ReasonErrorHandler.m
//  linphone
//
//  Created by Misha Torosyan on 4/15/16.
//
//

#import "ReasonErrorHandler.h"
#import "ReasonError.h"
#import "ErrorHandlerPopUpView.h"

#define kReasonErrorFile   @"ResasonErrors"
#define kPopUpDismissDelay 5.f

@interface ReasonErrorHandler ()

@property (nonatomic, strong) ErrorHandlerPopUpView *popUpView;

@end

@implementation ReasonErrorHandler

#pragma mark - Lifecycle Methods
+ (instancetype)sharedInstance {
    
    static dispatch_once_t onceToken;
    static ReasonErrorHandler *errorHandler;
    
    dispatch_once(&onceToken, ^{
        errorHandler = [[ReasonErrorHandler alloc] init];
    });
    
    return errorHandler;
}


#pragma mark - Instance Methods
- (void)showErrorForLinphoneReason:(LinphoneReason)reason {
    
    ReasonError *error = [self errorWithReason:reason];
    [self showReasonWithError:error];
}

- (NSString *)stateStringForReason:(LinphoneReason)reason {
    
    NSDictionary * const reasonStateStrings = @{
                                                @(LinphoneReasonNone) : @"LinphoneReasonNone",
                                                @(LinphoneReasonNoResponse) : @"LinphoneReasonNoResponse",
                                                @(LinphoneReasonAddressIncomplete) : @"LinphoneReasonAddressIncomplete",
                                                @(LinphoneReasonForbidden) : @"LinphoneReasonForbidden",
                                                @(LinphoneReasonBadGateway) : @"LinphoneReasonBadGateway",
                                                @(LinphoneReasonBusy) : @"LinphoneReasonBusy",
                                                @(LinphoneReasonDeclined) : @"LinphoneReasonDeclined",
                                                @(LinphoneReasonDoNotDisturb) : @"LinphoneReasonDoNotDisturb",
                                                @(LinphoneReasonGone) : @"LinphoneReasonGone",
                                                @(LinphoneReasonIOError) : @"LinphoneReasonIOError",
                                                @(LinphoneReasonMovedPermanently) : @"LinphoneReasonMovedPermanently",
                                                @(LinphoneReasonNoMatch) : @"LinphoneReasonNoMatch",
                                                @(LinphoneReasonNotAcceptable) : @"LinphoneReasonNotAcceptable",
                                                @(LinphoneReasonNotAnswered) : @"LinphoneReasonNotAnswered",
                                                @(LinphoneReasonNotFound) : @"LinphoneReasonNotFound",
                                                @(LinphoneReasonNotImplemented) : @"LinphoneReasonNotImplemented",
                                                @(LinphoneReasonServerTimeout) : @"LinphoneReasonServerTimeout",
                                                @(LinphoneReasonTemporarilyUnavailable) : @"LinphoneReasonTemporarilyUnavailable",
                                                @(LinphoneReasonUnauthorized) : @"LinphoneReasonUnauthorized",
                                                @(LinphoneReasonUnknown) : @"LinphoneReasonUnknown",
                                                @(LinphoneReasonUnsupportedContent) : @"LinphoneReasonUnsupportedContent",
                                                };
    
    return reasonStateStrings[@(reason)];
}

- (ReasonError *)errorWithReason:(LinphoneReason)reason {
    
    NSDictionary *reasonData = [self reasonData];
    NSString *reasonName = [self stateStringForReason:reason];
    ReasonError *reasonError = [[ReasonError alloc] initWithDictionary:reasonData[reasonName]];
    
    return reasonError;
}

- (NSDictionary *)reasonData {
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:kReasonErrorFile ofType:@"plist"];
    NSDictionary *reasonData = [NSDictionary dictionaryWithContentsOfFile:filePath];
    
    return reasonData;
}

- (void)showReasonWithError:(ReasonError *)reasonError {
    
    NSString *reasonErrorMessage = [NSString stringWithFormat:@"%@", reasonError];
    
    self.popUpView = [ErrorHandlerPopUpView popUpView];
    [self.popUpView fillWithMessage:reasonErrorMessage];
    
    __weak ReasonErrorHandler *weakSelf = self;
    [self.popUpView showWithCompletion:^{
        [weakSelf.popUpView hideAfterDelay:kPopUpDismissDelay withCompletion:^{
            weakSelf.popUpViewWillDismissComplitionBlock();
        }];
    }];
}

- (void)closeErrorView {
    
    __weak ReasonErrorHandler *weakSelf = self;
    [self.popUpView hideAfterDelay:0 withCompletion:^{
        weakSelf.popUpViewWillDismissComplitionBlock();
    }];
}
@end
