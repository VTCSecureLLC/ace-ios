//
//  DialUnitView.h
//  linphone
//
//  Created by Hrachya Stepanyan on 4/29/16.
//
//

#import <UIKit/UIKit.h>


typedef void (^DialUnitViewCallback)(UIButton *);


@interface DialUnitView : UIView

@property (nonatomic, copy) NSString *numericText;
@property (nonatomic, copy) NSString *alphabetText;
@property (nonatomic, weak) UIFont *numericFont;
@property (nonatomic, weak) UIFont *alphabetFont;
@property (nonatomic, copy) DialUnitViewCallback dialUnitViewCallback;

@end
