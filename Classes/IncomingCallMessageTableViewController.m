//
//  IncomingCallMessageTableViewController.m
//  linphone
//
//  Created by Misha Torosyan on 3/2/16.
//
//

#import "IncomingCallMessageTableViewController.h"

@interface IncomingCallMessageTableViewController ()

@end

@implementation IncomingCallMessageTableViewController

#pragma mark - Override methods
 
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Instance methods

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.messageDidSelectedCallback) {
        self.messageDidSelectedCallback(indexPath.row);
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
