//
//  DateTimePicker.m
//  amTaxi
//
//  Created by Edgar Sukiasyan on 4/27/15.
//  Copyright (c) 2015 Home. All rights reserved.
//

#import "UICustomPicker.h"
#import "WizardViewController.h"
@interface UICustomPicker () <UIPickerViewDelegate, UIPickerViewDataSource> {
    UIPickerView *pickerView;
    
    NSArray *arraySource;
}

- (void) onButtonCancel:(id)sender;
- (void) onButtonSelect:(id)sender;

@end

@implementation UICustomPicker

@synthesize delegate = _delegate;
@synthesize datePickerMode = _datePickerMode;

- (id) initWithFrame:(CGRect)frame SourceList:(NSArray*)sourceList {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setBackgroundColor:[UIColor darkGrayColor]];//[UIColor colorWithRed:0.0 green:56.0/255.0 blue:88.0/255.0 alpha:1.0]];
        
        arraySource = sourceList;
        
        pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 200, self.frame.size.width, 200)];
        pickerView.delegate = self;
        pickerView.dataSource = self;
        [self addSubview:pickerView];
        
        UIView *viewButtonsBG = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 48)];
        [viewButtonsBG setBackgroundColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.25]];
        [self addSubview:viewButtonsBG];
        
        UIButton *buttonCancel = [[UIButton alloc] initWithFrame:CGRectMake(0, 8, 70, 30)];
        [buttonCancel setTitle:@"Cancel" forState:UIControlStateNormal];
        [buttonCancel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [buttonCancel addTarget:self action:@selector(onButtonCancel:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:buttonCancel];

        UIButton *buttonSelect = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width - 70, 8, 70, 30)];
        [buttonSelect setTitle:@"Select" forState:UIControlStateNormal];
        [buttonSelect setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [buttonSelect addTarget:self action:@selector(onButtonSelect:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:buttonSelect];
    }
    
    return self;
}

- (void) onButtonCancel:(id)sender {
    if ([_delegate respondsToSelector:@selector(didCancelUICustomPicker:)]) {
        [_delegate didCancelUICustomPicker:self];
    }
    [self removeFromSuperview];
}

- (void) onButtonSelect:(id)sender {
    [self onButtonCancel:nil];
    
    if ([_delegate respondsToSelector:@selector(didSelectUICustomPicker:selectedItem:)]) {
        NSInteger row = [pickerView selectedRowInComponent:0];
        NSString *item = [arraySource objectAtIndex:row];
        [_delegate didSelectUICustomPicker:self selectedItem:item];
    }
    if ([_delegate respondsToSelector:@selector(didSelectUICustomPicker:didSelectRow:)]) {
        [_delegate didSelectUICustomPicker:self didSelectRow:_selectedRow];
    }
}

#pragma mark - UIPickerView DataSource

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return arraySource.count;
}

#pragma mark - UIPickerView Delegate

//- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
//    return [arraySource objectAtIndex:row];
//}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    _selectedRow = row;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *title = [arraySource objectAtIndex:row];
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    return attString;
    
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    NSString *imgResource;
    /*Load hard baked logos for beta stability.
     Going forward we will be loading these from the CDN*/
    if([WizardViewController getProvidersFromCDN] != nil){
        if([[[[WizardViewController getProvidersFromCDN] objectAtIndex:row] lowercaseString] containsString:@"sorenson"]){
            imgResource = @"provider0.png";
        }
        else if([[[[WizardViewController getProvidersFromCDN] objectAtIndex:row] lowercaseString] containsString:@"zvrs"]){
            imgResource = @"provider1.png";
        }
        else if([[[[WizardViewController getProvidersFromCDN] objectAtIndex:row] lowercaseString]  containsString:@"star"]){
            imgResource = @"provider2.png";
        }
        else if([[[[WizardViewController getProvidersFromCDN] objectAtIndex:row] lowercaseString]  containsString:@"convo"]){
            imgResource = @"provider5.png";
        }
        else if([[[[WizardViewController getProvidersFromCDN] objectAtIndex:row] lowercaseString] containsString:@"global"]){
            imgResource = @"provider4.png";
        }
        else if([[[[WizardViewController getProvidersFromCDN] objectAtIndex:row] lowercaseString] containsString:@"purple"]){
            imgResource = @"provider3.png";
        }
        else if([[[[WizardViewController getProvidersFromCDN] objectAtIndex:row] lowercaseString] containsString:@"ace"]){
            imgResource = @"ace_icon2x.png";
        }
    }
    
    if(!imgResource){
        imgResource = @"ace_icon2x.png";
    }
    
    UIImage *img = [UIImage imageNamed:imgResource];
    UIImageView *providerImageView = [[UIImageView alloc] initWithImage:img];
    providerImageView.frame = CGRectMake(-15, 18, 25, 25);
    
    UILabel *providerLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 150, 60)];
    providerLabel.text = [arraySource objectAtIndex:row];
    providerLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17.0f];
    providerLabel.textAlignment = NSTextAlignmentLeft;
    providerLabel.textColor = [UIColor whiteColor];
    providerLabel.backgroundColor = [UIColor clearColor];
    
    UIView *rowViw = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 110, 60)];
    [rowViw insertSubview:providerImageView atIndex:0];
    [rowViw insertSubview:providerLabel atIndex:1];
    
    return rowViw;
}

@end
