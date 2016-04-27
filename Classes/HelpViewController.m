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
#import "VSContactsManager.h"
#import "Utils.h"

typedef struct _LinphoneCardDAVStats {
    int sync_done_count;
    int new_contact_count;
    int removed_contact_count;
    int updated_contact_count;
} LinphoneCardDAVStats;

@interface HelpViewController ()<MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>
{
    LinphoneCardDAVStats _cardDavStats;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation HelpViewController{
    NSArray *tableData;
    ResourcesViewController *resourcesController;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    tableData = [NSArray arrayWithObjects: @"Deaf / Hard of Hearing Resources", @"Instant Feedback", @"Technical Support", @"Videomail", @"Export Contacts", @"Sync Contacts", nil];
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
    else if([[tableData objectAtIndex:indexPath.row] isEqualToString:@"Export Contacts"]) {
        if ([[VSContactsManager sharedInstance] addressBookContactsCount] <= 0) {
            UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:nil
                                                             message:@"You have no contacts to export"
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles: nil];
            [alert show];
        } else if ([[VSContactsManager sharedInstance] checkContactSipURIExistance]) {
            [self exportAllContacts];
        } else {
            UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:nil
                                                             message:@"No contact has valid sip URI"
                                                            delegate:nil
                                                   cancelButtonTitle:@"OK"
                                                   otherButtonTitles: nil];
            [alert show];
        }
    }
    else if([[tableData objectAtIndex:indexPath.row] isEqualToString:@"Sync Contacts"]) {
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"carddav_path"] && [[NSUserDefaults standardUserDefaults] objectForKey:@"carddav_realm"]) {
            if (!([[[NSUserDefaults standardUserDefaults] objectForKey:@"carddav_path"] isEqualToString:@""]) && (![[[NSUserDefaults standardUserDefaults] objectForKey:@"carddav_realm"] isEqualToString:@""])) {
                [[VSContactsManager sharedInstance] addAllContactsToFriendList];
                //[self delAllContacts];
                [self syncContacts];
                
            } else {
                [self showCardDavSyncAlert];
            }
        } else {
            [self showCardDavSyncAlert];
        }
    }
}

- (void)showCardDavSyncAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:@"Please configure CardDav URI and Realm first"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
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

- (void)syncContacts {
    
    const char *cardDavUser = "";
    const char *cardDavPass = "";
    const char *cardDavRealm = "";
    const char *cardDavServer = "";
    const char *cardDavDomain = "";

    cardDavUser = [[[LinphoneManager instance] lpConfigStringForKey:@"wizard_username"] UTF8String];
    cardDavPass = [[[LinphoneManager instance] lpConfigStringForKey:@"wizard_password"] UTF8String];
    cardDavRealm = [[[NSUserDefaults standardUserDefaults] objectForKey:@"carddav_realm"] UTF8String];
    cardDavServer = [[[NSUserDefaults standardUserDefaults] objectForKey:@"carddav_path"] UTF8String];
    cardDavDomain = [[LinphoneUtils cardDAVServerDomain] UTF8String];
    
    LinphoneFriendList * cardDAVFriends = linphone_core_get_default_friend_list([LinphoneManager getLc]);
    
    const LinphoneAuthInfo * carddavAuth = linphone_auth_info_new(cardDavUser, nil, cardDavPass, nil, cardDavRealm, cardDavDomain);
    linphone_core_add_auth_info([LinphoneManager getLc], carddavAuth);
    
    LinphoneFriendListCbs * cbs = linphone_friend_list_get_callbacks(cardDAVFriends);
    linphone_friend_list_cbs_set_user_data(cbs, &_cardDavStats);
    linphone_friend_list_cbs_set_sync_status_changed(cbs, carddav_sync_status_changed);
    linphone_friend_list_cbs_set_contact_created(cbs, carddav_contact_created);
    linphone_friend_list_cbs_set_contact_deleted(cbs, carddav_contact_deleted);
    linphone_friend_list_cbs_set_contact_updated(cbs, carddav_contact_updated);
    
    linphone_friend_list_set_uri(cardDAVFriends, cardDavServer);
    linphone_friend_list_synchronize_friends_from_server(cardDAVFriends);
    
}

static void carddav_sync_status_changed(LinphoneFriendList *list, LinphoneFriendListSyncStatus status, const char *msg) {

}

static void carddav_contact_created(LinphoneFriendList *list, LinphoneFriend *lf) {
    if (linphone_friend_get_ref_key(lf)) {
        // own contact successully uploaded to the server
    } else {
        // create contact
        // add contact to address book
        CFErrorRef  anError = NULL;
        ABRecordRef contact = [[VSContactsManager sharedInstance] createAddressBookContactFromLinphoneFriend:lf];
        ABAddressBookRef addressBook = ABAddressBookCreate();
        ABAddressBookAddRecord(addressBook, contact, nil);
        BOOL isSaved = ABAddressBookSave(addressBook, &anError);
        if (isSaved) {
            NSLog(@"Contact successfully created");
        }
    }
}

