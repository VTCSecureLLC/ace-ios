//
//  InCallDialpadView.m
//  linphone
//
//  Created by Hrachya Stepanyan on 3/9/16.
//
//

#import "InCallDialpadView.h"
#import "UIDigitButton.h"
#import "DialUnitView.h"

#define kAnimationDuration 0.5f
#define kPortraitNumericFontSize 44.0
#define kPortraitAlphabetFontSize 12.0
#define kLandscapeNumericFontSize 24.0
#define kLandscapeAlphabetFontSize 8.0


@interface InCallDialpadView ()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;

@property (nonatomic, strong) IBOutlet DialUnitView * oneButtonView;
@property (nonatomic, strong) IBOutlet DialUnitView * twoButtonView;
@property (nonatomic, strong) IBOutlet DialUnitView * threeButtonView;
@property (nonatomic, strong) IBOutlet DialUnitView * fourButtonView;
@property (nonatomic, strong) IBOutlet DialUnitView * fiveButtonView;
@property (nonatomic, strong) IBOutlet DialUnitView * sixButtonView;
@property (nonatomic, strong) IBOutlet DialUnitView * sevenButtonView;
@property (nonatomic, strong) IBOutlet DialUnitView * eightButtonView;
@property (nonatomic, strong) IBOutlet DialUnitView * nineButtonView;
@property (nonatomic, strong) IBOutlet DialUnitView * starButtonView;
@property (nonatomic, strong) IBOutlet DialUnitView * zeroButtonView;
@property (nonatomic, strong) IBOutlet DialUnitView * sharpButtonView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewBottomConstraint;

@end

@implementation InCallDialpadView

#pragma mark - Override methods
- (void)awakeFromNib {
    
    [self setupButtons];
}


#pragma mark - Instance methods

- (void)adjustButtons {
    
    UIFont *numberFont = nil;
    UIFont *alphabetFont = nil;
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication]statusBarOrientation])) {
        numberFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:kPortraitNumericFontSize];
        alphabetFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:kPortraitAlphabetFontSize];
    }
    else {
        numberFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:kLandscapeNumericFontSize];
        alphabetFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:kLandscapeAlphabetFontSize];
    }
    
    _oneButtonView.numericFont = numberFont;
    _oneButtonView.alphabetFont = alphabetFont;
    
    _twoButtonView.numericFont = numberFont;
    _twoButtonView.alphabetFont = alphabetFont;
    
    _threeButtonView.numericFont = numberFont;
    _threeButtonView.alphabetFont = alphabetFont;
    
    _fourButtonView.numericFont = numberFont;
    _fourButtonView.alphabetFont = alphabetFont;
    
    _fiveButtonView.numericFont = numberFont;
    _fiveButtonView.alphabetFont = alphabetFont;
    
    _sixButtonView.numericFont = numberFont;
    _sixButtonView.alphabetFont = alphabetFont;
    
    _sevenButtonView.numericFont = numberFont;
    _sevenButtonView.alphabetFont = alphabetFont;
    
    _eightButtonView.numericFont = numberFont;
    _eightButtonView.alphabetFont = alphabetFont;
    
    _nineButtonView.numericFont = numberFont;
    _nineButtonView.alphabetFont = alphabetFont;
    
    _starButtonView.numericFont = numberFont;
    _starButtonView.alphabetFont = alphabetFont;
    
    _zeroButtonView.numericFont = numberFont;
    _zeroButtonView.alphabetFont = alphabetFont;
    
    _sharpButtonView.numericFont = numberFont;
    _sharpButtonView.alphabetFont = alphabetFont;
}

