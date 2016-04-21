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
#import "LinphoneAppDelegate.h"

@interface HelpViewController ()<MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation HelpViewController{
    NSArray *tableData;
    ResourcesViewController *resourcesController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    tableData = [NSArray arrayWithObjects: @"Deaf / Hard of Hearing Resources", @"Instant Feedback", @"Technical Support", @"Videomail", @"Export Contacts", nil];
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
  
    if([[tableData objectAtIndex:indexPath.row] isEqualToString:@"Instant Feedback"]
       || [[tableData objectAtIndex:indexPath.row] isEqualToString:@"Technical Support"]){
        
        NSMutableArray *items = [[NSMutableArray alloc] init];
        
        struct utsname systemInfo;
        uname(&systemInfo);
        
        NSString *deviceInfo = [NSString stringWithFormat:@"\n \n \n%@ %@ %@ \n\n ACE: %@",
                                [NSString stringWithCString:systemInfo.machine
                                                   encoding:NSUTF8StringEncoding], [[UIDevice currentDevice] systemName], [[UIDevice currentDevice] systemVersion], @"Beta"];
        [items addObject:deviceInfo];
       
        NSArray *array = [NSArray new];
        array  = [[(LinphoneAppDelegate *)[UIApplication sharedApplication].delegate logFileArray] mutableCopy];
        
        NSString * logFilePath = [self logFilePath];
        [array writeToFile:logFilePath atomically:YES];
    
        NSData *logFileData = [NSData dataWithContentsOfFile:logFilePath];
        [items addObject:logFileData];
       
        if([BITHockeyManager sharedHockeyManager] && [BITHockeyManager sharedHockeyManager].feedbackManager){
            [[BITHockeyManager sharedHockeyManager].feedbackManager showFeedbackComposeViewWithPreparedItems:items];
        }
    }
    
    else if([[tableData objectAtIndex:indexPath.row] isEqualToString:@"Deaf / Hard of Hearing Resources"]){
        resourcesController = [[ResourcesViewController alloc] init];
        float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
        
        if (sysVer >= 8.0) {
            [self showViewController:resourcesController sender:self];
        }
        else{
            [self presentViewController:resourcesController animated:YES completion:nil];
        }
    }
    else if([[tableData objectAtIndex:indexPath.row] rangeOfString:@"Videomail"].location != NSNotFound){
        NSString *address = [[NSUserDefaults standardUserDefaults] objectForKey:@"video_mail_uri_preference"];
        if(address){
            [[LinphoneManager instance] call:address displayName:@"Videomail" transfer:FALSE];
            [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"mwi_count"];
        }
    }
    else if([[tableData objectAtIndex:indexPath.row] containsString:@"Export Contacts"]) {
        if ([[VSContactsManager sharedInstance] addressBookContactsCount] <= 0) {
            UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:nil
                                                             message:@"You have no contacts to export"
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles: nil];
            [alert show];
        } else {
            [self exportAllContacts];
        }
    }
}

- (NSString*)logFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains
    (NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logFilePath = [NSString stringWithFormat:@"%@/linphoneLogFile.text",
                             documentsDirectory];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:logFilePath];
    NSFileManager *fm = [NSFileManager defaultManager];
    if (!fileExists) {
        BOOL success = [fm createFileAtPath:logFilePath contents:nil attributes:nil];
        if (!success) {
            NSLog(@"Failed to create a linphone log file");
        }
    }
    return logFilePath;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *tableIdentifier = @"TableItem";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableIdentifier];
    }
    
    cell.textLabel.text = [tableData objectAtIndex:indexPath.row];
    
    if([[tableData objectAtIndex:indexPath.row] rangeOfString:@"Videomail"].location != NSNotFound){
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

- (void)exportAllContacts {
    
    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:@"Export all contacts?"
                                message:@""
                                preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"Yes"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action)
                         {
                             NSString *exportedContactsFilePath = [[VSContactsManager sharedInstance] exportAllContacts];
                             
                             if ([exportedContactsFilePath isEqualToString:@""]) {
                                 UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                                 message:@"There is no any contact that has sip uri or a phone number"
                                                                                delegate:self
                                                                       cancelButtonTitle:@"OK"
                                                                       otherButtonTitles:nil];
                                 [alert show];
                                 return;
                             }
                             NSData *vcard = [[NSFileManager defaultManager] contentsAtPath:exportedContactsFilePath];
                             
                             if (vcard) {
                                 
                                 if ([MFMailComposeViewController canSendMail]) {
                                     MFMailComposeViewController *composeMail =
                                     [[MFMailComposeViewController alloc] init];
                                     composeMail.mailComposeDelegate = self;
                                     [composeMail addAttachmentData:vcard mimeType:@"text/vcard" fileName:@"ACE_contact.vcard"];
                                     [self presentViewController:composeMail animated:NO completion:^{
                                     }];
                                     
                                 } else {
                                     UIAlertController *alert = [UIAlertController
                                                                 alertControllerWithTitle:@"WARNING!"
                                                                 message:@"There is no default email\n Do you want to go to settings?"
                                                                 preferredStyle:UIAlertControllerStyleAlert];
                                     
                                     UIAlertAction* ok = [UIAlertAction
                                                          actionWithTitle:@"Go to Settings"
                                                          style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto:"]];
                                                          }];
                                     
                                     UIAlertAction* cancel = [UIAlertAction
                                                              actionWithTitle:@"No Thanks"
                                                              style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action)
                                                              {
                                                                  [alert dismissViewControllerAnimated:YES completion:nil];
                                                                  
                                                              }];
                                     [alert addAction:ok];
                                     [alert addAction:cancel];
                                     
                                     [self presentViewController:alert animated:YES completion:nil];
                                     
                                 }
                             }
                             [alert dismissViewControllerAnimated:NO completion:nil];
                             
                         }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"No"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                 
                             }];
    
    [alert addAction:ok];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - MFMessageComposeViewControllerDelegate Functions

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result{}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    self.tableView.contentInset = UIEdgeInsetsMake(20.0f, 0.0f, 0.0f, 0.0f);
    [controller dismissViewControllerAnimated:NO completion:nil];
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
