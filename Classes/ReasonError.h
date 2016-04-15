//
//  ReasonError.h
//  linphone
//
//  Created by Misha Torosyan on 4/15/16.
//
//

#import <Foundation/Foundation.h>

@interface ReasonError : NSObject

@property (nonatomic, strong, readonly) NSString *message;
@property (nonatomic, strong, readonly) NSNumber *code;

- (instancetype)initWithDictionary:(NSDictionary <NSString *, NSString *> *)dict;

@end
