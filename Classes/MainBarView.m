//
//  MainBarView.m
//  linphone
//
//  Created by Misha Torosyan on 4/6/16.
//
//

#import "MainBarView.h"

@interface MainBarView ()

@property (weak, nonatomic) IBOutlet UIView *moreContainerView;
@property (weak, nonatomic) IBOutlet UIView *barView;

@end

@implementation MainBarView

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    
    if (CGRectContainsPoint(_barView.frame, point)) {
        return YES;
    }
    else if (CGRectContainsPoint(_moreContainerView.frame, point) && _moreContainerView.tag) {
        return YES;
    }
    
    return NO;
}


@end
