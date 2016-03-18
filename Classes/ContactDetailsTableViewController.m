/* ContactDetailsTableViewController.m
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

#import "ContactDetailsTableViewController.h"
#import "PhoneMainView.h"
#import "UIEditableTableViewCell.h"
#import "UACellBackgroundView.h"
#import "UILinphone.h"
#import "OrderedDictionary.h"
#import "FastAddressBook.h"
#import "Utils.h"

#define DATEPICKER_HEIGHT 230

@interface Entry : NSObject

@property(assign) ABMultiValueIdentifier identifier;

@end

@implementation Entry

@synthesize identifier;

#pragma mark - Lifecycle Functions

- (id)initWithData:(ABMultiValueIdentifier)aidentifier {
	self = [super init];
	if (self != NULL) {
		[self setIdentifier:aidentifier];
	}
	return self;
}

@end

@interface ContactDetailsTableViewController() <UICustomPickerDelegate>

@property NSMutableArray *domains;
@property (nonatomic, strong) UICustomPicker *providerPickerView;

@end

@implementation ContactDetailsTableViewController

static const ContactSections_e contactSections[ContactSections_MAX] = {ContactSections_None, ContactSections_Number,
																	   ContactSections_Sip, ContactSections_Email};

@synthesize footerController;
@synthesize headerController;
@synthesize contactDetailsDelegate;
@synthesize contact;

#pragma mark - Lifecycle Functions

- (void)initContactDetailsTableViewController {
	dataCache = [[NSMutableArray alloc] init];

	// pre-fill the data-cache with empty arrays
	for (int i = ContactSections_Number; i < ContactSections_MAX; i++) {
		[dataCache addObject:@[]];
	}

	labelArray = [[NSMutableArray alloc]
		initWithObjects:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
						[NSString stringWithString:(NSString *)kABPersonPhoneMobileLabel],
						[NSString stringWithString:(NSString *)kABPersonPhoneIPhoneLabel],
						[NSString stringWithString:(NSString *)kABPersonPhoneMainLabel], nil];
	editingIndexPath = nil;
}

- (id)init {
	self = [super init];
	if (self) {
		[self initContactDetailsTableViewController];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
	self = [super initWithCoder:decoder];
	if (self) {
		[self initContactDetailsTableViewController];
	}
	return self;
}

- (void)dealloc {
	if (contact != nil && ABRecordGetRecordID(contact) == kABRecordInvalidID) {
		CFRelease(contact);
	}
}

#pragma mark - ViewController Functions

- (void)viewDidLoad {
	[super viewDidLoad];
	[headerController view]; // Force view load
	[footerController view]; // Force view load

	self.tableView.accessibilityIdentifier = @"Contact numbers table";
    [self loadProviderDomainsFromCache];
}

#pragma mark -

- (BOOL)isValid {
	return [headerController isValid];
}

- (void)updateModification {
	[contactDetailsDelegate onModification:nil];
}

- (NSMutableArray *)getSectionData:(NSInteger)section {
	if (contactSections[section] == ContactSections_Number) {
		return [dataCache objectAtIndex:0];
	} else if (contactSections[section] == ContactSections_Sip) {
		return [dataCache objectAtIndex:1];
	} else if (contactSections[section] == ContactSections_Email) {
		if ([[LinphoneManager instance] lpConfigBoolForKey:@"show_contacts_emails_preference"] == true) {
			return [dataCache objectAtIndex:2];
		} else {
			return nil;
		}
	}
	return nil;
}

- (ABPropertyID)propertyIDForSection:(ContactSections_e)section {
	switch (section) {
	case ContactSections_Sip:
		return kABPersonInstantMessageProperty;
	case ContactSections_Number:
		return kABPersonPhoneProperty;
	case ContactSections_Email:
		return kABPersonEmailProperty;
	default:
		return kABInvalidPropertyType;
	}
}

- (NSDictionary *)getLocalizedLabels {
	OrderedDictionary *dict = [[OrderedDictionary alloc] initWithCapacity:[labelArray count]];
	for (NSString *str in labelArray) {
		[dict setObject:[FastAddressBook localizedLabel:str] forKey:str];
	}
	return dict;
}

- (void)loadData {
	[dataCache removeAllObjects];

	if (contact == NULL)
		return;

	LOGI(@"Load data from contact %p", contact);
	// Phone numbers
	{
		ABMultiValueRef lMap = ABRecordCopyValue(contact, kABPersonPhoneProperty);
		NSMutableArray *subArray = [NSMutableArray array];
		if (lMap) {
			for (int i = 0; i < ABMultiValueGetCount(lMap); ++i) {
				ABMultiValueIdentifier identifier = ABMultiValueGetIdentifierAtIndex(lMap, i);
				Entry *entry = [[Entry alloc] initWithData:identifier];
				[subArray addObject:entry];
			}
			CFRelease(lMap);
		}
		[dataCache addObject:subArray];
	}

	// SIP (IM)
	{
		ABMultiValueRef lMap = ABRecordCopyValue(contact, kABPersonInstantMessageProperty);
		NSMutableArray *subArray = [NSMutableArray array];
		if (lMap) {
			for (int i = 0; i < ABMultiValueGetCount(lMap); ++i) {
				ABMultiValueIdentifier identifier = ABMultiValueGetIdentifierAtIndex(lMap, i);
				CFDictionaryRef lDict = ABMultiValueCopyValueAtIndex(lMap, i);
				BOOL add = false;
				if (CFDictionaryContainsKey(lDict, @"username")) {
						add = true;
				} else {
					// check domain
					LinphoneAddress *address = linphone_address_new(
						[(NSString *)CFDictionaryGetValue(lDict, @"username") UTF8String]);
					if (address) {
						if ([[ContactSelection getSipFilter] compare:@"*" options:NSCaseInsensitiveSearch] ==
							NSOrderedSame) {
							add = true;
						} else {
							NSString *domain = [NSString stringWithCString:linphone_address_get_domain(address)
																  encoding:[NSString defaultCStringEncoding]];
							add = [domain compare:[ContactSelection getSipFilter] options:NSCaseInsensitiveSearch] ==
								  NSOrderedSame;
						}
						linphone_address_destroy(address);
					} else {
						add = false;
					}
				}
				if (add) {
					Entry *entry = [[Entry alloc] initWithData:identifier];
					[subArray addObject:entry];
				}
				CFRelease(lDict);
			}
			CFRelease(lMap);
		}
		[dataCache addObject:subArray];
	}

	// Email
	if ([[LinphoneManager instance] lpConfigBoolForKey:@"show_contacts_emails_preference"] == true) {
		ABMultiValueRef lMap = ABRecordCopyValue(contact, kABPersonEmailProperty);
		NSMutableArray *subArray = [NSMutableArray array];
		if (lMap) {
			for (int i = 0; i < ABMultiValueGetCount(lMap); ++i) {
				ABMultiValueIdentifier identifier = ABMultiValueGetIdentifierAtIndex(lMap, i);
				CFDictionaryRef lDict = ABMultiValueCopyValueAtIndex(lMap, i);
				Entry *entry = [[Entry alloc] initWithData:identifier];
				[subArray addObject:entry];
				CFRelease(lDict);
			}
			CFRelease(lMap);
		}
		[dataCache addObject:subArray];
	}

	if (contactDetailsDelegate != nil) {
		[contactDetailsDelegate onModification:nil];
	}
	[self.tableView reloadData];
}

- (Entry *)setOrCreateSipContactEntry:(Entry *)entry withValue:(NSString *)value {
	ABMultiValueRef lcMap = ABRecordCopyValue(contact, kABPersonInstantMessageProperty);
	ABMutableMultiValueRef lMap;
	if (lcMap != NULL) {
		lMap = ABMultiValueCreateMutableCopy(lcMap);
		CFRelease(lcMap);
	} else {
		lMap = ABMultiValueCreateMutable(kABStringPropertyType);
	}
	ABMultiValueIdentifier index;
	CFErrorRef error = NULL;

	NSDictionary *lDict = @{
		(NSString *)kABPersonInstantMessageUsernameKey : value, (NSString *)
		kABPersonInstantMessageServiceKey : [LinphoneManager instance].contactSipField
	};

	if (entry) {
		index = (int)ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
		ABMultiValueReplaceValueAtIndex(lMap, (__bridge CFTypeRef)(lDict), index);
	} else {
		CFStringRef label = (__bridge CFStringRef)[labelArray objectAtIndex:0];
		ABMultiValueAddValueAndLabel(lMap, (__bridge CFTypeRef)lDict, label, &index);
	}

	if (!ABRecordSetValue(contact, kABPersonInstantMessageProperty, lMap, &error)) {
		LOGI(@"Can't set contact with value [%@] cause [%@]", value, [(__bridge NSError *)error localizedDescription]);
		CFRelease(lMap);
	} else {
		if (entry == nil) {
			entry = [[Entry alloc] initWithData:index];
		}
		CFRelease(lMap);

		/*check if message type is kept or not*/
		lcMap = ABRecordCopyValue(contact, kABPersonInstantMessageProperty);
		lMap = ABMultiValueCreateMutableCopy(lcMap);
		CFRelease(lcMap);
		index = (int)ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
		lDict = CFBridgingRelease(ABMultiValueCopyValueAtIndex(lMap, index));

		if ([lDict objectForKey:(__bridge NSString *)kABPersonInstantMessageServiceKey] == nil) {
			/*too bad probably a gtalk number, storing uri*/
			NSString *username = [lDict objectForKey:(NSString *)@"username"];
			LinphoneAddress *address = linphone_core_interpret_url([LinphoneManager getLc], [username UTF8String]);
			if (address) {
				char *uri = linphone_address_as_string_uri_only(address);
				NSDictionary *dict2 = @{
					(NSString *)@"username" :
									[NSString stringWithCString:uri encoding:[NSString defaultCStringEncoding]],
								(NSString *)
					kABPersonInstantMessageServiceKey : [LinphoneManager instance].contactSipField
				};

				ABMultiValueReplaceValueAtIndex(lMap, (__bridge CFTypeRef)(dict2), index);

				if (!ABRecordSetValue(contact, kABPersonInstantMessageProperty, lMap, &error)) {
					LOGI(@"Can't set contact with value [%@] cause [%@]", value,
						 [(__bridge NSError *)error localizedDescription]);
				}
				linphone_address_destroy(address);
				ms_free(uri);
			}
		}
		CFRelease(lMap);
	}

	return entry;
}

