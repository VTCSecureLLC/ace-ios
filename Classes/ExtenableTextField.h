//
//  ExtenableLabel.h
//  ecTouch
//
//  Created by Simon Jakobsson on 31/08/15.
//
//

#import <UIKit/UIKit.h>

@interface ExtenableTextField : UITextView {
    NSMutableString *labelString;
}

-(void)removeLast;
-(void)appendWithString:(NSString*)str;

@end
