//
//  VSContactsManager.m
//  linphone
//
//  Created by Karen Muradyan on 2/26/16.
//
//

#import "VSContactsManager.h"
#import "LinphoneManager.h"

@implementation VSContactsManager

+ (VSContactsManager *)sharedInstance {
    static VSContactsManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[VSContactsManager alloc] init];
    });
    
    return sharedInstance;
}

- (NSString*)exportContact:(ABRecordRef)abRecord {
    
    [self resetDefaultFrinedList];
    NSMutableArray *phoneNumbers = [self contactPhoneNumbersFrom:abRecord];
    NSMutableArray *sipURIs = [self contactSipURIsFrom:abRecord];
    NSString *nameSurnameOrg = [self contactNameSurnameOrganizationFrom:abRecord];
    LinphoneFriend *friend = NULL;
    if (sipURIs.count > 1) {
        friend = [self createFriendFromName:nameSurnameOrg withPhoneNumbers:phoneNumbers andSipURIs:sipURIs];
    } else {
        return @"";
    }
    if (friend == NULL) {
        return @"";
    }
    NSString *documtensDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *exportedContactFilePath = [documtensDirectoryPath stringByAppendingString:[NSString stringWithFormat:@"/%@%@.vcard", @"ACE_", @"Contacts"]];
    
    LinphoneFriendList *friendList = linphone_core_get_default_friend_list([LinphoneManager getLc]);
    linphone_friend_list_export_friends_as_vcard4_file(friendList, [exportedContactFilePath UTF8String]);
    
    return exportedContactFilePath;
}

- (BOOL)checkContactSipURIExistance{
    ABAddressBookRef addressBook = ABAddressBookCreate( );
    CFArrayRef allContacts = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
    
    for ( int i = 0; i < nPeople; i++ ) {
        ABRecordRef ref = CFArrayGetValueAtIndex(allContacts, i);
        NSMutableArray *sipURIs = [self contactSipURIsFrom:ref];
        if (sipURIs.count > 0) {
            return  YES;
        }
    }
    return NO;
}

- (NSString*)exportAllContacts {
    
    ABAddressBookRef addressBook = ABAddressBookCreate( );
    CFArrayRef allContacts = ABAddressBookCopyArrayOfAllPeople(addressBook);
    
    [self resetDefaultFrinedList];
    [self createListWithAllContacts:allContacts];
    
    NSString *exportedContactsFilePath = [[self documentsDirectoryPath] stringByAppendingString:[NSString stringWithFormat:@"/%@%@.vcard", @"ACE_", @"Contacts"]];
    LinphoneFriendList *defaultFriendList = linphone_core_get_default_friend_list([LinphoneManager getLc]);
    linphone_friend_list_export_friends_as_vcard4_file(defaultFriendList, [exportedContactsFilePath UTF8String]);
    
    return exportedContactsFilePath;
}

-(void)createListWithAllContacts:(CFArrayRef)allContacts{
    ABAddressBookRef addressBook = ABAddressBookCreate();
    CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
    
    for ( int i = 0; i < nPeople; i++ ) {
        ABRecordRef ref = CFArrayGetValueAtIndex(allContacts, i);
        NSMutableArray *phoneNumbers = [self contactPhoneNumbersFrom:ref];
        NSMutableArray *sipURIs = [self contactSipURIsFrom:ref];
        NSString *contactNameSurnameOrg = [self contactNameSurnameOrganizationFrom:ref];
        
        if (sipURIs.count > 0) {
            LinphoneFriend *friend = [self createFriendFromName:contactNameSurnameOrg withPhoneNumbers:phoneNumbers andSipURIs:sipURIs];
#pragma unused(friend)
        }
    }
}

- (NSString*)documentsDirectoryPath {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
}

- (LinphoneFriend*)createFriendFromContactBySipURI:(ABRecordRef)abRecord {
    
    LinphoneFriend *linphoneFriend = NULL;
    NSString *contactNameSurnameOrganization = [self contactNameSurnameOrganizationFrom:abRecord];
    NSString *contactSipURI = [self contactSipURIFrom:abRecord];
    NSString *appendSIP = [@"sip:" stringByAppendingString:contactSipURI];
    
    linphoneFriend = [self createFriendFromName:contactNameSurnameOrganization andSipURI:appendSIP];
    
    return linphoneFriend;
}