- (void)setSipContactEntry:(Entry *)entry withValue:(NSString *)value {
	[self setOrCreateSipContactEntry:entry withValue:value];
}
- (void)addEntry:(UITableView *)tableview section:(NSInteger)section animated:(BOOL)animated {
	[self addEntry:tableview section:section animated:animated value:@""];
}

- (void)addEntry:(UITableView *)tableview section:(NSInteger)section animated:(BOOL)animated value:(NSString *)value {
	NSMutableArray *sectionArray = [self getSectionData:section];
	NSUInteger count = [sectionArray count];
	CFErrorRef error = NULL;
	bool added = TRUE;
	if (contactSections[section] == ContactSections_Number) {
		ABMultiValueIdentifier identifier;
		ABMultiValueRef lcMap = ABRecordCopyValue(contact, kABPersonPhoneProperty);
		ABMutableMultiValueRef lMap;
		if (lcMap != NULL) {
			lMap = ABMultiValueCreateMutableCopy(lcMap);
			CFRelease(lcMap);
		} else {
			lMap = ABMultiValueCreateMutable(kABStringPropertyType);
		}
		CFStringRef label = (__bridge CFStringRef)[labelArray objectAtIndex:0];
		if (!ABMultiValueAddValueAndLabel(lMap, (__bridge CFTypeRef)(value), label, &identifier)) {
			added = false;
		}

		if (added && ABRecordSetValue(contact, kABPersonPhoneProperty, lMap, &error)) {
			Entry *entry = [[Entry alloc] initWithData:identifier];
			[sectionArray addObject:entry];
		} else {
			added = false;
			LOGI(@"Can't add entry: %@", [(__bridge NSError *)error localizedDescription]);
		}
		CFRelease(lMap);
	} else if (contactSections[section] == ContactSections_Sip) {
		Entry *entry = [self setOrCreateSipContactEntry:nil withValue:value];
		if (entry) {
			[sectionArray addObject:entry];
			added = true;
		} else {
			added = false;
			LOGE(@"Can't add entry for value: %@", value);
		}
	} else if (contactSections[section] == ContactSections_Email) {
		ABMultiValueIdentifier identifier;
		ABMultiValueRef lcMap = ABRecordCopyValue(contact, kABPersonEmailProperty);
		ABMutableMultiValueRef lMap;
		if (lcMap != NULL) {
			lMap = ABMultiValueCreateMutableCopy(lcMap);
			CFRelease(lcMap);
		} else {
			lMap = ABMultiValueCreateMutable(kABStringPropertyType);
		}
		CFStringRef label = (__bridge CFStringRef)[labelArray objectAtIndex:0];
		if (!ABMultiValueAddValueAndLabel(lMap, (__bridge CFTypeRef)(value), label, &identifier)) {
			added = false;
		}

		if (added && ABRecordSetValue(contact, kABPersonEmailProperty, lMap, &error)) {
			Entry *entry = [[Entry alloc] initWithData:identifier];
			[sectionArray addObject:entry];
		} else {
			added = false;
			LOGI(@"Can't add entry: %@", [(__bridge NSError *)error localizedDescription]);
		}
		CFRelease(lMap);
	}

	if (added && animated) {
		// Update accessory
		if (count > 0) {
			[tableview reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:count - 1
																						  inSection:section]]
							 withRowAnimation:FALSE];
		}
		[tableview
			insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:count inSection:section]]
				  withRowAnimation:UITableViewRowAnimationFade];
	}
	if (contactDetailsDelegate != nil) {
		[contactDetailsDelegate onModification:nil];
	}
}

