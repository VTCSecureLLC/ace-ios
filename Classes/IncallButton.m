//
//  IncallButton.m
//  linphone
//
//  Created by Hrachya Stepanyan on 3/1/16.
//
//

#import "IncallButton.h"

@implementation IncallButton

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    if (selected) {
        self.backgroundColor = [UIColor colorWithRed:0.902 green:0.3569 blue:0.1569 alpha:1.0];
    }
    else {
        self.backgroundColor = [UIColor clearColor];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
