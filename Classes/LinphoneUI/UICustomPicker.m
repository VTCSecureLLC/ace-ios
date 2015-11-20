//
//  DateTimePicker.m
//  amTaxi
//
//  Created by Edgar Sukiasyan on 4/27/15.
//  Copyright (c) 2015 Home. All rights reserved.
//

#import "UICustomPicker.h"

@interface UICustomPicker () <UIPickerViewDelegate, UIPickerViewDataSource> {
    UIPickerView *pickerView;
    
    NSArray *arraySource;
    NSInteger selectedRow;
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
        [self setBackgroundColor:[UIColor colorWithRed:0.0 green:56.0/255.0 blue:88.0/255.0 alpha:1.0]];
        
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
        [_delegate didSelectUICustomPicker:self didSelectRow:selectedRow];
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
    selectedRow = row;
}

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSString *title = [arraySource objectAtIndex:row];
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:title attributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    return attString;
    
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    
    
    
}

@end