- (void)removeEmptyEntry:(UITableView *)tableview section:(NSInteger)section animated:(BOOL)animated {
	NSMutableArray *sectionDict = [self getSectionData:section];
	NSInteger row = [sectionDict count] - 1;
	if (row >= 0) {
		Entry *entry = [sectionDict objectAtIndex:row];

		ABPropertyID property = [self propertyIDForSection:contactSections[section]];
		if (property != kABInvalidPropertyType) {
			ABMultiValueRef lMap = ABRecordCopyValue(contact, property);
			NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
			CFTypeRef valueRef = ABMultiValueCopyValueAtIndex(lMap, index);
			CFTypeRef toRelease = nil;
			NSString *value = nil;
			if (property == kABPersonInstantMessageProperty) {
				// when we query the instanteMsg property we get a dictionary instead of a value
				toRelease = valueRef;
				value = CFDictionaryGetValue(valueRef, kABPersonInstantMessageUsernameKey);
			} else {
				value = CFBridgingRelease(valueRef);
			}

			if (value.length == 0) {
				[self removeEntry:tableview path:[NSIndexPath indexPathForRow:row inSection:section] animated:animated];
			}
			if (toRelease != nil) {
				CFRelease(toRelease);
			}

			CFRelease(lMap);
		}
	}
	if (contactDetailsDelegate != nil) {
		[contactDetailsDelegate onModification:nil];
	}
}

- (void)removeEntry:(UITableView *)tableview path:(NSIndexPath *)indexPath animated:(BOOL)animated {
	NSMutableArray *sectionArray = [self getSectionData:[indexPath section]];
	Entry *entry = [sectionArray objectAtIndex:[indexPath row]];
	ABPropertyID property = [self propertyIDForSection:contactSections[indexPath.section]];

	if (property != kABInvalidPropertyType) {
		ABMultiValueRef lcMap = ABRecordCopyValue(contact, property);
		ABMutableMultiValueRef lMap = ABMultiValueCreateMutableCopy(lcMap);
		CFRelease(lcMap);
		NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
		ABMultiValueRemoveValueAndLabelAtIndex(lMap, index);
		ABRecordSetValue(contact, property, lMap, nil);
		CFRelease(lMap);
	}

	[sectionArray removeObjectAtIndex:[indexPath row]];

	NSArray *tagInsertIndexPath = [NSArray arrayWithObject:indexPath];
	if (animated) {
		[tableview deleteRowsAtIndexPaths:tagInsertIndexPath withRowAnimation:UITableViewRowAnimationFade];
	}
}

