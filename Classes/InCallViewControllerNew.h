//
//  InCallViewControllerNew.h
//  linphone
//
//  Created by Hrachya Stepanyan on 3/1/16.
//
//

#import <UIKit/UIKit.h>

@interface InCallViewControllerNew : UIViewController

@property (nonatomic, readonly) UITextPosition *beginningOfDocument;
@property (nonatomic, readonly) UITextPosition *endOfDocument;
@property (nonatomic, readonly) id<UITextInputTokenizer> tokenizer;
@property (nonatomic, assign) id<UITextInputDelegate> inputDelegate;
@property (nonatomic, readonly) UITextRange *markedTextRange;
@property (nonatomic, copy) NSDictionary *markedTextStyle;
@property (readwrite, copy) UITextRange *selectedTextRange;

@end
