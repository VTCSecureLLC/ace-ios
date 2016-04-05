//
//  MainMenuBarView.h
//  linphone
//
//  Created by Ruben Semerjyan on 4/5/16.
//
//

#import "BaseView.h"
#import "InCallViewConstants.h"
#import "TPMultiLayoutViewController.h"

@interface MainMenuBarView : TPMultiLayoutViewController

@property (nonatomic, copy) ButtonActionHandler historyButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler contactsButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler dialpadButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler chatButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler moreButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler settingsButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler resourcesButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler videomailButtonActionHandler;
@property (nonatomic, copy) ButtonActionHandler selfPreviewButtonActionHandler;

@end