#pragma mark - Property Functions

- (void)setContact:(ABRecordRef)acontact {
	if (contact != nil && ABRecordGetRecordID(contact) == kABRecordInvalidID) {
		CFRelease(contact);
	}
	contact = acontact;
	[self loadData];
	[headerController setContact:contact];
}

- (void)addPhoneField:(NSString *)number {
	int i = 0;
	while (i < ContactSections_MAX && contactSections[i] != ContactSections_Number)
		++i;
	[self addEntry:[self tableView] section:i animated:FALSE value:number];
}

- (void)addSipField:(NSString *)address {
	int i = 0;
	while (i < ContactSections_MAX && contactSections[i] != ContactSections_Sip)
		++i;
	[self addEntry:[self tableView] section:i animated:FALSE value:address];
}

- (void)addEmailField:(NSString *)address {
	int i = 0;
	while (i < ContactSections_MAX && contactSections[i] != ContactSections_Email)
		++i;
	[self addEntry:[self tableView] section:i animated:FALSE value:address];
}

#pragma mark - UITableViewDataSource Functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return ContactSections_MAX;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[self getSectionData:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *kCellId = @"ContactDetailsCell";
    tableView.backgroundColor =[UIColor whiteColor];
    UIEditableTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
	if (cell == nil) {
		cell = [[UIEditableTableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:kCellId];
		[cell.detailTextField setDelegate:self];
        [cell.detailTextField setTag:indexPath.row];
		[cell.detailTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
		[cell.detailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
		[cell setBackgroundColor:[UIColor whiteColor]];
		// Background View
		UACellBackgroundView *selectedBackgroundView = [[UACellBackgroundView alloc] initWithFrame:CGRectZero];
        [selectedBackgroundView setBackgroundColor:LINPHONE_MAIN_COLOR];
        cell.selectedBackgroundView = selectedBackgroundView;
        // cell.contentView.backgroundColor =LINPHONE_TABLE_CELL_BACKGROUND_COLOR;
        cell.contentView.tintColor = [UIColor whiteColor];
        cell.textLabel.textColor =LINPHONE_TABLE_CELL_BACKGROUND_COLOR;
        cell.textLabel.highlightedTextColor = [UIColor whiteColor];
        cell.contentView.backgroundColor=[UIColor whiteColor];
	}

	NSMutableArray *sectionDict = [self getSectionData:[indexPath section]];
	Entry *entry = [sectionDict objectAtIndex:[indexPath row]];

	NSString *value = @"";
	// default label is our app name
	NSString *label = [FastAddressBook localizedLabel:[labelArray objectAtIndex:0]];

	if (contactSections[[indexPath section]] == ContactSections_Number) {
		ABMultiValueRef lMap = ABRecordCopyValue(contact, kABPersonPhoneProperty);
		NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
		NSString *labelRef = CFBridgingRelease(ABMultiValueCopyLabelAtIndex(lMap, index));
		if (labelRef != NULL) {
			label = [FastAddressBook localizedLabel:labelRef];
		}
		NSString *valueRef = CFBridgingRelease(ABMultiValueCopyValueAtIndex(lMap, index));
		if (valueRef != NULL) {
			value = [FastAddressBook localizedLabel:valueRef];
		}
		CFRelease(lMap);
	} else if (contactSections[[indexPath section]] == ContactSections_Sip) {
		ABMultiValueRef lMap = ABRecordCopyValue(contact, kABPersonInstantMessageProperty);
		NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);

		NSString *labelRef = CFBridgingRelease(ABMultiValueCopyLabelAtIndex(lMap, index));
		if (labelRef != NULL) {
			label = [FastAddressBook localizedLabel:labelRef];
		}

        [cell.providerPicker setTag:indexPath.row];
        [cell.providerPicker addTarget:self
                                action:@selector(onProviderPickerClicked:)forControlEvents:UIControlEventTouchUpInside];
        
		CFDictionaryRef lDict = ABMultiValueCopyValueAtIndex(lMap, index);
		value = (__bridge NSString *)(CFDictionaryGetValue(lDict, @"username"));
		if (value != NULL) {
			LinphoneAddress *addr = NULL;
			if ([[LinphoneManager instance] lpConfigBoolForKey:@"contact_display_username_only"] &&
				(addr = linphone_address_new([value UTF8String]))) {
				if (linphone_address_get_username(addr)) {
					value = [NSString stringWithCString:linphone_address_get_username(addr)
											   encoding:[NSString defaultCStringEncoding]];
				}
			}
			if (addr)
				linphone_address_destroy(addr);
		}
		CFRelease(lDict);
		CFRelease(lMap);
	} else if (contactSections[[indexPath section]] == ContactSections_Email) {
		ABMultiValueRef lMap = ABRecordCopyValue(contact, kABPersonEmailProperty);
		NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
		NSString *labelRef = CFBridgingRelease(ABMultiValueCopyLabelAtIndex(lMap, index));
		if (labelRef != NULL) {
			label = [FastAddressBook localizedLabel:labelRef];
		}
		NSString *valueRef = CFBridgingRelease(ABMultiValueCopyValueAtIndex(lMap, index));
		if (valueRef != NULL) {
			value = [FastAddressBook localizedLabel:valueRef];
		}
		CFRelease(lMap);
	}
	[cell.textLabel setText:label];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"force508"]) {
        [cell.textLabel setTextColor:[UIColor blackColor]];
    } else {
        [cell.textLabel setTextColor:[UIColor grayColor]];
    }
    
	[cell.detailTextLabel setText:value];
	[cell.detailTextField setText:value];
	if (contactSections[[indexPath section]] == ContactSections_Number) {
		[cell.detailTextField setKeyboardType:UIKeyboardTypePhonePad];
		[cell.detailTextField setPlaceholder:NSLocalizedString(@"Phone number", nil)];
	} else if (contactSections[[indexPath section]] == ContactSections_Sip) {
        
		[cell.detailTextField setKeyboardType:UIKeyboardTypeASCIICapable];
		[cell.detailTextField setPlaceholder:NSLocalizedString(@"SIP address", nil)];
        [cell.providerPicker setBackgroundColor:[UIColor darkGrayColor]];
        
        NSString *currentDomain = [self getDomainFromSip:value];
        NSString *currentSipAddress = [self getAddressFromSip:value];
        
        if(![self.tableView isEditing]){
            [cell.providerPicker setHidden:YES];
            [cell.providerPicker setEnabled:NO];
            cell.detailTextLabel.text = currentSipAddress;
        }
        else{
            [cell.providerPicker setHidden:NO];
            [cell.providerPicker setEnabled:YES];
            cell.detailTextField.text = currentSipAddress;
        }
        
        if (currentDomain.length > 0) {
            
            UIImage *image = [self fetchProviderImageWithDomain:currentDomain];
            
            if (image) {
                [cell.providerPicker setImage:image forState:UIControlStateNormal];
                [cell.providerPicker setBackgroundColor:[UIColor clearColor]];
            }
            else {
                [cell.providerPicker setImage:nil forState:UIControlStateNormal];
            }
        }
        else {
            [cell.providerPicker setImage:nil forState:UIControlStateNormal];
        }
	} else if (contactSections[[indexPath section]] == ContactSections_Email) {
		[cell.detailTextField setKeyboardType:UIKeyboardTypeASCIICapable];
		[cell.detailTextField setPlaceholder:NSLocalizedString(@"Email address", nil)];
	}
    



	return cell;
}

