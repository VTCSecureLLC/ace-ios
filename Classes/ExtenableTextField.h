//
//  ExtenableLabel.h
//  ecTouch
//
//  Created by Simon Jakobsson on 31/08/15.
//
//

#import <UIKit/UIKit.h>

@interface ExtenableRttField : UITextView {
    NSMutableString *labelString;
}

-(void)setReadOnly:(BOOL) isReadOnly;
-(void)removeLast;
-(void)appendWithString:(NSString*)str;
@end
