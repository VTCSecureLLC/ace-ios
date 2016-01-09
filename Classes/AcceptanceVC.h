//
//  AcceptanceVC.h
//  linphone
//
//  Created by User on 29/12/15.
//
//

#import <UIKit/UIKit.h>

@protocol AcceptanceVCDelegate <NSObject>

- (void)didAccept;

@end


@interface AcceptanceVC : UIViewController
@property (weak, nonatomic) id <AcceptanceVCDelegate> delegate;
@end
