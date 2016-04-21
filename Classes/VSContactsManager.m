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
    LinphoneFriend *friend = [self createFriendFromContactBySipURI:abRecord];
    if (friend == NULL) {
        return @"";
    }
    NSString *documtensDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *exportedContactFilePath = [documtensDirectoryPath stringByAppendingString:[NSString stringWithFormat:@"/%@%@.vcard", @"ACE_", @"Contacts"]];

    LinphoneFriendList *friendList = linphone_core_get_default_friend_list([LinphoneManager getLc]);
    linphone_friend_list_export_friends_as_vcard4_file(friendList, [exportedContactFilePath UTF8String]);

    return exportedContactFilePath;
}

- (NSString*)exportAllContacts {

    ABAddressBookRef addressBook = ABAddressBookCreate( );
    CFArrayRef allContacts = ABAddressBookCopyArrayOfAllPeople(addressBook);
    
    [self resetDefaultFrinedList];
    [self createFriendListWithAllContacts:allContacts];

    LinphoneFriendList *friendList = linphone_core_get_default_friend_list([LinphoneManager getLc]);
    const MSList* friends = linphone_friend_list_get_friends(friendList);
    if (ms_list_size(friends) <= 0) {
        return @"";
    }
    
    NSString *exportedContactsFilePath = [[self documentsDirectoryPath] stringByAppendingString:[NSString stringWithFormat:@"/%@%@.vcard", @"ACE_", @"Contacts"]];
    LinphoneFriendList *defaultFriendList = linphone_core_get_default_friend_list([LinphoneManager getLc]);
    linphone_friend_list_export_friends_as_vcard4_file(defaultFriendList, [exportedContactsFilePath UTF8String]);
    
    return exportedContactsFilePath;
}

