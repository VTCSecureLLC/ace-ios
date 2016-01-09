//
//  RTTMessageModel.h
//  linphone
//
//  Created by Zack Matthews on 11/19/15.
//
//

#import <Foundation/Foundation.h>

@interface RTTMessageModel : NSObject
@property NSMutableString *msgString;
@property UIColor *color;
@property NSAttributedString *attrMsgString;
@property NSTimeInterval modifiedTimeInterval;
-(id) initWithString: (NSString*)msgString;
-(void) removeLast;
@end
