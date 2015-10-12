//
//  HelpViewController.m
//  linphone
//
//  Created by Shareef Ali on 9/15/15.
//
//

#import "HelpViewController.h"
#import <HockeySDK/HockeySDK.h>
@interface HelpViewController ()

@end

@implementation HelpViewController{
    
    NSArray *tableData;
    NSArray *tableImages;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    tableData = [NSArray arrayWithObjects:@"Technical Support", @"Instant Feedback", @"Deaf / Hard of Hearing Resources", nil];
    tableImages = [NSArray arrayWithObjects:[UIImage imageNamed:@"resources_default.png"], [UIImage imageNamed:@"resources_default.png"], [UIImage imageNamed:@"Global1.png"], nil];
    // Do any additional setup after loading the view from its nib.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tableData count];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
  
    if(indexPath.row == 1){
        [[BITHockeyManager sharedHockeyManager].feedbackManager showFeedbackComposeView];
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *tableIdentifier = @"TableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableIdentifier];
    }
    
    cell.textLabel.text = [tableData objectAtIndex:indexPath.row];
   // cell.imageView.image = [tableImages objectAtIndex:indexPath.row];

    return cell;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
    if (compositeDescription == nil) {
        compositeDescription = [[UICompositeViewDescription alloc] init:@"Help"
                                                                content:@"HelpViewController"
                                                               stateBar:nil
                                                        stateBarEnabled:false
                                                                 tabBar:@"UIMainBar"
                                                          tabBarEnabled:true
                                                             fullscreen:false
                                                          landscapeMode:[LinphoneManager runningOnIpad]
                                                           portraitMode:true];
    }
    return compositeDescription;
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
