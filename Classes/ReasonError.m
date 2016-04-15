//
//  ReasonError.m
//  linphone
//
//  Created by Misha Torosyan on 4/15/16.
//
//

#import "ReasonError.h"

#define kMessage @"message"
#define kCode    @"code"

@implementation ReasonError

- (instancetype)initWithDictionary:(NSDictionary <NSString *, NSString *> *)dict {
    
    self = [super init];
    if (self) {
        
        _message = dict[kMessage];
        _code = (NSNumber *)dict[kCode];
    }
    
    return self;
}

- (NSString *)description {
    
    NSString *description;
    if (_message.length > 0 && _code) {
        description = [NSString stringWithFormat:@"%@(sip:%@)", _message, _code];
    }
    else if (_message.length > 0) {
        description = [NSString stringWithFormat:@"%@", _message];
    }
    else {
        description = [NSString stringWithFormat:@"sip:%@", _code];
    }
    
    return description;
}

@end