-(void) loadProviderDomainsFromCache{
    NSString *name;
    self.domains = [[NSMutableArray alloc] init];
    name = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"provider%d", 0]];
    
    for(int i = 1; name; i++){
        [self.domains addObject:name];
        name = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"provider%d", i]];
    }
}

-(IBAction)onProviderPickerClicked:(id)sender {
    
    [self setupProviderPickerViewWithTag:[(UIButton*)sender tag]];
    
    /*
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Available in General Release",nil)
                                                                   message:@"Select the SIP provider of the person you wish to call."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    if (self.domains) {
        UIButton *btn = (UIButton*)sender;

        NSIndexPath *path = [NSIndexPath indexPathForRow:btn.tag inSection:ContactSections_Sip];
        UIEditableTableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
        for (NSString *domain in self.domains) {
            UIAlertAction* providerAction = [UIAlertAction actionWithTitle:domain
                                         style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action) {
                                               NSString *domain = @"";
                                               //Todo: connect CDN provided image to this
                                               for(int i = 0; i < self.domains.count; i++){
                                                   if([action.title isEqualToString:[self.domains objectAtIndex:i]]){
                                                       domain = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"provider%d_domain", i]];
                                                   }
                                               }
                                               //Seperate username from domain in contact address, append
                                               //new domain
                                               if(!domain) { domain = @""; }
                                               
                                               NSString *username = [cell.detailTextField.text componentsSeparatedByString:@"@"][0];
                                               cell.detailTextField.text = [NSString stringWithFormat:@"%@@%@", username, domain];
                                           }];
            [providerAction setEnabled:YES];
            [alert addAction:providerAction];
            [alert.view setBackgroundColor:[UIColor blackColor]];
            [alert setModalPresentationStyle:UIModalPresentationPopover];
            
            UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
            UIButton *button = (UIButton*)sender;
            popPresenter.sourceView = button;
            popPresenter.sourceRect = button.bounds;
            
        }
    }
    UIAlertAction* none = [UIAlertAction actionWithTitle:NSLocalizedString(@"Leave empty", nil)
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction * action) {
                                                 }];
    [alert addAction:none];
    [self presentViewController:alert animated:YES completion:nil];
*/
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	NSMutableArray *sectionDict = [self getSectionData:[indexPath section]];
	Entry *entry = [sectionDict objectAtIndex:[indexPath row]];
	if (![self isEditing]) {
		NSString *dest = NULL;
		;
		if (contactSections[[indexPath section]] == ContactSections_Number) {
			ABMultiValueRef lMap = ABRecordCopyValue(contact, kABPersonPhoneProperty);
			NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
			NSString *valueRef = CFBridgingRelease(ABMultiValueCopyValueAtIndex(lMap, index));
			if (valueRef != NULL) {
				char normalizedPhoneNumber[256];
				linphone_proxy_config_normalize_number(linphone_core_get_default_proxy_config([LinphoneManager getLc]),
													   [valueRef UTF8String], normalizedPhoneNumber,
													   sizeof(normalizedPhoneNumber));
				dest = [NSString stringWithUTF8String:normalizedPhoneNumber];
			}
			CFRelease(lMap);
		} else if (contactSections[[indexPath section]] == ContactSections_Sip) {
			ABMultiValueRef lMap = ABRecordCopyValue(contact, kABPersonInstantMessageProperty);
			NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
			CFDictionaryRef lDict = ABMultiValueCopyValueAtIndex(lMap, index);
			NSString *valueRef = (__bridge NSString *)(CFDictionaryGetValue(lDict, @"username"));
			dest = [FastAddressBook normalizeSipURI:(NSString *)valueRef];
			CFRelease(lDict);
			CFRelease(lMap);
		} else if (contactSections[[indexPath section]] == ContactSections_Email) {
			ABMultiValueRef lMap = ABRecordCopyValue(contact, kABPersonEmailProperty);
			NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
			NSString *valueRef = CFBridgingRelease(ABMultiValueCopyValueAtIndex(lMap, index));
			if (valueRef != NULL) {
				dest = [FastAddressBook normalizeSipURI:(NSString *)(valueRef)];
			}
			CFRelease(lMap);
		}
		if (dest != nil) {
			NSString *displayName = [FastAddressBook getContactDisplayName:contact];
			if ([ContactSelection getSelectionMode] != ContactSelectionModeMessage) {
				// Go to dialer view
				DialerViewController *controller = DYNAMIC_CAST(
					[[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]],
					DialerViewController);
				if (controller != nil) {
					[controller call:dest displayName:displayName];
				}
			} else {
				// Go to Chat room view
				[[PhoneMainView instance]
					popToView:[ChatViewController compositeViewDescription]]; // Got to Chat and push ChatRoom
				ChatRoomViewController *controller = DYNAMIC_CAST(
					[[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription]
														   push:TRUE],
					ChatRoomViewController);
				if (controller != nil) {
					LinphoneChatRoom *room =
						linphone_core_get_chat_room_from_uri([LinphoneManager getLc], [dest UTF8String]);
					[controller setChatRoom:room];
				}
			}
		}
	} else {
		NSString *key = nil;
		ABPropertyID property = [self propertyIDForSection:contactSections[indexPath.section]];

		if (property != kABInvalidPropertyType) {
			ABMultiValueRef lMap = ABRecordCopyValue(contact, property);
			NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
			NSString *labelRef = CFBridgingRelease(ABMultiValueCopyLabelAtIndex(lMap, index));
			if (labelRef != NULL) {
				key = (NSString *)(labelRef);
			}
			CFRelease(lMap);
		}
		if (key != nil) {
			editingIndexPath = indexPath;
			ContactDetailsLabelViewController *controller = DYNAMIC_CAST(
				[[PhoneMainView instance] changeCurrentView:[ContactDetailsLabelViewController compositeViewDescription]
													   push:TRUE],
				ContactDetailsLabelViewController);
			if (controller != nil) {
				[controller setDataList:[self getLocalizedLabels]];
				[controller setSelectedData:key];
				[controller setDelegate:self];
			}
		}
	}
}