- (LinphoneFriend*)createFriendFromContactByPhoneNumber:(ABRecordRef)abRecord {
    
    LinphoneFriend *linphoneFriend = NULL;
    NSString *contactNameSurnameOrganization = [self contactNameSurnameOrganizationFrom:abRecord];
    NSString *contactPhoneNumber = [self contactPhoneNumberFrom:abRecord];
    if (![contactPhoneNumber isEqualToString:@""]) {
        linphoneFriend = [self createFriendFromName:contactNameSurnameOrganization andSipURI:[self phoneNumberWithDefaultSipDomain:contactPhoneNumber]];
    }
    
    return linphoneFriend;
}

- (NSString*)contactNameSurnameOrganizationFrom:(ABRecordRef)abRecord {
    
    NSString *contactFullName = @"";
    NSString *contactFirstName = @"";
    NSString *contactLastName = @"";
    NSString *contactOrganizationName = @"";
    
    @try {
        contactFirstName = (__bridge NSString*)ABRecordCopyValue(abRecord, kABPersonFirstNameProperty);
        contactLastName = (__bridge NSString*)ABRecordCopyValue(abRecord, kABPersonLastNameProperty);
        contactOrganizationName = (__bridge NSString*)ABRecordCopyValue(abRecord, kABPersonOrganizationProperty);
    }
    @catch (NSException *exception) {
    }
    
    if (contactFirstName == nil && contactLastName == nil) {
        contactFullName = contactOrganizationName;
    } else if (contactFirstName == nil) {
        contactFullName = contactLastName;
    } else if (contactLastName == nil) {
        contactFullName = contactFirstName;
    } else {
        contactFullName = [NSString stringWithFormat:@"%@ %@", contactFirstName, contactLastName];
    }
    contactFullName = [contactFullName stringByReplacingOccurrencesOfString:@"(null)" withString:@""];
    
    return contactFullName;
}

- (NSString*)contactSipURIFrom:(ABRecordRef)abRecord {
    NSString *contactSipURI = @"";
    
    ABMultiValueRef instantMessageProperties = ABRecordCopyValue(abRecord, kABPersonInstantMessageProperty);
    for (CFIndex i = 0; i < ABMultiValueGetCount(instantMessageProperties); ++i) {
        CFDictionaryRef emailRef = ABMultiValueCopyValueAtIndex(instantMessageProperties, i);
        NSDictionary *emailDict = (__bridge NSDictionary*)emailRef;
        CFRelease(emailRef);
        if ([emailDict objectForKey:@"service"] && [[emailDict objectForKey:@"service"] isEqualToString:@"SIP"]) {
            contactSipURI = [emailDict objectForKey:@"username"];
            break;
        }
    }
    
    return contactSipURI;
}

- (NSString*)contactPhoneNumberFrom:(ABRecordRef)abRecord {
    NSString *phoneNumber = @"";
    
    ABMultiValueRef multiPhones = ABRecordCopyValue(abRecord, kABPersonPhoneProperty);
    for (CFIndex i = 0; i < ABMultiValueGetCount(multiPhones); ++i) {
        CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, i);
        CFRelease(multiPhones);
        NSString *abPhoneNumber = (__bridge NSString *) phoneNumberRef;
        CFRelease(phoneNumberRef);
        if (abPhoneNumber) {
            phoneNumber = abPhoneNumber;
            break;
        }
    }
    
    return phoneNumber;
}

- (LinphoneFriend*)createFriendFromName:(NSString*)name andSipURI:(NSString*)sipURI {
    LinphoneFriend *newFriend = linphone_friend_new_with_addr([sipURI  UTF8String]);
    if (newFriend) {
        linphone_friend_edit(newFriend);
        linphone_friend_set_name(newFriend, [name  UTF8String]);
        linphone_friend_done(newFriend);
        linphone_core_add_friend([LinphoneManager getLc], newFriend);
    }
    
    return newFriend;
}

- (void)createFriendListWithAllContacts:(CFArrayRef)allContacts {
    ABAddressBookRef addressBook = ABAddressBookCreate( );
    CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
    for ( int i = 0; i < nPeople; i++ ) {
        ABRecordRef ref = CFArrayGetValueAtIndex(allContacts, i);
        #pragma unused(ref)
        LinphoneFriend *friendByPhoneNumber = [self createFriendFromContactByPhoneNumber:ref];
        if (friendByPhoneNumber == NULL) {
            LinphoneFriend *friendBySipURI = [self createFriendFromContactBySipURI:ref];
            #pragma unused(friendBySipURI)
        }
    }
}