static void carddav_contact_deleted(LinphoneFriendList *list, LinphoneFriend *lf) {

    if (linphone_friend_get_ref_key(lf)) {
        const char *refKey = linphone_friend_get_ref_key(lf);
        NSString *refKeyString = [NSString stringWithUTF8String:refKey];
        ABAddressBookRef addressBook = ABAddressBookCreate();
        ABRecordRef person = ABAddressBookGetPersonWithRecordID(addressBook, [refKeyString intValue]);
        if(person != NULL) {
            CFErrorRef  anError = NULL;
            ABAddressBookRemoveRecord(addressBook, person, &anError);
            BOOL isSaved = ABAddressBookSave(addressBook, &anError);
            if (isSaved) {
                 NSLog(@"Contact successfully deleted");
            }
        }
    } else {
        NSLog(@"ERROR: Contact doesn' have ref Key");
    }
}

static void carddav_contact_updated(LinphoneFriendList *list, LinphoneFriend *new_friend, LinphoneFriend *old_friend) {
    
    const char *receivedRefKey = linphone_friend_get_ref_key(new_friend);
    
    if (receivedRefKey) {
        
        LinphoneFriendList * friendList = linphone_core_get_default_friend_list([LinphoneManager getLc]);
        const MSList* friends = linphone_friend_list_get_friends(friendList);
        while (friends != NULL) {
            LinphoneFriend* friend = (LinphoneFriend*)friends->data;
            const char *friendRefKey = linphone_friend_get_ref_key(friend);
            
            if (strcmp(friendRefKey, receivedRefKey)) {
                
                linphone_friend_edit(friend);
                
                // Set the new name
                const char * newName = linphone_friend_get_name(new_friend);
                linphone_friend_set_name(friend, newName);
                
                // Remove sip addresses
               const MSList* friendAddresses = linphone_friend_get_addresses(friend);
                while (friendAddresses != NULL) {
                    LinphoneAddress* lAddress = (LinphoneAddress*)friendAddresses->data;
                    linphone_friend_remove_address(friend, lAddress);
                    friendAddresses = ms_list_next(friendAddresses);
                }
                
                // Remove phones
                const MSList* friendPhoneNumbers = linphone_friend_get_phone_numbers(friend);
                while (friendPhoneNumbers != NULL) {
                    const char* lPhoneNumber = (const char*)friendPhoneNumbers->data;
                    linphone_friend_remove_phone_number(friend, lPhoneNumber);
                    friendPhoneNumbers = ms_list_next(friendPhoneNumbers);
                }
                
                // Add new sip addresses
                const MSList* newFriendAddresses = linphone_friend_get_addresses(new_friend);
                while (newFriendAddresses != NULL) {
                    LinphoneAddress* lAddress = (LinphoneAddress*)friendAddresses->data;
                    linphone_friend_add_address(new_friend, lAddress);
                    newFriendAddresses = ms_list_next(newFriendAddresses);
                }
                
                // Add new phone numbers
                const MSList* newFriendPhoneNumbers = linphone_friend_get_addresses(new_friend);
                while (newFriendPhoneNumbers != NULL) {
                    const char* lPhoneNumber = (const char*)friendPhoneNumbers->data;
                    linphone_friend_add_phone_number(new_friend, lPhoneNumber);
                    newFriendPhoneNumbers = ms_list_next(newFriendPhoneNumbers);
                }
                
                linphone_friend_done (friend);
                
                break;
            }
            
            friends = ms_list_next(friends);
        }
    } else {
         NSLog(@"ERROR: No such a contact to be deleted");
    }
}

- (void)delAllContacts {
    ABAddressBookRef addressBook = CFBridgingRetain((__bridge id)(ABAddressBookCreateWithOptions(NULL, NULL)));
    CFIndex count = ABAddressBookGetPersonCount(addressBook);
    if(count==0 && addressBook!=NULL) { //If there are no contacts, don't delete
        CFRelease(addressBook);
        return;
    }
    //Get all contacts and store it in a CFArrayRef
    CFArrayRef theArray = ABAddressBookCopyArrayOfAllPeople(addressBook);
    for(CFIndex i=0;i<count;i++) {
        ABRecordRef person = CFArrayGetValueAtIndex(theArray, i); //Get the ABRecord
        BOOL result = ABAddressBookRemoveRecord (addressBook,person,NULL); //remove it
        if(result==YES) { //if successful removal
            BOOL save = ABAddressBookSave(addressBook, NULL); //save address book state
            if(save==YES && person!=NULL) {
                CFRelease(person);
            } else {
                NSLog(@"Couldn't save, breaking out");
                break;
            }
        } else {
            NSLog(@"Couldn't delete, breaking out");
            break;
        }
    }
    if(addressBook!=NULL) {
        CFRelease(addressBook);
    }
}

@end






