//
//  BaseView.m
//  PTO
//
//  Created by Ruben Semerjyan on 12/2/15.
//  Copyright © 2015 VTCSecure. All rights reserved.
//

#import "BaseView.h"

@implementation BaseView


#pragma mark - Initialization

//@brief  Loads view from xib
- (void)load {
    
    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class])
                                                         owner:self
                                                       options:nil];
    
    UIView *xibView = [nibContents lastObject];
    [xibView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:xibView];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[xibView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(xibView)]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[xibView]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:NSDictionaryOfVariableBindings(xibView)]];
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self load];
    }
    return self;
}


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self load];
    }
    return self;
}

@end