- (void)addAllContactsToFriendList {
    
    ABAddressBookRef addressBook = ABAddressBookCreate( );
    CFArrayRef allContacts = ABAddressBookCopyArrayOfAllPeople(addressBook);
    
    [self deleteFriendsFromList];
    
    CFIndex nPeople = ABAddressBookGetPersonCount(addressBook);
    for ( int i = 0; i < nPeople; i++ ) {
        ABRecordRef abContact = CFArrayGetValueAtIndex(allContacts, i);
        
        NSString *contactNameSurnameOrganization = [self contactNameSurnameOrganizationFrom:abContact];
        NSMutableArray *sipURIs = [self contactSipURIsFrom:abContact];
        if (sipURIs.count > 0) {
            NSMutableArray *phoneNumbers = [self contactPhoneNumbersFrom:abContact];
            ABRecordID recordID = ABRecordGetRecordID(abContact);
            [self addFriendToListWithName:contactNameSurnameOrganization withPhoneNumbers:phoneNumbers andSipURIs:sipURIs andRefKey:recordID];
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

- (void)addFriendToListWithName:(NSString*)name withPhoneNumbers:(NSMutableArray*)phoneNumbers andSipURIs:(NSMutableArray*)sipURIs andRefKey:(ABRecordID)refKey {
    NSString *refKeyString = [NSString stringWithFormat:@"%d", refKey];
    //#pragma unused(refKeyString)
    
    //LinphoneFriend *newFriend = linphone_core_create_friend_with_address([LinphoneManager getLc], "sip:example@example.com");
    
    LinphoneFriend *newFriend = linphone_friend_new();
    
    for (int i = 0; i < sipURIs.count; ++i) {
        NSString *sipURIString = [sipURIs objectAtIndex:i];
        const char *address = [sipURIString UTF8String];
        
        const LinphoneAddress *lAddr = linphone_address_new(address);
        
        linphone_friend_set_address(newFriend, lAddr);
        
        linphone_friend_add_address(newFriend, lAddr);
    }
    
    for (int i = 0; i < phoneNumbers.count; ++i) {
        linphone_friend_add_phone_number(newFriend, [phoneNumbers[i] UTF8String]);
    }
    
    linphone_friend_set_name(newFriend, [name UTF8String]);
    linphone_friend_set_ref_key(newFriend, [refKeyString UTF8String]);

    LinphoneFriendList *friendList = linphone_core_get_default_friend_list([LinphoneManager getLc]);
    linphone_friend_list_add_friend(friendList, newFriend);
    
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
        CFRelease(multiPhones);
        NSString *abPhoneNumber = (__bridge NSString *) phoneNumberRef;
        CFRelease(phoneNumberRef);
        if (abPhoneNumber) {
            [phoneNumbers addObject:abPhoneNumber];
        }
    }
    
    return phoneNumbers;
}

- (ABRecordRef)createAddressBookContactFromLinphoneFriend:(LinphoneFriend*)lFriend {
    ABRecordRef abContact = ABPersonCreate();
    
    const char *name = linphone_friend_get_name(lFriend);
    NSString *friendName = [NSString stringWithUTF8String:name];
    
    NSMutableArray *sipURIs = [self contactSipURIsFromLinphoneFriend:lFriend];
    
    NSMutableArray *phoneNumbers = [self contactPhoneNumbersFromLinphoneFriend:lFriend];
    
    CFErrorRef  anError = NULL;
    ABRecordSetValue(abContact, kABPersonFirstNameProperty, (__bridge CFTypeRef)friendName, nil);
    
    CFStringRef ref = (__bridge_retained CFStringRef)@"ACE";

    ABMutableMultiValueRef phoneNumberMultiValue = ABMultiValueCreateMutable(kABPersonPhoneProperty);
    
    if (phoneNumbers.count > 0) {
        for (int i = 0; i < phoneNumbers.count; ++i) {
            ABMultiValueAddValueAndLabel(phoneNumberMultiValue ,(__bridge CFTypeRef)(phoneNumbers[i]), ref, NULL);
        }
        ABRecordSetValue(abContact, kABPersonPhoneProperty, phoneNumberMultiValue, &anError);
        if (anError != NULL) {
            NSLog(@"Error adding phone numbers");
        }
        CFRelease(phoneNumberMultiValue);
    }
    
     ABMutableMultiValueRef values =  ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
    
    if (sipURIs.count > 0) {
        for (int i = 0; i < sipURIs.count; ++i) {
            NSDictionary *lDict = @{
                                    (NSString *)kABPersonInstantMessageUsernameKey : sipURIs[i],
                                    (NSString *)kABPersonInstantMessageServiceKey : @"SIP"
                                    };
            ABMultiValueAddValueAndLabel(values, (__bridge CFTypeRef)(lDict), NULL, NULL);
        }
        ABRecordSetValue(abContact, kABPersonInstantMessageProperty, values, &anError);
        if (anError != NULL) {
            NSLog(@"Error adding sip URIs");
        }
         CFRelease(values);
    }
    
    return abContact;
}

- (NSMutableArray*)contactSipURIsFromLinphoneFriend:(LinphoneFriend*)lFriend {
    
    NSMutableArray *sipURIs = [NSMutableArray new];
    
    MSList* addresses = linphone_friend_get_addresses(lFriend);
    while (addresses != NULL) {
        LinphoneAddress* lAddress = (LinphoneAddress*)addresses->data;
        char *sipURI = linphone_address_as_string_uri_only(lAddress);
        if (sipURI) {
            NSString *sipAddress = [NSString stringWithUTF8String:sipURI];
            NSString *sip_ =[sipAddress substringToIndex:4];
            if ([sip_ isEqualToString:@"sip:"]) {
                sipAddress = [sipAddress substringFromIndex:4];
            }
            [sipURIs addObject:sipAddress];
        }
        addresses = ms_list_next(addresses);
    }

    return sipURIs;
}

- (NSMutableArray*)contactPhoneNumbersFromLinphoneFriend:(LinphoneFriend*)lFriend {
    
    NSMutableArray *phoneNumbers = [NSMutableArray new];
    MSList* phone_numbers = linphone_friend_get_phone_numbers(lFriend);
    
    while (phone_numbers != NULL) {
        const char *phone = (const char *)phone_numbers->data;
        if (phone) {
            NSString *phoneString = [NSString stringWithUTF8String:phone];
            if ([phoneString length] > 4) {
                NSString *sip_ =[phoneString substringToIndex:4];
                if (![sip_ isEqualToString:@"sip:"]) {
                    [phoneNumbers addObject:[NSString stringWithUTF8String:phone]];
                }
            } else {
                [phoneNumbers addObject:[NSString stringWithUTF8String:phone]];
            }
        }
        phone_numbers = ms_list_next(phone_numbers);
    }
    
    return phoneNumbers;
}

- (void)deleteFriendsFromList {
    const LinphoneFriendList *friendList = linphone_core_get_default_friend_list([LinphoneManager getLc]);
    const MSList *friends = linphone_friend_list_get_friends(friendList);
    while (friends != NULL) {
        LinphoneFriend* friend = (LinphoneFriend*)friends->data;
        friends = ms_list_next(friends);
        linphone_core_remove_friend([LinphoneManager getLc], friend);
    }
    
}

@end
