//
//  UICallCellDataNew.h
//  linphone
//
//  Created by Ruben Semerjyan on 3/15/16.
//
//

#import <Foundation/Foundation.h>
#include "linphone/linphonecore.h"

typedef enum _UICallCellOtherView {
    UICallCellOtherView_Avatar = 0,
    UICallCellOtherView_AudioStats,
    UICallCellOtherView_VideoStats,
    UICallCellOtherView_MAX
} UICallCellOtherView;

@interface UICallCellDataNew : NSObject

@property (nonatomic, assign) BOOL minimize;
@property (nonatomic, assign) UICallCellOtherView view;
@property (nonatomic, assign) LinphoneCall *call;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *address;

- (id)init:(LinphoneCall*) call minimized:(BOOL)minimized;

@end