- (void)tableView:(UITableView *)tableView
	commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
	 forRowAtIndexPath:(NSIndexPath *)indexPath {
	[LinphoneUtils findAndResignFirstResponder:[self tableView]];
	if (editingStyle == UITableViewCellEditingStyleInsert) {
		[tableView beginUpdates];
		[self addEntry:tableView section:[indexPath section] animated:TRUE];
		[tableView endUpdates];
	} else if (editingStyle == UITableViewCellEditingStyleDelete) {
		[tableView beginUpdates];
		[self removeEntry:tableView path:indexPath animated:TRUE];
		[tableView endUpdates];
	}
}

#pragma mark - UITableViewDelegate Functions

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	bool_t showEmails = [[LinphoneManager instance] lpConfigBoolForKey:@"show_contacts_emails_preference"];
	// Resign keyboard
	if (!editing) {
		[LinphoneUtils findAndResignFirstResponder:[self tableView]];
	}

	[headerController setEditing:editing animated:animated];
	[footerController setEditing:editing animated:animated];

	if (animated) {
		[self.tableView beginUpdates];
	}
    long tempEntriesCount = [[self getSectionData:ContactSections_Sip] count];
	if (editing) {
		// add phony entries so that the user can add new data
		for (int section = 0; section < [self numberOfSectionsInTableView:[self tableView]]; ++section) {
			if (contactSections[section] == ContactSections_Number || contactSections[section] == ContactSections_Sip ||
				(showEmails && contactSections[section] == ContactSections_Email)) {
				[self addEntry:self.tableView section:section animated:animated];
			}

            if(contactSections[section] == ContactSections_Sip){
                for(int row = 0; row < [[self getSectionData:section] count]; ++row){
                    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:ContactSections_Sip];
                    UIEditableTableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
                    [cell.providerPicker setHidden:YES];
                    [cell.providerPicker setEnabled:NO];
                }
            }
        }
        
	} else {
		for (int section = 0; section < [self numberOfSectionsInTableView:[self tableView]]; ++section) {
			// remove phony entries that were not filled by the user
			if (contactSections[section] == ContactSections_Number || contactSections[section] == ContactSections_Sip ||
				(showEmails && contactSections[section] == ContactSections_Email)) {

				[self removeEmptyEntry:self.tableView section:section animated:animated];
				if ([[self getSectionData:section] count] == 0 && animated) { // the section is empty -> remove titles
					[self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section]
								  withRowAnimation:UITableViewRowAnimationFade];
				}
			}
		}
	}
	if (animated) {
		[self.tableView endUpdates];
	}

	[super setEditing:editing animated:animated];
	if (contactDetailsDelegate != nil) {
		[contactDetailsDelegate onModification:nil];
	}
    if(editing && tempEntriesCount != 0){
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:ContactSections_Sip]
                      withRowAnimation:UITableViewRowAnimationNone];
    }

}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
		   editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSInteger last_index = [[self getSectionData:[indexPath section]] count] - 1;
	if (indexPath.row == last_index) {
		return UITableViewCellEditingStyleInsert;
	}
	return UITableViewCellEditingStyleDelete;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (section == ContactSections_None) {
		return [headerController view];
	} else {
        // create the parent view that will hold header Label
        UIView *customView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, [self tableView:tableView heightForHeaderInSection:section])];
        
        if (contactSections[section] == ContactSections_Number ||
            contactSections[section] == ContactSections_Sip ||
            contactSections[section] == ContactSections_Email) {
            UILabel * headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            headerLabel.backgroundColor = [UIColor clearColor];
            headerLabel.opaque = NO;
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"force508"]) {
                headerLabel.textColor = [UIColor blackColor];
            } else {
                headerLabel.textColor = [UIColor grayColor];
            }
            headerLabel.font = [UIFont boldSystemFontOfSize:17];
            headerLabel.frame = CGRectMake(10.0, 0.0, customView.frame.size.width, customView.frame.size.height);
            
            if (contactSections[section] == ContactSections_Number) {
                headerLabel.text = NSLocalizedString(@"Phone numbers", nil);
            } else if (contactSections[section] == ContactSections_Sip) {
                headerLabel.text = NSLocalizedString(@"SIP addresses", nil);
            } else if (contactSections[section] == ContactSections_Email) {
                headerLabel.text = NSLocalizedString(@"Email addresses", nil);
            }

            [customView addSubview:headerLabel];
            
            return customView;
        }
	}
    
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	if (section == (ContactSections_MAX - 1)) {
		if (ABRecordGetRecordID(contact) != kABRecordInvalidID) {
			return [footerController view];
		}
	}
	return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == ContactSections_None) {
		return [UIContactDetailsHeader height:[headerController isEditing]];
	} else {
		// Hide section if nothing in it
		if ([[self getSectionData:section] count] > 0)
			return 22;
		else
			return 0.000001f; // Hack UITableView = 0
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	if (section == (ContactSections_MAX - 1)) {
		if (ABRecordGetRecordID(contact) != kABRecordInvalidID) {
			return [UIContactDetailsFooter height:[footerController isEditing]];
		} else {
			return 0.000001f; // Hack UITableView = 0
		}
	} else if (section == ContactSections_None) {
		return 0.000001f; // Hack UITableView = 0
	}
	return 10.0f;
}

