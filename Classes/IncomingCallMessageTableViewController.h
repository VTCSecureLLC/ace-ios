//
//  IncomingCallMessageTableViewController.h
//  linphone
//
//  Created by Ruben Semerjyan on 3/2/16.
//
//

#import <UIKit/UIKit.h>

/**
 *  @brief Calls when selected cell of table view
 *
 *  @param NSUInteger Selected cell row's index
 */
typedef void (^MessageDidSelectedBlock)(NSUInteger);


@interface IncomingCallMessageTableViewController : UITableViewController

@property (nonatomic, copy) MessageDidSelectedBlock messageDidSelectedCallback;

@end
