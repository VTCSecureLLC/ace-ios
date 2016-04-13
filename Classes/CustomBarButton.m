//
//  CustomBarButton.m
//  linphone
//
//  Created by Misha Torosyan on 4/5/16.
//
//

#import "CustomBarButton.h"

@implementation CustomBarButton

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    if (selected) {
        self.backgroundColor = [UIColor colorWithRed:0.902 green:0.3569 blue:0.1569 alpha:1.0];
    }
    else {
        self.backgroundColor = [UIColor clearColor];
    }
}

@end
