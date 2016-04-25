//
//  ReasonErrorHandler.m
//  linphone
//
//  Created by Misha Torosyan on 4/15/16.
//
//

#import "ReasonErrorHandler.h"
#import "ReasonError.h"

#define kReasonErrorFile   @"ResasonErrors"
#define kAlertDismissDelay 5.f

@interface ReasonErrorHandler () <UIAlertViewDelegate>

@property (nonatomic, strong) UIAlertView *errorAlertView;

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
    
    return  reasonData;
}

- (void)showReasonWithError:(ReasonError *)reasonError {
    
    NSString *reasonErrorMessage = [NSString stringWithFormat:@"%@", reasonError];
    
    self.errorAlertView = [[UIAlertView alloc] initWithTitle:nil
                                                    message:reasonErrorMessage
                                                   delegate:self
                                          cancelButtonTitle:@"Dismiss"
                                          otherButtonTitles:nil, nil];
    self.errorAlertView.delegate = self;
    [self.errorAlertView show];
    [self performSelector:@selector(dismissAlertWithError:) withObject:reasonError afterDelay:kAlertDismissDelay];
}

- (void)dismissAlertWithError:(ReasonError *)error {
    
    [self.errorAlertView dismissWithClickedButtonIndex:0 animated:YES];
    self.errorAlertView = nil;
}

#pragma mark - 

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (self.alertViewWillDismissComplitionBlock) {
        self.alertViewWillDismissComplitionBlock(nil);
    }
}

@end
