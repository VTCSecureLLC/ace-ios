/* SettingsViewController.m
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

#import "SettingsViewController.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "UILinphone.h"
#import "UACellBackgroundView.h"
#import "SDPNegotiationService.h"
#import "DCRoundSwitch.h"

#import "IASKSpecifierValuesViewController.h"
#import "IASKPSTextFieldSpecifierViewCell.h"
#import "IASKPSTitleValueSpecifierViewCell.h"
#import "IASKSpecifier.h"
#import "IASKTextField.h"
#include "linphone/lpconfig.h"
#import "InfColorPicker/InfColorPickerController.h"
#import "DTAlertView.h"

#ifdef DEBUG
@interface UIDevice (debug)

- (void)_setBatteryLevel:(float)level;
- (void)_setBatteryState:(int)state;

@end
#endif

@interface SettingsViewController (private)

+ (IASKSpecifier *)filterSpecifier:(IASKSpecifier *)specifier;

@end

#pragma mark - IASKSwitchEx Class

@interface IASKSwitchEx : DCRoundSwitch {
	NSString *_key;
}

@property(nonatomic, strong) NSString *key;

@end

@implementation IASKSwitchEx

@synthesize key = _key;

- (void)dealloc {
	_key = nil;
}

@end

#pragma mark - IASKSpecifierValuesViewControllerEx Class

// Patch IASKSpecifierValuesViewController
@interface IASKSpecifierValuesViewControllerEx : IASKSpecifierValuesViewController

@end

@implementation IASKSpecifierValuesViewControllerEx

- (void)initIASKSpecifierValuesViewControllerEx {
	[self.view setBackgroundColor:[UIColor clearColor]];
}

- (id)init {
	self = [super init];
	if (self != nil) {
		[self initIASKSpecifierValuesViewControllerEx];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self != nil) {
		[self initIASKSpecifierValuesViewControllerEx];
	}
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self != nil) {
		[self initIASKSpecifierValuesViewControllerEx];
	}
	return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

	// Background View
	UACellBackgroundView *selectedBackgroundView = [[UACellBackgroundView alloc] initWithFrame:CGRectZero];
	cell.selectedBackgroundView = selectedBackgroundView;
    [selectedBackgroundView setBackgroundColor:LINPHONE_MAIN_COLOR];//LINPHONE_TABLE_CELL_BACKGROUND_COLOR];
	return cell;
}

@end

#pragma mark - IASKAppSettingsViewControllerEx Class

@interface IASKAppSettingsViewController (PrivateInterface)
- (UITableViewCell *)newCellForIdentifier:(NSString *)identifier;
@end
;

@interface IASKAppSettingsViewControllerEx : IASKAppSettingsViewController

@end

@implementation IASKAppSettingsViewControllerEx

- (UITableViewCell *)newCellForIdentifier:(NSString *)identifier {
	UITableViewCell *cell = nil;
	if ([identifier isEqualToString:kIASKPSToggleSwitchSpecifier]) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
									  reuseIdentifier:kIASKPSToggleSwitchSpecifier];
		cell.accessoryView = [[IASKSwitchEx alloc] initWithFrame:CGRectMake(0, 0, 79, 27)];
		[((IASKSwitchEx *)cell.accessoryView)addTarget:self
												action:@selector(toggledValue:)
									  forControlEvents:UIControlEventValueChanged];
		[((IASKSwitchEx *)cell.accessoryView)setOnTintColor:LINPHONE_MAIN_COLOR];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.minimumScaleFactor = kIASKMinimumFontSize / [UIFont systemFontSize];
		cell.detailTextLabel.minimumScaleFactor = kIASKMinimumFontSize / [UIFont systemFontSize];
      //  cell.tintColor = LINPHONE_MAIN_COLOR;
	} else {
		cell = [super newCellForIdentifier:identifier];
	}
	return cell;
}

- (void)toggledValue:(id)sender {
	IASKSwitchEx *toggle = (IASKSwitchEx *)sender;
	IASKSpecifier *spec = [_settingsReader specifierForKey:[toggle key]];

	if ([toggle isOn]) {
		if ([spec trueValue] != nil) {
			[self.settingsStore setObject:[spec trueValue] forKey:[toggle key]];
		} else {
			[self.settingsStore setBool:YES forKey:[toggle key]];
		}
	} else {
		if ([spec falseValue] != nil) {
			[self.settingsStore setObject:[spec falseValue] forKey:[toggle key]];
		} else {
			[self.settingsStore setBool:NO forKey:[toggle key]];
		}
	}
	// Start notification after animation of DCRoundSwitch
	dispatch_async(dispatch_get_main_queue(), ^{
	  [[NSNotificationCenter defaultCenter]
		  postNotificationName:kIASKAppSettingChanged
						object:[toggle key]
					  userInfo:[NSDictionary dictionaryWithObject:[self.settingsStore objectForKey:[toggle key]]
														   forKey:[toggle key]]];
	});
}

- (void)initIASKAppSettingsViewControllerEx {
    [self.view setBackgroundColor:[UIColor clearColor]];

	// Force kIASKSpecifierValuesViewControllerIndex
	static int kIASKSpecifierValuesViewControllerIndex = 0;
	_viewList = [[NSMutableArray alloc] init];
	[_viewList addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"IASKSpecifierValuesView", @"ViewName", nil]];
	[_viewList addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"IASKAppSettingsView", @"ViewName", nil]];

	NSMutableDictionary *newItemDict = [NSMutableDictionary dictionaryWithCapacity:3];
	[newItemDict addEntriesFromDictionary:[_viewList objectAtIndex:kIASKSpecifierValuesViewControllerIndex]]; // copy
																											  // the
																											  // title
																											  // and
																											  // explain
																											  // strings

	IASKSpecifierValuesViewController *targetViewController = [[IASKSpecifierValuesViewControllerEx alloc] init];
	// add the new view controller to the dictionary and then to the 'viewList' array
	[newItemDict setObject:targetViewController forKey:@"viewController"];
	[_viewList replaceObjectAtIndex:kIASKSpecifierValuesViewControllerIndex withObject:newItemDict];
}

- (IASKSettingsReader *)settingsReader {
	IASKSettingsReader *r = [super settingsReader];
	NSMutableArray *dataSource = [NSMutableArray arrayWithArray:[r dataSource]];
	for (int i = 0; i < [dataSource count]; ++i) {
		NSMutableArray *specifiers = [NSMutableArray arrayWithArray:[dataSource objectAtIndex:i]];
		for (int j = 0; j < [specifiers count]; ++j) {
			id sp = [specifiers objectAtIndex:j];
			if ([sp isKindOfClass:[IASKSpecifier class]]) {
				sp = [SettingsViewController filterSpecifier:sp];
			}
			[specifiers replaceObjectAtIndex:j withObject:sp];
		}

		[dataSource replaceObjectAtIndex:i withObject:specifiers];
	}
	[r setDataSource:dataSource];
	return r;
}

- (void)viewDidLoad {
	[super viewDidLoad];

    [self.tableView setBackgroundColor:[UIColor clearColor]]; // Can't do it in Xib: issue with ios4
	[self.tableView setBackgroundView:nil];					  // Can't do it in Xib: issue with ios4
 //   [[self view] setBackgroundColor:LINPHONE_MAIN_COLOR];
}

- (id)initWithStyle:(UITableViewStyle)style {
	self = [super initWithStyle:style];
	if (self != nil) {
		[self initIASKAppSettingsViewControllerEx];
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	UIBarButtonItem *buttonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"About", nil)
																   style:UIBarButtonItemStyleBordered
																  target:self
																  action:@selector(onAboutClick:)];
	self.navigationItem.rightBarButtonItem = buttonItem;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

	if ([cell isKindOfClass:[IASKPSTextFieldSpecifierViewCell class]]) {
		UITextField *field = ((IASKPSTextFieldSpecifierViewCell *)cell).textField;
		[field setTextColor:LINPHONE_MAIN_COLOR];
	}

	if ([cell isKindOfClass:[IASKPSTitleValueSpecifierViewCell class]]) {
        cell.detailTextLabel.textColor = LINPHONE_MAIN_COLOR;//LINPHONE_MAIN_COLOR;//LINPHONE_TABLE_CELL_BACKGROUND_COLOR;
	} else {
        cell.detailTextLabel.textColor = LINPHONE_MAIN_COLOR;//LINPHONE_MAIN_COLOR;
	}

	// Background View
	UACellBackgroundView *selectedBackgroundView = [[UACellBackgroundView alloc] initWithFrame:CGRectZero];
	cell.selectedBackgroundView = selectedBackgroundView;
    [selectedBackgroundView setBackgroundColor:LINPHONE_MAIN_COLOR];//LINPHONE_TABLE_CELL_BACKGROUND_COLOR];
    //cell.tintColor=LINPHONE_MAIN_COLOR;
	return cell;
}

- (IBAction)onAboutClick:(id)sender {
	[[PhoneMainView instance] changeCurrentView:[AboutViewController compositeViewDescription] push:TRUE];
}

@end

#pragma mark - UINavigationBarEx Class

@interface UINavigationBarEx : UINavigationBar {
}
@end

@implementation UINavigationBarEx

#pragma mark - Lifecycle Functions

- (void)initUINavigationBarEx {
    [self setTintColor:LINPHONE_MAIN_COLOR];//[LINPHONE_MAIN_COLOR adjustHue:5.0f / 180.0f saturation:0.0f brightness:0.0f alpha:0.0f]];
}

- (id)init {
	self = [super init];
	if (self) {
		[self initUINavigationBarEx];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self initUINavigationBarEx];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self initUINavigationBarEx];
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	UIImage *img = [UIImage imageNamed:@"toolsbar_background.png"];
	[img drawInRect:rect];
    //self.tintColor=LINPHONE_MAIN_COLOR;
//    self.tableView.backgroundColor=LINPHONE_MAIN_COLOR;

}

@end

#pragma mark - UINavigationControllerEx Class

@interface UINavigationControllerEx : UINavigationController

@end

@implementation UINavigationControllerEx

- (id)initWithRootViewController:(UIViewController *)rootViewController {
	[UINavigationControllerEx removeBackground:rootViewController.view];
	return [self initWithRootViewController:rootViewController];
}

+ (void)removeBackground:(UIView *)view {
	// iOS7 transparent background is *really* transparent: with an alpha != 0
	// it messes up the transitions. Use non-transparent BG for iOS7
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
		[view setBackgroundColor:LINPHONE_SETTINGS_BG_IOS7];
	else
        [view setBackgroundColor:[UIColor clearColor]];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
	[UINavigationControllerEx removeBackground:viewController.view];

	[viewController view]; // Force view
	UILabel *labelTitleView = [[UILabel alloc] init];
   // labelTitleView.backgroundColor = LINPHONE_TABLE_CELL_BACKGROUND_COLOR;
    labelTitleView.textColor = LINPHONE_MAIN_COLOR;//[UIColor colorWithRed:0x41 / 255.0f green:0x48 / 255.0f blue:0x4f / 255.0f alpha:1.0];
	//labelTitleView.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.5];
	labelTitleView.font = [UIFont boldSystemFontOfSize:20];
	labelTitleView.shadowOffset = CGSizeMake(0, 1);
	labelTitleView.textAlignment = NSTextAlignmentCenter;
	labelTitleView.text = viewController.title;
	[labelTitleView sizeToFit];
	viewController.navigationItem.titleView = labelTitleView;
	[super pushViewController:viewController animated:animated];
}

- (void)setViewControllers:(NSArray *)viewControllers {
	for (UIViewController *controller in viewControllers) {
		[UINavigationControllerEx removeBackground:controller.view];
	}
	[super setViewControllers:viewControllers];
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
	for (UIViewController *controller in viewControllers) {
		[UINavigationControllerEx removeBackground:controller.view];
	}
	[super setViewControllers:viewControllers animated:animated];
}

@end

@implementation SettingsViewController

@synthesize settingsController;
@synthesize navigationController;

#pragma mark - Lifecycle Functions

- (id)init {
	return [super initWithNibName:@"SettingsViewController" bundle:[NSBundle mainBundle]];
}

- (void)dealloc {
	// Remove all observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"Settings"
																content:@"SettingsViewController"
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

#pragma mark - ViewController Functions

- (void)viewDidLoad {
	[super viewDidLoad];

	settingsStore = [[LinphoneCoreSettingsStore alloc] init];

	settingsController.showDoneButton = FALSE;
	settingsController.delegate = self;
	settingsController.showCreditsFooter = FALSE;
	settingsController.settingsStore = settingsStore;
    settingsController.view.backgroundColor =LINPHONE_MAIN_COLOR;
    [navigationController.view setBackgroundColor:LINPHONE_MAIN_COLOR];//[UIColor clearColor]];

	navigationController.view.frame = self.view.frame;
	[navigationController pushViewController:settingsController animated:FALSE];
	[self.view addSubview:navigationController.view];
   // [self.view addSubview:navigationController.view.tintColor= LINPHONE_MAIN_COLOR];
    //[self.view.backgroundColor=LINPHONE_MAIN_COLOR];
    //[self.tableView.backgroundColor=LINPHONE_MAIN_COLOR];

}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[settingsController dismiss:self];
	// Set observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kIASKAppSettingChanged object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	// Sync settings with linphone core settings
	[settingsStore transformLinphoneCoreToKeys];
	settingsController.hiddenKeys = [self findHiddenKeys];
	[settingsController.tableView reloadData];

	// Set observer
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(appSettingChanged:)
												 name:kIASKAppSettingChanged
											   object:nil];
}

#pragma mark - Event Functions

- (void)appSettingChanged:(NSNotification *)notif {
	NSMutableSet *hiddenKeys = [NSMutableSet setWithSet:[settingsController hiddenKeys]];
	NSMutableArray *keys = [NSMutableArray array];
	BOOL removeFromHiddenKeys = TRUE;
    
    // Make sure we can change the rtt settings.
    if ([@"enable_rtt" compare:notif.object] == NSOrderedSame) {
        BOOL enableRtt = [[notif.userInfo objectForKey:@"enable_rtt"] boolValue];
        [[LinphoneManager instance] lpConfigSetBool:enableRtt forKey:@"rtt"];
    } else if ([@"enable_video_preference" compare:notif.object] == NSOrderedSame) {
		removeFromHiddenKeys = [[notif.userInfo objectForKey:@"enable_video_preference"] boolValue];
		[keys addObject:@"video_menu"];
	} else if ([@"random_port_preference" compare:notif.object] == NSOrderedSame) {
		removeFromHiddenKeys = ![[notif.userInfo objectForKey:@"random_port_preference"] boolValue];
		[keys addObject:@"port_preference"];
	} else if ([@"backgroundmode_preference" compare:notif.object] == NSOrderedSame) {
		removeFromHiddenKeys = [[notif.userInfo objectForKey:@"backgroundmode_preference"] boolValue];
		[keys addObject:@"start_at_boot_preference"];
	} else if ([@"stun_preference" compare:notif.object] == NSOrderedSame) {
		NSString *stun_server = [notif.userInfo objectForKey:@"stun_preference"];
		removeFromHiddenKeys = (stun_server && ([stun_server length] > 0));
		[keys addObject:@"ice_preference"];
	} else if ([@"debugenable_preference" compare:notif.object] == NSOrderedSame) {
		BOOL debugEnabled = [[notif.userInfo objectForKey:@"debugenable_preference"] boolValue];
		removeFromHiddenKeys = debugEnabled;
		[keys addObject:@"send_logs_button"];
		[keys addObject:@"reset_logs_button"];
		[[LinphoneManager instance] setLogsEnabled:debugEnabled];
	} else if ([@"advanced_account_preference" compare:notif.object] == NSOrderedSame) {
		removeFromHiddenKeys = [[notif.userInfo objectForKey:@"advanced_account_preference"] boolValue];
		[keys addObject:@"userid_preference"];
		[keys addObject:@"proxy_preference"];
		[keys addObject:@"outbound_proxy_preference"];
		[keys addObject:@"avpf_preference"];
	} else if ([@"video_preset_preference" compare:notif.object] == NSOrderedSame) {
		NSString *video_preset = [notif.userInfo objectForKey:@"video_preset_preference"];
		removeFromHiddenKeys = [video_preset isEqualToString:@"custom"];
		[keys addObject:@"video_preferred_fps_preference"];
		[keys addObject:@"download_bandwidth_preference"];
	}
    
    else if ([@"mute_microphone_preference" compare:notif.object] == NSOrderedSame) {
        BOOL isMuted = [[notif.userInfo objectForKey:@"mute_microphone_preference"] boolValue];
        linphone_core_mute_mic([LinphoneManager getLc], isMuted);
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:isMuted forKey:@"isCallAudioMuted"];
        [defaults synchronize];

    }
    else if ([@"mute_speaker_preference" compare:notif.object] == NSOrderedSame) {
        BOOL isSpeakerEnabled = ([[notif.userInfo objectForKey:@"mute_speaker_preference"] boolValue]) ? NO : YES;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:isSpeakerEnabled forKey:@"isSpeakerEnabled"];
        [defaults synchronize];
    }

    else if([@"max_upload_preference" compare:notif.object] == NSOrderedSame){
        linphone_core_set_upload_bandwidth([LinphoneManager getLc], [[notif.userInfo objectForKey:@"max_upload_preference"] intValue]);
    }
    else if([@"max_download_preference" compare:notif.object] == NSOrderedSame){
        linphone_core_set_download_bandwidth([LinphoneManager getLc], [[notif.userInfo objectForKey:@"max_download_preference"] intValue]);
    }
    else if([@"echo_cancel_preference" compare:notif.object] == NSOrderedSame){
        BOOL isEchoCancelEnabled = ([[notif.userInfo objectForKey:@"echo_cancel_preference"] boolValue]) ? YES : NO;
        linphone_core_enable_echo_cancellation([LinphoneManager getLc], isEchoCancelEnabled);
    }


	for (NSString *key in keys) {
		if (removeFromHiddenKeys)
			[hiddenKeys removeObject:key];
		else
			[hiddenKeys addObject:key];
	}

	[settingsController setHiddenKeys:hiddenKeys animated:TRUE];
}

- (void) changeColor: (NSString*) pref
    {
        InfColorPickerController* picker = [ InfColorPickerController colorPickerViewController ];
    
        NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:pref];
        UIColor *color;
        NSString *title = ([pref isEqualToString:@"foreground_color_preference"]) ? @"Foreground Color" : @"Background Color";
        if(colorData){
            color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
        }
        else{
            color = [UIColor blueColor];
        }
        picker.sourceColor = color;

        [picker setTitle: title];
        picker.delegate = self;
        
        [ picker presentModallyOverViewController: self ];
    }
             
- (void) colorPickerControllerDidFinish: (InfColorPickerController*) picker
    {
        NSString *key = ([picker.title isEqualToString:@"Foreground Color"]) ? @"foreground_color_preference" : @"background_color_preference";
         NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:picker.resultColor];
        [[NSUserDefaults standardUserDefaults] setObject:colorData forKey:key];
        
        [ self dismissViewControllerAnimated:NO completion:nil];
    }

#pragma mark -

+ (IASKSpecifier *)filterSpecifier:(IASKSpecifier *)specifier {
	if (!linphone_core_sip_transport_supported([LinphoneManager getLc], LinphoneTransportTls)) {
		if ([[specifier key] isEqualToString:@"transport_preference"]) {
			NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[specifier specifierDict]];
			NSMutableArray *titles = [NSMutableArray arrayWithArray:[dict objectForKey:@"Titles"]];
			[titles removeObject:@"TLS"];
			[dict setObject:titles forKey:@"Titles"];
			NSMutableArray *values = [NSMutableArray arrayWithArray:[dict objectForKey:@"Values"]];
			[values removeObject:@"tls"];
			[dict setObject:values forKey:@"Values"];
			return [[IASKSpecifier alloc] initWithSpecifier:dict];
		}
	} else {
		if ([[specifier key] isEqualToString:@"media_encryption_preference"]) {
			NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[specifier specifierDict]];
			if (!linphone_core_media_encryption_supported([LinphoneManager getLc], LinphoneMediaEncryptionZRTP)) {
				NSMutableArray *titles = [NSMutableArray arrayWithArray:[dict objectForKey:@"Titles"]];
				[titles removeObject:@"ZRTP"];
				[dict setObject:titles forKey:@"Titles"];
				NSMutableArray *values = [NSMutableArray arrayWithArray:[dict objectForKey:@"Values"]];
				[values removeObject:@"ZRTP"];
				[dict setObject:values forKey:@"Values"];
			}
			if (!linphone_core_media_encryption_supported([LinphoneManager getLc], LinphoneMediaEncryptionSRTP)) {
				NSMutableArray *titles = [NSMutableArray arrayWithArray:[dict objectForKey:@"Titles"]];
				[titles removeObject:@"SRTP"];
				[dict setObject:titles forKey:@"Titles"];
				NSMutableArray *values = [NSMutableArray arrayWithArray:[dict objectForKey:@"Values"]];
				[values removeObject:@"SRTP"];
				[dict setObject:values forKey:@"Values"];
			}
			if (!linphone_core_media_encryption_supported([LinphoneManager getLc], LinphoneMediaEncryptionDTLS)) {
				NSMutableArray *titles = [NSMutableArray arrayWithArray:[dict objectForKey:@"Titles"]];
				[titles removeObject:@"DTLS"];
				[dict setObject:titles forKey:@"Titles"];
				NSMutableArray *values = [NSMutableArray arrayWithArray:[dict objectForKey:@"Values"]];
				[values removeObject:@"DTLS"];
				[dict setObject:values forKey:@"Values"];
			}
			return [[IASKSpecifier alloc] initWithSpecifier:dict];
		}
	}

	return specifier;
}

static BOOL isAdvancedSettings = FALSE;

+(void) unlockAdvancedSettings{
    isAdvancedSettings = TRUE;
}
- (NSSet *)findHiddenKeys {
	LinphoneManager *lm = [LinphoneManager instance];
	NSMutableSet *hiddenKeys = [NSMutableSet set];

	if (!linphone_core_sip_transport_supported([LinphoneManager getLc], LinphoneTransportTls)) {
		[hiddenKeys addObject:@"media_encryption_preference"];
	}

#ifndef DEBUG
	[hiddenKeys addObject:@"release_button"];
	[hiddenKeys addObject:@"clear_cache_button"];
	[hiddenKeys addObject:@"battery_alert_button"];
#endif

	if (![[LinphoneManager instance] lpConfigBoolForKey:@"debugenable_preference"]) {
		[hiddenKeys addObject:@"send_logs_button"];
		[hiddenKeys addObject:@"reset_logs_button"];
	}

	[hiddenKeys addObject:@"playback_gain_preference"];
	[hiddenKeys addObject:@"microphone_gain_preference"];

	[hiddenKeys addObject:@"network_limit_group"];

	[hiddenKeys addObject:@"incoming_call_timeout_preference"];
	[hiddenKeys addObject:@"in_call_timeout_preference"];

	//[hiddenKeys addObject:@"wifi_only_preference"];

	[hiddenKeys addObject:@"quit_button"];  // Hide for the moment
	[hiddenKeys addObject:@"about_button"]; // Hide for the moment

	if (!linphone_core_video_supported([LinphoneManager getLc]))
		[hiddenKeys addObject:@"video_menu"];

	if (![LinphoneManager isCodecSupported:"h264"]) {
		[hiddenKeys addObject:@"h264_preference"];
	}
	if (![LinphoneManager isCodecSupported:"mp4v-es"]) {
		[hiddenKeys addObject:@"mp4v-es_preference"];
	}

	if (![LinphoneManager isNotIphone3G])
		[hiddenKeys addObject:@"silk_24k_preference"];

	UIDevice *device = [UIDevice currentDevice];
	if (![device respondsToSelector:@selector(isMultitaskingSupported)] || ![device isMultitaskingSupported]) {
		[hiddenKeys addObject:@"backgroundmode_preference"];
		[hiddenKeys addObject:@"start_at_boot_preference"];
	} else {
		if (![lm lpConfigBoolForKey:@"backgroundmode_preference"]) {
			[hiddenKeys addObject:@"start_at_boot_preference"];
		}
	}

	[hiddenKeys addObject:@"enable_first_login_view_preference"];

	if (!linphone_core_video_supported([LinphoneManager getLc])) {
		[hiddenKeys addObject:@"enable_video_preference"];
	}

	if (!linphone_core_video_enabled([LinphoneManager getLc])) {
		[hiddenKeys addObject:@"video_menu"];
	}

	if (!linphone_core_get_video_preset([LinphoneManager getLc]) ||
		strcmp(linphone_core_get_video_preset([LinphoneManager getLc]), "custom") != 0) {
		[hiddenKeys addObject:@"video_preferred_fps_preference"];
		[hiddenKeys addObject:@"download_bandwidth_preference"];
	}

	[hiddenKeys addObjectsFromArray:[[SDPNegotiationService unsupportedCodecs] allObjects]];

	BOOL random_port = [lm lpConfigBoolForKey:@"random_port_preference"];
	if (random_port) {
		[hiddenKeys addObject:@"port_preference"];
	}

	if (linphone_core_get_stun_server([LinphoneManager getLc]) == NULL) {
		[hiddenKeys addObject:@"ice_preference"];
	}

	if (![lm lpConfigBoolForKey:@"debugenable_preference"]) {
		[hiddenKeys addObject:@"console_button"];
	}

	if (![LinphoneManager runningOnIpad]) {
		[hiddenKeys addObject:@"preview_preference"];
	}
	if ([lm lpConfigBoolForKey:@"hide_run_assistant_preference"]) {
		[hiddenKeys addObject:@"wizard_button"];
	}

	if (!linphone_core_tunnel_available()) {
		[hiddenKeys addObject:@"tunnel_menu"];
	}

	if (![lm lpConfigBoolForKey:@"advanced_account_preference"]) {
		[hiddenKeys addObject:@"userid_preference"];
		[hiddenKeys addObject:@"proxy_preference"];
		[hiddenKeys addObject:@"outbound_proxy_preference"];
		[hiddenKeys addObject:@"avpf_preference"];
	}

	if (![[[LinphoneManager instance] iapManager] enabled]) {
		[hiddenKeys addObject:@"in_app_products_button"];
	}

	if ([[UIDevice currentDevice].systemVersion floatValue] < 8) {
		[hiddenKeys addObject:@"repeat_call_notification_preference"];
	}
    if(!isAdvancedSettings){
        [hiddenKeys addObject:@"enable_video_preference"];
        [hiddenKeys addObject:@"avpf_preference"];
        [hiddenKeys addObject:@"outbound_proxy_preference"];
        [hiddenKeys addObject:@"domain_preference"];
        [hiddenKeys addObject:@"proxy_preference"];
        [hiddenKeys addObject:@"transport_preference"];
        [hiddenKeys addObject:@"advanced_account_preference"];
        
        [hiddenKeys addObject:@"rtt_menu"];
        [hiddenKeys addObject:@"audio_menu"];
        [hiddenKeys addObject:@"video_menu"];
        [hiddenKeys addObject:@"call_menu"];
        [hiddenKeys addObject:@"network_menu"];
        [hiddenKeys addObject:@"tunnel_menu"];
        [hiddenKeys addObject:@"advanced_menu"];

    }
	return hiddenKeys;
}

- (void)goToWizard {
	WizardViewController *controller =
		DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[WizardViewController compositeViewDescription]],
					 WizardViewController);
	if (controller != nil) {
		[controller reset];
	}
}

#pragma mark - IASKSettingsDelegate Functions

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender {
}

- (void)settingsViewController:(IASKAppSettingsViewController *)sender
	  buttonTappedForSpecifier:(IASKSpecifier *)specifier {
	NSString *key = [specifier.specifierDict objectForKey:kIASKKey];
	LinphoneCore *lc = [LinphoneManager getLc];
#ifdef DEBUG
	if ([key isEqual:@"release_button"]) {
		[UIApplication sharedApplication].keyWindow.rootViewController = nil;
		[[UIApplication sharedApplication].keyWindow setRootViewController:nil];
		[[LinphoneManager instance] destroyLinphoneCore];
		[LinphoneManager instanceRelease];
	} else if ([key isEqual:@"clear_cache_button"]) {
		[[PhoneMainView instance]
				.mainViewController clearCache:[NSArray arrayWithObject:[[PhoneMainView instance] currentView]]];
	} else if ([key isEqual:@"battery_alert_button"]) {
		[[UIDevice currentDevice] _setBatteryState:UIDeviceBatteryStateUnplugged];
		[[UIDevice currentDevice] _setBatteryLevel:0.01f];
		[[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceBatteryLevelDidChangeNotification
															object:self];
	}
#endif
	if ([key isEqual:@"wizard_button"]) {
		if (linphone_core_get_default_proxy_config(lc) == NULL) {
			[self goToWizard];
			return;
		}
		UIAlertView *alert = [[UIAlertView alloc]
				initWithTitle:NSLocalizedString(@"Warning", nil)
					  message:
						  NSLocalizedString(
							  @"Launching the Wizard will delete any existing proxy config.\nAre you sure to want it?",
							  nil)
					 delegate:self
			cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
			otherButtonTitles:NSLocalizedString(@"Launch Wizard", nil), nil];
		[alert show];
	} else if ([key isEqual:@"clear_proxy_button"]) {
		if (linphone_core_get_default_proxy_config(lc) == NULL) {
			return;
		}

		DTAlertView *alert = [[DTAlertView alloc]
			initWithTitle:NSLocalizedString(@"Warning", nil)
				  message:NSLocalizedString(@"Are you sure to want to clear your proxy setup?", nil)];

		[alert addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:nil];
		[alert addButtonWithTitle:NSLocalizedString(@"Yes", nil)
							block:^{
							  linphone_core_clear_proxy_config(lc);
							  linphone_core_clear_all_auth_info(lc);
							  [settingsStore transformLinphoneCoreToKeys];
							  [settingsController.tableView reloadData];
							}];
		[alert show];

	} else if ([key isEqual:@"about_button"]) {
		[[PhoneMainView instance] changeCurrentView:[AboutViewController compositeViewDescription] push:TRUE];
	} else if ([key isEqualToString:@"reset_logs_button"]) {
		linphone_core_reset_log_collection();
	}
    else if([key isEqualToString:@"foreground_color_preference"]){
        [self changeColor: @"foreground_color_preference"];
    }
    else if([key isEqualToString:@"background_color_preference"]){
        [self changeColor: @"background_color_preference"];
    }
    else if ([key isEqual:@"send_logs_button"]) {
		NSString *message;

		if ([LinphoneManager.instance lpConfigBoolForKey:@"send_logs_include_linphonerc_and_chathistory"]) {
			message = NSLocalizedString(
				@"Warning: an email will be created with 3 attachments:\n- Application "
				@"logs\n- Linphone configuration\n- Chats history.\nThey may contain "
				@"private informations (MIGHT contain clear-text password!).\nYou can remove one or several "
				@"of these attachments before sending your email, however there are all "
				@"important to diagnostize your issue.",
				nil);
		} else {
			message = NSLocalizedString(@"Warning: an email will be created with application " @"logs. It may contain "
										@"private informations (but no password!).\nThese logs are "
										@"important to diagnostize your issue.",
										nil);
		}

		DTAlertView *alert =
			[[DTAlertView alloc] initWithTitle:NSLocalizedString(@"Sending logs", nil) message:message];
		[alert addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:nil];
		[alert addButtonWithTitle:NSLocalizedString(@"I got it, continue", nil)
							block:^{
							  [self sendEmailWithDebugAttachments];
							}];
		[alert show];
	}
    
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != 1)
		return; /* cancel */
	else
		[self goToWizard];
}

