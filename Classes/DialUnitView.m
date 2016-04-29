//
//  DialUnitView.m
//  linphone
//
//  Created by Hrachya Stepanyan on 4/29/16.
//
//

#import "DialUnitView.h"

@interface DialUnitView()

@property (nonatomic, weak) IBOutlet UILabel *numericLabel;
@property (nonatomic, weak) IBOutlet UILabel *alphabetLabel;

@end


@implementation DialUnitView

- (void)load {
    
    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];
    UIView *view = [nibContents lastObject];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:view];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                 options:0
                                                                 metrics:nil
                                                                   views:views]];
}

#pragma mark - Life Cycle Methods
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self load];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self load];
    }
    
    return self;
}

- (void)setAlphabetFont:(UIFont *)alphabetFont {

    _alphabetLabel.font = alphabetFont;
}

- (void)setNumericFont:(UIFont *)numericFont {

    _numericLabel.font = numericFont;
}

- (void)setNumericText:(NSString *)numericText {

    _numericLabel.text = numericText;
}

- (void)setAlphabetText:(NSString *)alphabetText {

    _alphabetLabel.text = alphabetText;
}

- (IBAction)buttonAction:(id)sender {
    
    if (_dialUnitViewCallback) {
        _dialUnitViewCallback(sender);
    }
}

@end