- (void)setupButtons {
    
    UIFont *numberFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:kPortraitAlphabetFontSize];
    UIFont *alphabetFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:kPortraitAlphabetFontSize];
    
    __weak InCallDialpadView *weakSelf = self;
    _oneButtonView.numericFont = numberFont;
    _oneButtonView.alphabetFont = alphabetFont;
    _oneButtonView.numericText = @"1";
    _oneButtonView.alphabetText = @"";
    _oneButtonView.dialUnitViewCallback = ^(UIButton *sender) {
        
        if (weakSelf.oneButtonHandler) {
            weakSelf.oneButtonHandler(sender);
        }
    };
    
    _twoButtonView.numericFont = numberFont;
    _twoButtonView.alphabetFont = alphabetFont;
    _twoButtonView.numericText = @"2";
    _twoButtonView.alphabetText = @"ABC";
    _twoButtonView.dialUnitViewCallback = ^(UIButton *sender) {
        
        if (weakSelf.twoButtonHandler) {
            weakSelf.twoButtonHandler(sender);
        }
    };
    
    _threeButtonView.numericFont = numberFont;
    _threeButtonView.alphabetFont = alphabetFont;
    _threeButtonView.numericText = @"3";
    _threeButtonView.alphabetText = @"DEF";
    _threeButtonView.dialUnitViewCallback = ^(UIButton *sender) {
        
        if (weakSelf.threeButtonHandler) {
            weakSelf.threeButtonHandler(sender);
        }
    };
    
    _fourButtonView.numericFont = numberFont;
    _fourButtonView.alphabetFont = alphabetFont;
    _fourButtonView.numericText = @"4";
    _fourButtonView.alphabetText = @"GHI";
    _fourButtonView.dialUnitViewCallback = ^(UIButton *sender) {
        
        if (weakSelf.fourButtonHandler) {
            weakSelf.fourButtonHandler(sender);
        }
    };
    
    _fiveButtonView.numericFont = numberFont;
    _fiveButtonView.alphabetFont = alphabetFont;
    _fiveButtonView.numericText = @"5";
    _fiveButtonView.alphabetText = @"JKL";
    _fiveButtonView.dialUnitViewCallback = ^(UIButton *sender) {
        
        if (weakSelf.fiveButtonHandler) {
            weakSelf.fiveButtonHandler(sender);
        }
    };
    
    _sixButtonView.numericFont = numberFont;
    _sixButtonView.alphabetFont = alphabetFont;
    _sixButtonView.numericText = @"6";
    _sixButtonView.alphabetText = @"MNO";
    _sixButtonView.dialUnitViewCallback = ^(UIButton *sender) {
        
        if (weakSelf.sixButtonHandler) {
            weakSelf.sixButtonHandler(sender);
        }
    };
    _sevenButtonView.numericFont = numberFont;
    _sevenButtonView.alphabetFont = alphabetFont;
    _sevenButtonView.numericText = @"7";
    _sevenButtonView.alphabetText = @"PQRS";
    _sevenButtonView.dialUnitViewCallback = ^(UIButton *sender) {
        
        if (weakSelf.sevenButtonHandler) {
            weakSelf.sevenButtonHandler(sender);
        }
    };
    
    _eightButtonView.numericFont = numberFont;
    _eightButtonView.alphabetFont = alphabetFont;
    _eightButtonView.numericText = @"8";
    _eightButtonView.alphabetText = @"TUV";
    _eightButtonView.dialUnitViewCallback = ^(UIButton *sender) {
        
        if (weakSelf.eightButtonHandler) {
            weakSelf.eightButtonHandler(sender);
        }
    };
    
    _nineButtonView.numericFont = numberFont;
    _nineButtonView.alphabetFont = alphabetFont;
    _nineButtonView.numericText = @"9";
    _nineButtonView.alphabetText = @"WXYZ";
    _nineButtonView.dialUnitViewCallback = ^(UIButton *sender) {
        
        if (weakSelf.nineButtonHandler) {
            weakSelf.nineButtonHandler(sender);
        }
    };
    
    _starButtonView.numericFont = numberFont;
    _starButtonView.alphabetFont = alphabetFont;
    _starButtonView.numericText = @"*";
    _starButtonView.alphabetText = @"";
    _starButtonView.dialUnitViewCallback = ^(UIButton *sender) {
        
        if (weakSelf.starButtonHandler) {
            weakSelf.starButtonHandler(sender);
        }
    };
    
    _zeroButtonView.numericFont = numberFont;
    _zeroButtonView.alphabetFont = alphabetFont;
    _zeroButtonView.numericText = @"0";
    _zeroButtonView.alphabetText = @"+";
    _zeroButtonView.dialUnitViewCallback = ^(UIButton *sender) {
        
        if (weakSelf.zeroButtonHandler) {
            weakSelf.zeroButtonHandler(sender);
        }
    };
    
    _sharpButtonView.numericFont = numberFont;
    _sharpButtonView.alphabetFont = alphabetFont;
    _sharpButtonView.numericText = @"#";
    _sharpButtonView.alphabetText = @"";
    _sharpButtonView.dialUnitViewCallback = ^(UIButton *sender) {
        
        if (weakSelf.sharpButtonHandler) {
            weakSelf.sharpButtonHandler(sender);
        }
    };
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self adjustButtons];
}


