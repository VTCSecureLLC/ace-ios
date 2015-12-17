#import "ResourcesViewController.h"
#import <HockeySDK/HockeySDK.h>
#import <sys/utsname.h>
#import "LinphoneIOSVersion.h"
#import "DialerViewController.h"
#import "PhoneMainView.h"
@interface ResourcesViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ResourcesViewController{
    NSMutableArray *cdnResources;
    NSURLRequest *cdnRequest;
    NSURLSession *urlSession;

}

const NSString *cdnDatabase = @"http://cdn.vatrp.net/numbers.json";
- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadDataFromCDN];
}

-(void) loadDataFromCDN{
    cdnResources = [[NSMutableArray alloc] init];
    urlSession = [NSURLSession sharedSession];
    
    [[urlSession dataTaskWithURL:[NSURL URLWithString:(NSString*)cdnDatabase] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *jsonParsingError = nil;
        if(data){
            NSArray *resources = [NSJSONSerialization JSONObjectWithData:data
                                                             options:0 error:&jsonParsingError];
            NSDictionary *resource;
            for(int i=0; i < [resources count];i++){
                resource= [resources objectAtIndex:i];
                [cdnResources addObject:resource];
                NSLog(@"Loaded CDN Resource: %@", [resource objectForKey:@"name"]);
            }
            [self.tableView reloadData];
        }
        
    }] resume];
  
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [cdnResources count];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    DialerViewController *controller =
    DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]],
                 DialerViewController);
    if (controller != nil) {
        NSDictionary *resource = [cdnResources objectAtIndex:indexPath.row];
        NSString *name = [resource objectForKey:@"name"];
        NSString *address = [resource objectForKey:@"address"];
        
        [controller call:address displayName:name];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *tableIdentifier = @"tableItem";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableIdentifier];
    }
    
    NSDictionary *resource= [cdnResources objectAtIndex:indexPath.row];
    
    NSString *name = [resource objectForKey:@"name"];
    [cell.textLabel setText:[NSString stringWithFormat:@"%@", name]];
    [cell.textLabel setCenter:cell.center];
    return cell;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
//static UICompositeViewDescription *compositeDescription = nil;
//
//+ (UICompositeViewDescription *)compositeViewDescription {
//    if (compositeDescription == nil) {
//        compositeDescription = [[UICompositeViewDescription alloc] init:@"Resources"
//                                                                content:@"ResourcesViewController"
//                                                               stateBar:nil
//                                                        stateBarEnabled:false
//                                                                 tabBar:@"UIMainBar"
//                                                          tabBarEnabled:true
//                                                             fullscreen:false
//                                                          landscapeMode:[LinphoneManager runningOnIpad]
//                                                           portraitMode:true];
//    }
//    return compositeDescription;
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