#pragma mark - Mail composer for sending logs

- (void)sendEmailWithDebugAttachments {
	NSMutableArray *attachments = [[NSMutableArray alloc] initWithCapacity:3];

	// retrieve linphone logs if available
	char *filepath = linphone_core_compress_log_collection();
	if (filepath != NULL) {
		NSString *filename = [[NSString stringWithUTF8String:filepath] componentsSeparatedByString:@"/"].lastObject;
		NSString *mimeType = nil;
		if ([filename hasSuffix:@".txt"]) {
			mimeType = @"text/plain";
		} else if ([filename hasSuffix:@".gz"]) {
			mimeType = @"application/gzip";
		} else {
			LOGE(@"Unknown extension type: %@, not attaching logs", filename);
		}

		if (mimeType != nil) {
			[attachments addObject:@[ [NSString stringWithUTF8String:filepath], mimeType, filename ]];
		}
	}

	if ([LinphoneManager.instance lpConfigBoolForKey:@"send_logs_include_linphonerc_and_chathistory"]) {
		// retrieve linphone rc
		[attachments
			addObject:@[ [LinphoneManager documentFile:@"linphonerc"], @"text/plain", @"linphone-configuration.rc" ]];

		// retrieve historydb
		[attachments addObject:@[
			[LinphoneManager documentFile:@"linphone_chats.db"],
			@"application/x-sqlite3",
			@"linphone-chats-history.db"
		]];
	}

	[self emailAttachments:attachments];
	ms_free(filepath);
}
- (void)emailAttachments:(NSArray *)attachments {
	NSString *error = nil;
#if TARGET_IPHONE_SIMULATOR
	error = @"Cannot send emails on the Simulator. To test this feature, please use a real device.";
#else
	if ([MFMailComposeViewController canSendMail] == NO) {
		error = NSLocalizedString(
			@"Your device is not configured to send emails. Please configure mail application prior to send logs.",
			nil);
	}
#endif

	if (error != nil) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Cannot send email", nil)
														message:error
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"Continue", nil)
											  otherButtonTitles:nil];
		[alert show];
	} else {
		MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
		picker.mailComposeDelegate = self;

		[picker setSubject:@"Linphone iOS Logs"];
		[picker setToRecipients:[NSArray arrayWithObjects:@"linphone-iphone@belledonne-communications.com", nil]];
		[picker setMessageBody:@"Here are information about an issue I had on my device.\nI was "
							   @"doing ...\nI expected Linphone to ...\nInstead, I got an "
							   @"unexpected result: ..."
						isHTML:NO];
		for (NSArray *attachment in attachments) {
			if ([[NSFileManager defaultManager] fileExistsAtPath:attachment[0]]) {
				[picker addAttachmentData:[NSData dataWithContentsOfFile:attachment[0]]
								 mimeType:attachment[1]
								 fileName:attachment[2]];
			}
		}
		[self presentViewController:picker animated:true completion:nil];
	}
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError *)error {
	if (error != nil) {
		LOGW(@"Error while sending mail: %@", error);
	} else {
		LOGI(@"Mail completed with status: %d", result);
	}
	[self dismissViewControllerAnimated:true completion:nil];
}

@end