- (NSString*)phoneNumberWithDefaultSipDomain:(NSString*)phoneNumber {
    LinphoneProxyConfig *proxyConfig = linphone_core_get_default_proxy_config([LinphoneManager getLc]);
    const char *domain = linphone_proxy_config_get_domain(proxyConfig);
    NSString *phoneNumberWithDefaultDomain = [NSString stringWithFormat:@"sip:%@@%s", phoneNumber, domain];
    return phoneNumberWithDefaultDomain;
}

- (void)resetDefaultFrinedList {
    LinphoneFriendList *oldFriendList = linphone_core_get_default_friend_list([LinphoneManager getLc]);
    linphone_core_remove_friend_list ([LinphoneManager getLc], oldFriendList);
    LinphoneFriendList *friendListNew = linphone_core_create_friend_list([LinphoneManager getLc]);
    linphone_core_add_friend_list([LinphoneManager getLc], friendListNew);
}

- (int)addressBookContactsCount {
    int count = 0;
    ABAddressBookRef addressBook = ABAddressBookCreate( );
    CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
    count = (int)nPeople;
    return count;
}

- (NSMutableArray*)contactSipURIsFrom:(ABRecordRef)abRecord {
    NSString *contactSipURI = @"";
    NSMutableArray *sipURIs = [NSMutableArray new];
    
    ABMultiValueRef instantMessageProperties = ABRecordCopyValue(abRecord, kABPersonInstantMessageProperty);
    for (CFIndex i = 0; i < ABMultiValueGetCount(instantMessageProperties); ++i) {
        CFDictionaryRef emailRef = ABMultiValueCopyValueAtIndex(instantMessageProperties, i);
        NSDictionary *emailDict = (__bridge NSDictionary*)emailRef;
        CFRelease(emailRef);
        if ([emailDict objectForKey:@"service"] && [[emailDict objectForKey:@"service"] isEqualToString:@"SIP"]) {
            contactSipURI = [emailDict objectForKey:@"username"];
            [sipURIs addObject:[@"sip:" stringByAppendingString:contactSipURI]];
        }
    }
    
    return sipURIs;
}


- (NSMutableArray*)contactPhoneNumbersFrom:(ABRecordRef)abRecord {
    NSMutableArray *phoneNumbers = [NSMutableArray new];
    
    ABMultiValueRef multiPhones = ABRecordCopyValue(abRecord, kABPersonPhoneProperty);
    for (CFIndex i = 0; i < ABMultiValueGetCount(multiPhones); ++i) {
        CFStringRef phoneNumberRef = ABMultiValueCopyValueAtIndex(multiPhones, i);
        NSString *abPhoneNumber = (__bridge NSString *) phoneNumberRef;
        CFRelease(phoneNumberRef);
        if (abPhoneNumber) {
            [phoneNumbers addObject:abPhoneNumber];
        }
    }
    
    CFRelease(multiPhones);
    
    return phoneNumbers;
}

- (LinphoneFriend*)createFriendFromName:(NSString*)name withPhoneNumbers:(NSMutableArray*)phoneNumbers andSipURIs:(NSMutableArray*)sipURIs {
    
    LinphoneFriend *newFriend = linphone_core_create_friend([LinphoneManager getLc]);
    if (newFriend == NULL) {
        return newFriend;
    }
    linphone_friend_set_name(newFriend, [name UTF8String]);
    
    const LinphoneAddress *addr = linphone_core_create_address([LinphoneManager getLc], [sipURIs[0] UTF8String]);
    if (addr) {
        linphone_friend_set_address(newFriend, addr);
    }
    
    if (sipURIs.count > 1) {
        for (int i = 1; i < sipURIs.count; ++i) {
            const LinphoneAddress *addr = linphone_core_create_address([LinphoneManager getLc], [sipURIs[i] UTF8String]);
            if (addr) {
                linphone_friend_add_address(newFriend, addr);
            }
        }
    }

    for (int i = 0; i < phoneNumbers.count; ++i) {
        linphone_friend_add_phone_number(newFriend, [phoneNumbers[i] UTF8String]);
    }
    
    LinphoneFriendList *friendList = linphone_core_get_default_friend_list([LinphoneManager getLc]);
    linphone_friend_list_add_friend(friendList, newFriend);
    
    MSList* addressesList = linphone_friend_get_addresses(newFriend);
    if (ms_list_size(addressesList) == 0) {
        return NULL;
    }
    
    if (linphone_friend_get_address(newFriend) == NULL) {
        return NULL;
    }
    
    return newFriend;
}

@end
