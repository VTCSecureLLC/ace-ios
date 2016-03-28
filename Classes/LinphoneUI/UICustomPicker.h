//
//  DateTimePicker.h
//  amTaxi
//
//  Created by Ruben Semerjyan on 4/27/15.
//  Copyright (c) 2015 VTCSecure. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UICustomPickerDelegate;

@interface UICustomPicker : UIView

@property (nonatomic, assign) id <UICustomPickerDelegate> delegate;
@property (nonatomic, assign) UIDatePickerMode datePickerMode;
@property (nonatomic, assign) NSInteger selectedRow;

- (id)initWithFrame:(CGRect)frame SourceList:(NSArray*)sourceList;
- (void)setDataSource:(NSArray*)_dataSource;

@end

@protocol UICustomPickerDelegate <NSObject>

@optional

- (UIFont *)fontForRow:(NSInteger)row forComponent:(NSInteger)component;
- (void) didSelectUICustomPicker:(UICustomPicker*)customPicker selectedItem:(NSString*)item;
- (void) didSelectUICustomPicker:(UICustomPicker*)customPicker didSelectRow:(NSInteger)row;
- (void) didCancelUICustomPicker:(UICustomPicker*)customPicker;

@end