//
//  ExtenableLabel.m
//  ecTouch
//
//  Created by Simon Jakobsson on 31/08/15.
//
//

#import "ExtenableTextField.h"

@interface ExtenableTextField()
@property  BOOL isReadOnly;
@end

@implementation ExtenableTextField

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        labelString = [[NSMutableString alloc]initWithCapacity:10000];
        [self setFont:[UIFont boldSystemFontOfSize:[UIFont systemFontSize] * 2]];
        self.isReadOnly = NO;
    }
    return self;
}

-(void)removeLast{
    if (self.text.length == 0)
        return;
    [labelString deleteCharactersInRange:NSMakeRange(labelString.length -1,1)];
    [self setText:labelString];
}

-(void)appendWithString:(NSString*)str{
    [labelString appendString:str];
    [self setText:labelString];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range       replacementString:(NSString *)string{
    return !self.isReadOnly;
}

-(void) setReadOnly:(BOOL)isReadOnly{
    self.isReadOnly = isReadOnly;
}

-(BOOL) shouldChangeTextInRange:(UITextRange *)range replacementText:(NSString *)text{
    return !self.isReadOnly;
}
@end
