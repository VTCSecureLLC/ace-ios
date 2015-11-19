//
//  RTTMessageModel.m
//  linphone
//
//  Created by Zack Matthews on 11/19/15.
//
//

#import "RTTMessageModel.h"

@implementation RTTMessageModel
- (id) init {
    self = [super init];
    return self;
}
-(id) initWithString:(NSString *)msgString{
    self = [super init];
    self.msgString = msgString;
    return self;
}
@end