#pragma mark - ContactDetailsLabelDelegate Functions

- (void)changeContactDetailsLabel:(NSString *)value {
	if (value != nil) {
		NSInteger section = editingIndexPath.section;
		NSMutableArray *sectionDict = [self getSectionData:section];
		ABPropertyID property = [self propertyIDForSection:(int)section];
		Entry *entry = [sectionDict objectAtIndex:editingIndexPath.row];

		if (property != kABInvalidPropertyType) {
			ABMultiValueRef lcMap = ABRecordCopyValue(contact, kABPersonPhoneProperty);
			ABMutableMultiValueRef lMap = ABMultiValueCreateMutableCopy(lcMap);
			CFRelease(lcMap);
			NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
			ABMultiValueReplaceLabelAtIndex(lMap, (__bridge CFStringRef)(value), index);
			ABRecordSetValue(contact, kABPersonPhoneProperty, lMap, nil);
			CFRelease(lMap);
		}

		[self.tableView beginUpdates];
		[self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:editingIndexPath] withRowAnimation:FALSE];
		[self.tableView reloadSectionIndexTitles];
		[self.tableView endUpdates];
	}
	editingIndexPath = nil;
}

#pragma mark - UITextFieldDelegate Functions

- (BOOL)textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
				replacementString:(NSString *)string {
	if (contactDetailsDelegate != nil) {
		[self performSelector:@selector(updateModification) withObject:nil afterDelay:0];
	}
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	UIView *view = [textField superview];
	// Find TableViewCell
	while (view != nil && ![view isKindOfClass:[UIEditableTableViewCell class]])
		view = [view superview];
	if (view != nil) {
		UIEditableTableViewCell *cell = (UIEditableTableViewCell *)view;
		NSIndexPath *path = [self.tableView indexPathForCell:cell];
		NSMutableArray *sectionDict = [self getSectionData:[path section]];
		Entry *entry = [sectionDict objectAtIndex:[path row]];
		ContactSections_e sect = contactSections[[path section]];

		ABPropertyID property = [self propertyIDForSection:sect];
		NSString *value = [textField text];

		if (sect == ContactSections_Sip) {
			[self setSipContactEntry:entry withValue:value];
		} else if (property != kABInvalidPropertyType) {
			ABMultiValueRef lcMap = ABRecordCopyValue(contact, property);
			ABMutableMultiValueRef lMap = ABMultiValueCreateMutableCopy(lcMap);
			CFRelease(lcMap);
			NSInteger index = ABMultiValueGetIndexForIdentifier(lMap, [entry identifier]);
			ABMultiValueReplaceValueAtIndex(lMap, (__bridge CFStringRef)value, index);
			ABRecordSetValue(contact, property, lMap, nil);
			CFRelease(lMap);
		}

		[cell.detailTextLabel setText:value];
	} else {
		LOGE(@"Not valid UIEditableTableViewCell");
	}
	if (contactDetailsDelegate != nil) {
		[self performSelector:@selector(updateModification) withObject:nil afterDelay:0];
	}
    
	return TRUE;
}

