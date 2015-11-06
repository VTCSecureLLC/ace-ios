//
//  ExtenableLabel.m
//  ecTouch
//
//  Created by Simon Jakobsson on 31/08/15.
//
//

#import "ExtenableTextField.h"

@implementation ExtenableTextField

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        labelString = [[NSMutableString alloc]initWithCapacity:10000];
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

@end
