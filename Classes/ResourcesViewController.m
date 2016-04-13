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
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"background_color_preference"];
    if(colorData){
        UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
        self.tableView.opaque = NO;
        self.tableView.backgroundColor = color;
        self.tableView.backgroundView  = nil;
        self.view.backgroundColor = color;
    }
}

- (void)loadDataFromCDN {
    
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
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        
    }] resume];
  
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [cdnResources count];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *resource = [cdnResources objectAtIndex:indexPath.row];
    if(cdnResources && cdnResources.count){
        NSString *resourceNum = [resource objectForKey:@"address"];
        NSString *resourceName = [resource objectForKey:@"name"];
        const LinphoneAddress *addr = linphone_proxy_config_normalize_sip_uri(linphone_core_get_default_proxy_config([LinphoneManager getLc]), [resourceNum UTF8String]);
        NSString *sip_uri =[[NSString alloc] initWithUTF8String: linphone_address_as_string_uri_only(addr)];
        sip_uri = [NSString stringWithFormat:@"%@;user=phone", sip_uri];
        [[LinphoneManager instance] call:sip_uri displayName:resourceName transfer:0];
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
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"background_color_preference"];
    if(colorData){
        UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
        cell.backgroundColor = color;
    } else {
        cell.backgroundColor = [UIColor whiteColor];
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
- (IBAction)onBack:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
