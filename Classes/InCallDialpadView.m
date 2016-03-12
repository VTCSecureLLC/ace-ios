//
//  InCallDialpadView.m
//  linphone
//
//  Created by Hrachya Stepanyan on 3/9/16.
//
//

#import "InCallDialpadView.h"
#import "UIDigitButton.h"

#define kAnimationDuration 0.5f


@interface InCallDialpadView ()

@property (weak, nonatomic) IBOutlet UIView *backgroundView;

@property (nonatomic, strong) IBOutlet UIDigitButton * oneButton;
@property (nonatomic, strong) IBOutlet UIDigitButton * twoButton;
@property (nonatomic, strong) IBOutlet UIDigitButton * threeButton;
@property (nonatomic, strong) IBOutlet UIDigitButton * fourButton;
@property (nonatomic, strong) IBOutlet UIDigitButton * fiveButton;
@property (nonatomic, strong) IBOutlet UIDigitButton * sixButton;
@property (nonatomic, strong) IBOutlet UIDigitButton * sevenButton;
@property (nonatomic, strong) IBOutlet UIDigitButton * eightButton;
@property (nonatomic, strong) IBOutlet UIDigitButton * nineButton;
@property (nonatomic, strong) IBOutlet UIDigitButton * starButton;
@property (nonatomic, strong) IBOutlet UIDigitButton * zeroButton;
@property (nonatomic, strong) IBOutlet UIDigitButton * sharpButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewBottomConstraint;

@end

@implementation InCallDialpadView

#pragma mark - Override methods
- (void)viewDidLoad {
    
    [self setupButtons];
}


#pragma mark - Instance methods
- (void)setupButtons {
    
    [_zeroButton setDigit:'0'];
    [_zeroButton setDtmf:true];
    [_oneButton setDigit:'1'];
    [_oneButton setDtmf:true];
    [_twoButton setDigit:'2'];
    [_twoButton setDtmf:true];
    [_threeButton setDigit:'3'];
    [_threeButton setDtmf:true];
    [_fourButton setDigit:'4'];
    [_fourButton setDtmf:true];
    [_fiveButton setDigit:'5'];
    [_fiveButton setDtmf:true];
    [_sixButton setDigit:'6'];
    [_sixButton setDtmf:true];
    [_sevenButton setDigit:'7'];
    [_sevenButton setDtmf:true];
    [_eightButton setDigit:'8'];
    [_eightButton setDtmf:true];
    [_nineButton setDigit:'9'];
    [_nineButton setDtmf:true];
    [_starButton setDigit:'*'];
    [_starButton setDtmf:true];
    [_sharpButton setDigit:'#'];
    [_sharpButton setDtmf:true];
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
