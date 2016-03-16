//
//  UICallCellDataNew.m
//  linphone
//
//  Created by Ruben Semerjyan on 3/15/16.
//
//

#import "UICallCellDataNew.h"
#import "Utils.h"
#import "UILinphone.h"
#import "FastAddressBook.h"
#import "LinphoneManager.h"
#include "linphone/linphonecore.h"

@implementation UICallCellDataNew

- (id)init:(LinphoneCall *)acall minimized:(BOOL)minimized {
    self = [super init];
    if (self != nil) {
        self.minimize = minimized;
        self.view = UICallCellOtherView_Avatar;
        self.call = acall;
        self.image = [UIImage imageNamed:@"avatar_unknown.png"];
        self.address = NSLocalizedString(@"Unknown", nil);
        [self update];
    }
    return self;
}

- (void)update {
    if (self.call == NULL) {
        LOGW(@"Cannot update call cell: null call or data");
        return;
    }
    const LinphoneAddress *addr = linphone_call_get_remote_address(self.call);
    
    if (addr != NULL) {
        BOOL useLinphoneAddress = true;
        // contact name
        char *lAddress = linphone_address_as_string_uri_only(addr);
        if (lAddress) {
            NSString *normalizedSipAddress = [FastAddressBook normalizeSipURI:[NSString stringWithUTF8String:lAddress]];
            ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:normalizedSipAddress];
            if (contact) {
                useLinphoneAddress = false;
                self.address = [FastAddressBook getContactDisplayName:contact];
                UIImage *tmpImage = [FastAddressBook getContactImage:contact thumbnail:false];
                if (tmpImage != nil) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL),
                                   ^(void) {
                                       UIImage *tmpImage2 = [UIImage decodedImageWithImage:tmpImage];
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [self setImage:tmpImage2];
                                       });
                                   });
                }
            }
            ms_free(lAddress);
        }
        if (useLinphoneAddress) {
            const char *lDisplayName = linphone_address_get_display_name(addr);
            const char *lUserName = linphone_address_get_username(addr);
            if (lDisplayName)
                self.address = [NSString stringWithUTF8String:lDisplayName];
            else if (lUserName)
                self.address = [NSString stringWithUTF8String:lUserName];
        }
    }
}

@end