#pragma mark - Animatons
- (void)showWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.viewState = VS_Animating;
    NSTimeInterval duration = animation ? kAnimationDuration : 0;
    
    [UIView animateWithDuration:duration
                     animations:^{
                         
                         self.backgroundViewBottomConstraint.constant = 0;
                         self.alpha = 1;
                         [self layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         
                         self.viewState = VS_Opened;
                         if (completion && finished) {
                             completion();
                         }
                     }];
}

- (void)hideWithAnimation:(BOOL)animation completion:(void(^)())completion {
    
    self.viewState = VS_Animating;
    NSTimeInterval duration = animation ? kAnimationDuration : 0;
    
    [UIView animateWithDuration:duration
                     animations:^{
                         
                         self.backgroundViewBottomConstraint.constant = -CGRectGetHeight(self.backgroundView.frame);
                         self.alpha = 0;
                         [self layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         
                         self.viewState = VS_Closed;
                         if (completion && finished) {
                             completion();
                         }
                     }];
}


#pragma mark - Action methods
- (IBAction)oneButtonAction:(UIButton *)sender {
    
    __weak UIButton *weakSender = sender;
    if (self.oneButtonHandler) {
        self.oneButtonHandler(weakSender);
    }
}

- (IBAction)twoButtonAction:(UIButton *)sender {
    
    __weak UIButton *weakSender = sender;
    if (self.twoButtonHandler) {
        self.twoButtonHandler(weakSender);
    }
}

- (IBAction)threeButtonAction:(UIButton *)sender {
    
    __weak UIButton *weakSender = sender;
    if (self.threeButtonHandler) {
        self.threeButtonHandler(weakSender);
    }
}

- (IBAction)fourButtonAction:(UIButton *)sender {
    
    __weak UIButton *weakSender = sender;
    if (self.fourButtonHandler) {
        self.fourButtonHandler(weakSender);
    }
}

- (IBAction)fiveButtonAction:(UIButton *)sender {
    
    __weak UIButton *weakSender = sender;
    if (self.fiveButtonHandler) {
        self.fiveButtonHandler(weakSender);
    }
}

- (IBAction)sixButtonAction:(UIButton *)sender {
    
    __weak UIButton *weakSender = sender;
    if (self.sixButtonHandler) {
        self.sixButtonHandler(weakSender);
    }
}

- (IBAction)sevenButtonAction:(UIButton *)sender {
    
    __weak UIButton *weakSender = sender;
    if (self.sevenButtonHandler) {
        self.sevenButtonHandler(weakSender);
    }
}

- (IBAction)eightButtonAction:(UIButton *)sender {
    
    __weak UIButton *weakSender = sender;
    if (self.eightButtonHandler) {
        self.eightButtonHandler(weakSender);
    }
}

- (IBAction)nineButtonAction:(UIButton *)sender {
    
    __weak UIButton *weakSender = sender;
    if (self.nineButtonHandler) {
        self.nineButtonHandler(weakSender);
    }
}

- (IBAction)starButtonAction:(UIButton *)sender {
    
    __weak UIButton *weakSender = sender;
    if (self.starButtonHandler) {
        self.starButtonHandler(weakSender);
    }
}

- (IBAction)zeroButtonAction:(UIButton *)sender {
    
    __weak UIButton *weakSender = sender;
    if (self.zeroButtonHandler) {
        self.zeroButtonHandler(weakSender);
    }
}

- (IBAction)sharpButtonAction:(UIButton *)sender {
    
    __weak UIButton *weakSender = sender;
    if (self.sharpButtonHandler) {
        self.sharpButtonHandler(weakSender);
    }
}

@end
