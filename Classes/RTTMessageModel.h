//
//  RTTMessageModel.h
//  linphone
//
//  Created by Zack Matthews on 11/19/15.
//
//

#import <Foundation/Foundation.h>

@interface RTTMessageModel : NSObject
@property NSString *msgString;
@property UIColor *color;

-(id) initWithString: (NSString*)msgString;
@end
