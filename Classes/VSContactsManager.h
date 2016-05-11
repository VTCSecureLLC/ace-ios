//
//  VSContactsManager.h
//  linphone
//
//  Created by Karen Muradyan on 2/26/16.
//
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

#include "linphone/linphonecore.h"
#include "linphone/linphone_tunnel.h"

@interface VSContactsManager : NSObject

+ (VSContactsManager *)sharedInstance;

- (ABRecordRef)createAddressBookContactFromLinphoneFriend:(LinphoneFriend*)lFriend;

- (NSString*)exportContact:(ABRecordRef)abRecord;
- (LinphoneFriend*)createFriendFromContactBySipURI:(ABRecordRef)abRecord;
- (NSString*)exportAllContacts;
- (int)addressBookContactsCount;
- (void)addAllContactsToFriendList;
- (BOOL)checkContactSipURIExistance;

@end
