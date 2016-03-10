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
    
    LinphoneFriend *friend = [self createFriendFromContact:abRecord];
    #pragma unused(friend)

    NSString *documtensDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *exportedContactFilePath = [documtensDirectoryPath stringByAppendingString:[NSString stringWithFormat:@"/%@%@.vcard", @"ACE_", @"Contacts"]];

    LinphoneFriendList *friendList = linphone_core_get_default_friend_list([LinphoneManager getLc]);
    linphone_friend_list_export_friends_as_vcard4_file(friendList, [exportedContactFilePath UTF8String]);

    return exportedContactFilePath;
}

- (LinphoneFriend*)createFriendFromContact:(ABRecordRef)abRecord {
    
    LinphoneFriend *linphoneFriend = NULL;
    NSString *contactNameSurnameOrganization = [self contactNameSurnameOrganizationFrom:abRecord];
    NSString *contactSipURI = [self contactSipURIFrom:abRecord];
    NSString *appendSIP = [@"sip:" stringByAppendingString:contactSipURI];
    
    linphoneFriend = [self createFriendFromName:contactNameSurnameOrganization andSipURI:appendSIP];
    
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

- (LinphoneFriend*)createFriendFromName:(NSString*)name andSipURI:(NSString*)sipURI {
    LinphoneFriend *newFriend = linphone_friend_new_with_addr([sipURI  UTF8String]);
    if (newFriend) {
        linphone_friend_edit(newFriend);
        linphone_friend_set_name(newFriend, [name  UTF8String]);
        linphone_friend_done(newFriend);
    }
    linphone_core_add_friend([LinphoneManager getLc], newFriend);
    return newFriend;
}

@end
