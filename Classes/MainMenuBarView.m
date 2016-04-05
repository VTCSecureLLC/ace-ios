//
//  MainMenuBarView.m
//  linphone
//
//  Created by Ruben Semerjyan on 4/5/16.
//
//

#import "MainMenuBarView.h"
#import "CustomBarButton.h"
#import "PhoneMainView.h"

#define kAnimationDuration 0.5f

@interface MainMenuBarView ()

@property (weak, nonatomic) IBOutlet CustomBarButton *historyButton;
@property (weak, nonatomic) IBOutlet CustomBarButton *contactsButton;
@property (weak, nonatomic) IBOutlet CustomBarButton *dialpadButton;
@property (weak, nonatomic) IBOutlet CustomBarButton *chatButton;
@property (weak, nonatomic) IBOutlet CustomBarButton *moreButton;
@property (weak, nonatomic) IBOutlet UIView *moreMenuContainer;

@end


@implementation MainMenuBarView

#pragma mark - Life Cicle
- (instancetype)init {
    self = [super initWithNibName:@"MainMenuBarView" bundle:[NSBundle mainBundle]];
    if (self) {
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self update:FALSE];
}


#pragma mark - Private Methods

- (void)update:(BOOL)appear {
    [self updateView:[[PhoneMainView instance] firstView]];
//    [self updateMissedCall:linphone_core_get_missed_calls_count([LinphoneManager getLc]) appear:appear];
    
    //Remove Unread Messages Count on iPhone
    
    //[self updateUnreadMessage:appear];
}

- (void)updateView:(UICompositeViewDescription *)view {
    // Update buttons
    if ([view equal:[HistoryViewController compositeViewDescription]]) {
        self.historyButton.selected = TRUE;
    } else {
        self.historyButton.selected = FALSE;
    }
    if ([view equal:[ContactsViewController compositeViewDescription]]) {
        self.contactsButton.selected = TRUE;
    } else {
        self.contactsButton.selected = FALSE;
    }
    if ([view equal:[DialerViewController compositeViewDescription]]) {
//        self.dialerButton.selected = TRUE;
    } else {
//        self.dialerButton.selected = FALSE;
    }
    if ([view equal:[SettingsViewController compositeViewDescription]]) {
//        settingsButton.selected = TRUE;
    } else {
//        settingsButton.selected = FALSE;
    }
    if ([view equal:[HelpViewController compositeViewDescription]]) {
//        chatButton.selected = TRUE;
    } else {
//        chatButton.selected = FALSE;
    }
}

#pragma mark - Animation

- (void)showMoreMenu {
    
    self.moreMenuContainer.hidden = NO;
    self.moreMenuContainer.tag = 1;
    // Automatic hiding
    [UIView animateWithDuration:kAnimationDuration
                     animations:^{
                         self.moreMenuContainer.alpha = 1;
                         [self.moreButton setSelected:YES];
                     }];
}

- (void)hideMoreMenu {
    
    self.moreMenuContainer.tag = 0;
    
    [UIView animateWithDuration:kAnimationDuration
                     animations:^{
                         self.moreMenuContainer.alpha = 0;
                         [self.moreButton setSelected:NO];
                     }];
}

#pragma mark - Action Methods
- (IBAction)historyButtonAction:(UIButton *)sender {
    
    if (self.historyButtonActionHandler) {
        self.historyButtonActionHandler(sender);
    }
}

- (IBAction)contactsButtonAction:(UIButton *)sender {
    
    if (self.contactsButtonActionHandler) {
        self.contactsButtonActionHandler(sender);
    }
}

- (IBAction)dialpadButtonAction:(UIButton *)sender {
    
    if (self.dialpadButtonActionHandler) {
        self.dialpadButtonActionHandler(sender);
    }
}

- (IBAction)chatButtonAction:(UIButton *)sender {
    
    if (self.chatButtonActionHandler) {
        self.chatButtonActionHandler(sender);
    }
}

- (IBAction)moreButtonAction:(UIButton *)sender {
    
    if (self.moreMenuContainer.tag == 0) {
        
        [self showMoreMenu];
    }
    else {
        
        [self hideMoreMenu];
    }

    
    if (self.moreButtonActionHandler) {
        self.moreButtonActionHandler(sender);
    }
}


#pragma mark -- More Menu
- (IBAction)settingsButtonAction:(UIButton *)sender {
    
    if (self.settingsButtonActionHandler) {
        self.settingsButtonActionHandler(sender);
    }
}

- (IBAction)resourcesButtonAction:(UIButton *)sender {
    
    if (self.resourcesButtonActionHandler) {
        self.resourcesButtonActionHandler(sender);
    }
}

- (IBAction)videomailButtonAction:(UIButton *)sender {
    
    if (self.videomailButtonActionHandler) {
        self.videomailButtonActionHandler(sender);
    }
}

- (IBAction)selfPreviewButtonAction:(UIButton *)sender {
    
    if (self.selfPreviewButtonActionHandler) {
        self.selfPreviewButtonActionHandler(sender);
    }
}

@end
