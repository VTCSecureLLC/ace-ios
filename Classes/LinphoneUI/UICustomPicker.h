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

- (id) initWithFrame:(CGRect)frame SourceList:(NSArray*)sourceList;
-(void) setDataSource:(NSArray*)_dataSource;
@property (nonatomic, assign) id<UICustomPickerDelegate> delegate;
@property (nonatomic, assign) UIDatePickerMode datePickerMode;
@property (nonatomic, assign)  NSInteger selectedRow;
@end

@protocol UICustomPickerDelegate <NSObject>

@optional
- (void) didSelectUICustomPicker:(UICustomPicker*)customPicker selectedItem:(NSString*)item;
- (void) didSelectUICustomPicker:(UICustomPicker*)customPicker didSelectRow:(NSInteger)row;
- (void) didCancelUICustomPicker:(UICustomPicker*)customPicker;

@end