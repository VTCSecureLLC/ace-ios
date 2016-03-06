//
//  IncomingCallMessageTableViewController.m
//  linphone
//
//  Created by Ruben Semerjyan on 3/2/16.
//
//

#import "IncomingCallMessageTableViewController.h"


@interface IncomingCallMessageTableViewController ()

@end


@implementation IncomingCallMessageTableViewController

#pragma mark - Life Cycle
- (void)viewDidLoad {
    
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.messageDidSelectedCallback) {
        self.messageDidSelectedCallback(indexPath.row);
    }
}

@end
