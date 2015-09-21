//
//  DateTimePicker.h
//  amTaxi
//
//  Created by Edgar Sukiasyan on 4/27/15.
//  Copyright (c) 2015 Home. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UICustomPickerDelegate;

@interface UICustomPicker : UIView

- (id) initWithFrame:(CGRect)frame SourceList:(NSArray*)sourceList;

@property (nonatomic, assign) id<UICustomPickerDelegate> delegate;
@property (nonatomic, assign) UIDatePickerMode datePickerMode;

@end

@protocol UICustomPickerDelegate <NSObject>

@optional

- (void) didSelectUICustomPicker:(UICustomPicker*)customPicker selectedItem:(NSString*)item;

@end