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
    self.msgString = [[NSMutableString alloc] initWithCapacity:500];
    return self;
}
-(id) initWithString:(NSString *)msgString{
    self = [super init];
    self.msgString = [[NSMutableString alloc] initWithCapacity:500];
    [self.msgString appendString:msgString];
    return self;
}
-(void) removeLast{
    if (self.msgString.length == 0)
        return;
    [self.msgString deleteCharactersInRange:NSMakeRange(self.msgString.length -1,1)];
}
@end
