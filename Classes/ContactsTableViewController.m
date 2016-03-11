/* ContactsTableViewController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "ContactsTableViewController.h"
#import "UIContactCell.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "UACellBackgroundView.h"
#import "UILinphone.h"
#import "Utils.h"
#import "VSContactsManager.h"

@implementation ContactsTableViewController

static void sync_address_book(ABAddressBookRef addressBook, CFDictionaryRef info, void *context);
UILongPressGestureRecognizer *lpgr;
#pragma mark - Lifecycle Functions

- (void)initContactsTableViewController {
	addressBookMap = [[OrderedDictionary alloc] init];
	avatarMap = [[NSMutableDictionary alloc] init];

	addressBook = ABAddressBookCreateWithOptions(nil, nil);

	ABAddressBookRegisterExternalChangeCallback(addressBook, sync_address_book, (__bridge void *)(self));
}

- (id)init {
	self = [super init];
	if (self) {
		[self initContactsTableViewController];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self) {
		[self initContactsTableViewController];
	}
	return self;
}

-(void) attachLongPressListener:(UITableViewCell*) cell{
    lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    [lpgr setCancelsTouchesInView:YES];
    [lpgr setEnabled:YES];

    lpgr.delegate = self;
    [cell setUserInteractionEnabled:YES];
    [cell addGestureRecognizer:lpgr];
}

#pragma mark Contact Export
-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    CGPoint p = [gestureRecognizer locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
    OrderedDictionary *subDic = [addressBookMap objectForKey:[addressBookMap keyAtIndex:[indexPath section]]];
    NSString *key = [[subDic allKeys] objectAtIndex:[indexPath row]];
    ABRecordRef contact = (__bridge ABRecordRef)([subDic objectForKey:key]);
    
    if (![self contactHasValidSipDomain:contact]) {
        
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"WARINING!"
                                    message:@"You can't export this conctact\nthe contact has no sip URI"
                                    preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"Ok"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {}];
        
        [alert addAction:ok];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    if(gestureRecognizer.state == UIGestureRecognizerStateRecognized){
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:@"Export contact?"
                                    message:@""
                                    preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction
                             actionWithTitle:@"Ok"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 OrderedDictionary *subDic = [addressBookMap objectForKey:[addressBookMap keyAtIndex:[indexPath section]]];
                                 NSString *key = [[subDic allKeys] objectAtIndex:[indexPath row]];
                                 ABRecordRef contact = (__bridge ABRecordRef)([subDic objectForKey:key]);
                                 
                                 NSString *exportedContactFilePath = [[VSContactsManager sharedInstance] exportContact:contact];
                                 NSData *vcard = [[NSFileManager defaultManager] contentsAtPath:exportedContactFilePath];
                                 
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
//                                    MFMessageComposeViewController *composeMessage = [[MFMessageComposeViewController alloc] init];
//                                     [composeMessage addAttachmentData:vcard
//                                                        typeIdentifier:@"public.contact" filename:@"contact.vcard"];
//                                     composeMessage.messageComposeDelegate = self;
//                                     [self presentViewController:composeMessage animated:NO completion:^(void){
//
//                                     }];
                                 }
                                 [alert dismissViewControllerAnimated:NO completion:nil];
                                 
                             }];
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
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

- (void)dealloc {
	ABAddressBookUnregisterExternalChangeCallback(addressBook, sync_address_book, (__bridge void *)(self));
	CFRelease(addressBook);
}

#pragma mark -

- (BOOL)contactHasValidSipDomain:(ABRecordRef)person {
	// Check if one of the contact' sip URI matches the expected SIP filter
	ABMultiValueRef personSipAddresses = ABRecordCopyValue(person, kABPersonInstantMessageProperty);
	BOOL match = false;
	NSString *filter = [ContactSelection getSipFilter];

	for (int i = 0; i < ABMultiValueGetCount(personSipAddresses) && !match; ++i) {
		CFDictionaryRef lDict = ABMultiValueCopyValueAtIndex(personSipAddresses, i);
		if (CFDictionaryContainsKey(lDict, @"username")) {
				match = true;
		} else {
			// check domain
			LinphoneAddress *address = linphone_address_new(
				[(NSString *)CFDictionaryGetValue(lDict, kABPersonInstantMessageUsernameKey) UTF8String]);

			if (address) {
				const char *dom = linphone_address_get_domain(address);
				if (dom != NULL) {
					NSString *domain = [NSString stringWithCString:dom encoding:[NSString defaultCStringEncoding]];

					if (([filter compare:@"*" options:NSCaseInsensitiveSearch] == NSOrderedSame) ||
						([filter compare:domain options:NSCaseInsensitiveSearch] == NSOrderedSame)) {
						match = true;
					}
				}
				linphone_address_destroy(address);
			}
		}
		CFRelease(lDict);
	}
	CFRelease(personSipAddresses);
	return match;
}

static int ms_strcmpfuz(const char *fuzzy_word, const char *sentence) {
	if (!fuzzy_word || !sentence) {
		return fuzzy_word == sentence;
	}
	const char *c = fuzzy_word;
	const char *within_sentence = sentence;
	for (; c != NULL && *c != '\0' && within_sentence != NULL; ++c) {
		within_sentence = strchr(within_sentence, *c);
		// Could not find c character in sentence. Abort.
		if (within_sentence == NULL) {
			break;
		}
		// since strchr returns the index of the matched char, move forward
		within_sentence++;
	}

	// If the whole fuzzy was found, returns 0. Otherwise returns number of characters left.
	return (int)(within_sentence != NULL ? 0 : fuzzy_word + strlen(fuzzy_word) - c);
}

- (void)loadData {
	LOGI(@"Load contact list");
	@synchronized(addressBookMap) {

		// Reset Address book
		[addressBookMap removeAllObjects];

		NSArray *lContacts = (NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook));
		for (id lPerson in lContacts) {
			BOOL add = true;
			ABRecordRef person = (__bridge ABRecordRef)lPerson;

			// Do not add the contact directly if we set some filter
			if ([ContactSelection getSipFilter] || [ContactSelection emailFilterEnabled]) {
				add = false;
			}
			if ([ContactSelection getSipFilter] && [self contactHasValidSipDomain:person]) {
				add = true;
			}
			if (!add && [ContactSelection emailFilterEnabled]) {
				ABMultiValueRef personEmailAddresses = ABRecordCopyValue(person, kABPersonEmailProperty);
				// Add this contact if it has an email
				add = (ABMultiValueGetCount(personEmailAddresses) > 0);

				CFRelease(personEmailAddresses);
			}

			if (add) {
				NSString *lFirstName = CFBridgingRelease(ABRecordCopyValue(person, kABPersonFirstNameProperty));
				NSString *lLocalizedFirstName = [FastAddressBook localizedLabel:lFirstName];
				NSString *lLastName = CFBridgingRelease(ABRecordCopyValue(person, kABPersonLastNameProperty));
				NSString *lLocalizedLastName = [FastAddressBook localizedLabel:lLastName];
				NSString *lOrganization = CFBridgingRelease(ABRecordCopyValue(person, kABPersonOrganizationProperty));
				NSString *lLocalizedlOrganization = [FastAddressBook localizedLabel:lOrganization];

				NSString *name = nil;
				if (lLocalizedFirstName.length && lLocalizedLastName.length) {
					name = [NSString stringWithFormat:@"%@ %@", lLocalizedFirstName, lLocalizedLastName];
				} else if (lLocalizedLastName.length) {
					name = [NSString stringWithFormat:@"%@", lLocalizedLastName];
				} else if (lLocalizedFirstName.length) {
					name = [NSString stringWithFormat:@"%@", lLocalizedFirstName];
				} else if (lLocalizedlOrganization.length) {
					name = [NSString stringWithFormat:@"%@", lLocalizedlOrganization];
				}

				if (name != nil && [name length] > 0) {
					// Add the contact only if it fuzzy match filter too (if any)
					if ([ContactSelection getNameOrEmailFilter] == nil ||
						(ms_strcmpfuz([[[ContactSelection getNameOrEmailFilter] lowercaseString] UTF8String],
									  [[name lowercaseString] UTF8String]) == 0)) {

						// Sort contacts by first letter. We need to translate the name to ASCII first, because of UTF-8
						// issues. For instance
						// we expect order:  Alberta(A tilde) before ASylvano.
						NSData *name2ASCIIdata =
							[name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
						NSString *name2ASCII =
							[[NSString alloc] initWithData:name2ASCIIdata encoding:NSASCIIStringEncoding];
						NSString *firstChar = [[name2ASCII substringToIndex:1] uppercaseString];

						// Put in correct subDic
						if ([firstChar characterAtIndex:0] < 'A' || [firstChar characterAtIndex:0] > 'Z') {
							firstChar = @"#";
						}
						OrderedDictionary *subDic = [addressBookMap objectForKey:firstChar];
						if (subDic == nil) {
							subDic = [[OrderedDictionary alloc] init];
							[addressBookMap insertObject:subDic
												  forKey:firstChar
												selector:@selector(caseInsensitiveCompare:)];
						}
						while ([subDic objectForKey:name2ASCII] != nil) {
							name2ASCII = [name2ASCII stringByAppendingString:@"_"];
						}
						[subDic insertObject:lPerson forKey:name2ASCII selector:@selector(caseInsensitiveCompare:)];
					}
				}
			}
		}
	}
	[self.tableView reloadData];
}

static void sync_address_book(ABAddressBookRef addressBook, CFDictionaryRef info, void *context) {
	ContactsTableViewController *controller = (__bridge ContactsTableViewController *)context;
	ABAddressBookRevert(addressBook);
	[controller->avatarMap removeAllObjects];
	[controller loadData];
}

#pragma mark - UITableViewDataSource Functions

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return [addressBookMap allKeys];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [addressBookMap count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [(OrderedDictionary *)[addressBookMap objectForKey:[addressBookMap keyAtIndex:section]] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *kCellId = @"UIContactCell";
	UIContactCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
	if (cell == nil) {
		cell = [[UIContactCell alloc] initWithIdentifier:kCellId];

		// Background View
		UACellBackgroundView *selectedBackgroundView = [[UACellBackgroundView alloc] initWithFrame:CGRectZero];
        [selectedBackgroundView setBackgroundColor:LINPHONE_TABLE_CELL_BACKGROUND_COLOR];
		cell.selectedBackgroundView = selectedBackgroundView;
       // cell.contentView.backgroundColor =LINPHONE_TABLE_CELL_BACKGROUND_COLOR;
        cell.contentView.tintColor = [UIColor whiteColor];
        cell.textLabel.textColor =[UIColor whiteColor];
        cell.textLabel.highlightedTextColor = [UIColor whiteColor];
	}
	OrderedDictionary *subDic = [addressBookMap objectForKey:[addressBookMap keyAtIndex:[indexPath section]]];

	NSString *key = [[subDic allKeys] objectAtIndex:[indexPath row]];
	ABRecordRef contact = (__bridge ABRecordRef)([subDic objectForKey:key]);

	// Cached avatar
	UIImage *image = nil;
	id data = [avatarMap objectForKey:[NSNumber numberWithInt:ABRecordGetRecordID(contact)]];
	if (data == nil) {
		image = [FastAddressBook getContactImage:contact thumbnail:true];
		if (image != nil) {
			[avatarMap setObject:image forKey:[NSNumber numberWithInt:ABRecordGetRecordID(contact)]];
		} else {
			[avatarMap setObject:[NSNull null] forKey:[NSNumber numberWithInt:ABRecordGetRecordID(contact)]];
		}
	} else if (data != [NSNull null]) {
		image = data;
	}
	if (image == nil) {
		image = [UIImage imageNamed:@"avatar_unknown_small.png"];
	}
	[[cell avatarImage] setImage:image];

	[cell setContact:contact];
    
    [self attachLongPressListener:cell];
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [addressBookMap keyAtIndex:section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	OrderedDictionary *subDic = [addressBookMap objectForKey:[addressBookMap keyAtIndex:[indexPath section]]];
	ABRecordRef lPerson = (__bridge ABRecordRef)([subDic objectForKey:[subDic keyAtIndex:[indexPath row]]]);

	// Go to Contact details view
	ContactDetailsViewController *controller = DYNAMIC_CAST(
		[[PhoneMainView instance] changeCurrentView:[ContactDetailsViewController compositeViewDescription] push:TRUE],
		ContactDetailsViewController);
	if (controller != nil) {
		if ([ContactSelection getSelectionMode] != ContactSelectionModeEdit) {
			[controller setContact:lPerson];
		} else {
			[controller editContact:lPerson address:[ContactSelection getAddAddress]];
		}
	}
}

#pragma mark - MFMessageComposeViewControllerDelegate Functions

-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result{
    [controller dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark MFMailComposeViewControllerDelegate Functions
-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error{
    [controller dismissViewControllerAnimated:NO completion:nil];
}
#pragma mark - UITableViewDelegate Functions

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView
		   editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	// Detemine if it's in editing mode
	if (self.editing) {
		return UITableViewCellEditingStyleDelete;
	}
	return UITableViewCellEditingStyleNone;
}

@end
