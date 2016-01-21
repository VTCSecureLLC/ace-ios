//
//  HelpViewController.m
//  linphone
//
//  Created by Shareef Ali on 9/15/15.
//
//

#import "HelpViewController.h"
#import <HockeySDK/HockeySDK.h>
#import <sys/utsname.h>
#import "LinphoneIOSVersion.h"
#import "ResourcesViewController.h"
#import "PhoneMainView.h"
@interface HelpViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation HelpViewController{
    NSArray *tableData;
    NSArray *tableImages;
    ResourcesViewController *resourcesController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    tableImages = [NSArray arrayWithObjects:[UIImage imageNamed:@"resources_default.png"], [UIImage imageNamed:@"resources_default.png"], [UIImage imageNamed:@"Global1.png"], nil];
    
    tableData = [NSArray arrayWithObjects: @"Deaf / Hard of Hearing Resources", @"Instant Feedback", @"Technical Support", @"Videomail", nil];
    tableImages = [NSArray arrayWithObjects:[UIImage imageNamed:@"resources_default.png"], [UIImage imageNamed:@"resources_default.png"], [UIImage imageNamed:@"Global1.png"], nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"background_color_preference"];
    if(colorData){
        UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
        self.tableView.opaque = NO;
        self.tableView.backgroundColor = color;
        self.tableView.backgroundView  = nil;
    }
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tableData count];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
  
    if([[tableData objectAtIndex:indexPath.row] isEqualToString:@"Instant Feedback"]){
        NSMutableArray *deviceStats = [[NSMutableArray alloc] init];
        
        struct utsname systemInfo;
        uname(&systemInfo);
        
        NSString *deviceInfo = [NSString stringWithFormat:@"\n \n \n%@ %@ %@ \n\n ACE: %@",
                                [NSString stringWithCString:systemInfo.machine
                                                   encoding:NSUTF8StringEncoding], [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion], @"Beta"];
        [deviceStats addObject:deviceInfo];
        
        [[BITHockeyManager sharedHockeyManager].feedbackManager showFeedbackComposeViewWithPreparedItems:deviceStats];
    }
    
    else if([[tableData objectAtIndex:indexPath.row] isEqualToString:@"Deaf / Hard of Hearing Resources"]){
        resourcesController = [[ResourcesViewController alloc] init];
        [self showViewController:resourcesController sender:self];
//        [self presentViewController:resourcesController animated:YES completion:nil];
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
    
    if(indexPath.row == tableData.count-1){
        NSInteger mwiCount;
        if(![[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"mwi_count"]){
            mwiCount = 0;
        }
        else{
            mwiCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"mwi_count"];
        }
        
        if(mwiCount > 0){
            cell.textLabel.text = [NSString stringWithFormat:@"Videomail(%ld)", (long)mwiCount];
        }
    }


    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"background_color_preference"];
    if(colorData){
        UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
        cell.backgroundColor = color;
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    
    return view;
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