- (void)setupProviderPickerViewWithTag:(NSUInteger)tag {
    
    [self setRecursiveUserInteractionEnabled:false];
    CGRect frame = CGRectMake(0, 100 + DATEPICKER_HEIGHT / 2, self.view.frame.size.width, DATEPICKER_HEIGHT);
    self.providerPickerView = [[UICustomPicker alloc] initWithFrame:frame SourceList:self.domains];
    [self.providerPickerView setAlpha:1.0f];
    self.providerPickerView.delegate = self;
    self.providerPickerView.tag = tag;
    self.providerPickerView.userInteractionEnabled = true;
    [self.view addSubview:self.providerPickerView];
    
    if (self.domains.count > 0) {
        [self.providerPickerView setSelectedRow:0];
    }
}

- (void)setRecursiveUserInteractionEnabled:(BOOL)value {
    
    //self.view.userInteractionEnabled =   value;
    for (UIView *view in self.view.subviews) {
        view.userInteractionEnabled = value;
    }
}

- (NSString *)pathForImageCache {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *cachePath = [documentsDirectory stringByAppendingPathComponent:@"ImageCache"];
    
    return cachePath;
}

- (UIImage *)fetchProviderImageWithDomain:(NSString *)domain {
    
    NSString *lowercaseName = [domain lowercaseString];
    NSString *name = [lowercaseName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    NSString *cachePath = [self pathForImageCache];
    NSString *imageName = [NSString stringWithFormat:@"provider_%@.png", name];
    NSString *imagePath = [cachePath stringByAppendingPathComponent:imageName];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    
    if (!image) {
        NSString *localImageName = nil;
        if ([lowercaseName containsString:@"sorenson"]) {
            localImageName = @"provider0.png";
        }
        else if ([lowercaseName containsString:@"zvrs"]) {
            localImageName = @"provider1.png";
        }
        else if ([lowercaseName containsString:@"star"]) {
            localImageName = @"provider2.png";
        }
        else if ([lowercaseName containsString:@"convo"]) {
            localImageName = @"provider5.png";
        }
        else if ([lowercaseName containsString:@"global"]) {
            localImageName = @"provider4.png";
        }
        else if ([lowercaseName containsString:@"purple"]) {
            localImageName = @"provider3.png";
        }
        else if ([lowercaseName containsString:@"ace"]) {
            localImageName = @"ace_icon2x.png";
        }
        else {
            localImageName = @"ace_icon2x.png";
        }
        image = [UIImage imageNamed:localImageName];
    }
    
    return image;
}


- (NSString *)getAddressFromSip:(NSString *)sip {
    
    NSString *address = @"";
    
    if ([sip containsString:@"@"]) {
        
        NSArray *separatedSip = [sip componentsSeparatedByString:@"@"];
        if (separatedSip.count > 0) {
            address = [separatedSip firstObject];
        }
        else {
            address = sip;
        }
    }
    
    return address;
}

- (NSString *)getDomainFromSip:(NSString *)sip {
    
    if ([sip containsString:@"@"]) {
        
        NSArray *separatedSip = [sip componentsSeparatedByString:@"@"];
        if (separatedSip.count > 0) {
            return [separatedSip lastObject];
        }
        else {
            return @"";
        }
    }
    else {
        return @"";
    }
}

#pragma mark - UICustomPicker Delegate
- (void)didCancelUICustomPicker:(UICustomPicker *)customPicker {
    
    [self setRecursiveUserInteractionEnabled:true];
}

- (void)didSelectUICustomPicker:(UICustomPicker *)customPicker selectedItem:(NSString*)item {
    
    [self setRecursiveUserInteractionEnabled:true];
}

- (void)didSelectUICustomPicker:(UICustomPicker *)customPicker didSelectRow:(NSInteger)row {
    
    if (self.domains) {
        NSIndexPath *path = [NSIndexPath indexPathForRow:customPicker.tag inSection:ContactSections_Sip];
        UIEditableTableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
        NSString *selectedDomain = [self.domains objectAtIndex:row];
        NSString *sipAddress = [self getAddressFromSip:cell.detailTextLabel.text];
        NSString *newSipAddress = [NSString stringWithFormat:@"%@@%@", sipAddress, selectedDomain];
        
        NSIndexPath *cellPath = [self.tableView indexPathForCell:cell];
        NSMutableArray *sectionDict = [self getSectionData:cellPath.section];
        Entry *entry = [sectionDict objectAtIndex:cellPath.row];
        [self setSipContactEntry:entry withValue:newSipAddress];
        
        if(![self.tableView isEditing]){
            cell.detailTextField.text = newSipAddress;
        }
        else{
            cell.detailTextLabel.text = newSipAddress;
        }
        
        
        UIImage *image = [self fetchProviderImageWithDomain:selectedDomain];
        [cell.providerPicker setBackgroundColor:[UIColor clearColor]];
        [cell.providerPicker setImage:image forState:UIControlStateNormal];
        [self setRecursiveUserInteractionEnabled:true];
    }
}

@end
