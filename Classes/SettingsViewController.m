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
#import "SystemInfo.h"
#import "IASKSpecifierValuesViewController.h"
#import "IASKPSTextFieldSpecifierViewCell.h"
#import "IASKPSTitleValueSpecifierViewCell.h"
#import "IASKSpecifier.h"
#import "IASKTextField.h"
#include "linphone/lpconfig.h"
#import "InfColorPicker/InfColorPickerController.h"
#import "DTAlertView.h"
#import <HockeySDK/HockeySDK.h>
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

- (UITableViewCell *)tableView:(UITableView *)tableView     RowAtIndexPath:(NSIndexPath *)indexPath {
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
    [self.settingsStore synchronize];
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
    NSData *colorData = [[NSUserDefaults standardUserDefaults] objectForKey:@"background_color_preference"];
    if(colorData){
        UIColor *color = [NSKeyedUnarchiver unarchiveObjectWithData:colorData];
        self.tableView.opaque = NO;
        self.tableView.backgroundColor = [self darkerColorForColor:color];
        self.tableView.backgroundView  = nil;
    }
}

- (UIColor *)darkerColorForColor:(UIColor *)c
{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MAX(r - 0.1, 0.0)
                               green:MAX(g - 0.1, 0.0)
                                blue:MAX(b - 0.1, 0.0)
                               alpha:a];
    return nil;
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
        [[LinphoneManager instance] lpConfigSetBool:enableRtt forKey:@"enable_rtt"];
        [[NSUserDefaults standardUserDefaults] setBool:enableRtt forKey:@"enable_rtt"];
        [[LinphoneManager instance] lpConfigSetBool:enableRtt forKey:@"rtt"];
        
    }
    else if ([@"random_port_preference" compare:notif.object] == NSOrderedSame) {
		removeFromHiddenKeys = ![[notif.userInfo objectForKey:@"random_port_preference"] boolValue];
		[keys addObject:@"port_preference"];
	} else if ([@"backgroundmode_preference" compare:notif.object] == NSOrderedSame) {
		removeFromHiddenKeys = [[notif.userInfo objectForKey:@"backgroundmode_preference"] boolValue];
		[keys addObject:@"start_at_boot_preference"];
	} else if ([@"stun_preference" compare:notif.object] == NSOrderedSame) {
		NSString *stun_server = [notif.userInfo objectForKey:@"stun_preference"];
		removeFromHiddenKeys = (stun_server && ([stun_server length] > 0));
		[keys addObject:@"ice_preference"];
        if(removeFromHiddenKeys && linphone_core_get_firewall_policy([LinphoneManager getLc]) != LinphonePolicyUseStun && linphone_core_get_firewall_policy([LinphoneManager getLc]) != LinphonePolicyUseIce){
            linphone_core_set_firewall_policy([LinphoneManager getLc], LinphonePolicyUseStun);
        }
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
        linphone_core_set_video_preset([LinphoneManager getLc], "high-fps");
	}
    else if([@"ice_preference" compare:notif.object] == NSOrderedSame){
        BOOL iceEnabled = [[notif.userInfo objectForKey:@"ice_preference"] boolValue];
        LinphoneFirewallPolicy policy;
        
        /**< Use the ICE protocol */
        if(iceEnabled){ policy = LinphonePolicyUseIce; }

        /**< Use a STUN server to get the public address */
        else{ policy = LinphonePolicyUseStun; }
        
        linphone_core_set_firewall_policy([LinphoneManager getLc], policy);
    }
    else if([@"rtcp_feedback_pref" compare:notif.object] == NSOrderedSame){
		NSString *rtcpFeedbackMode = [notif.userInfo objectForKey:@"rtcp_feedback_pref"];
        
        if([rtcpFeedbackMode isEqualToString:@"Implicit"]){
            linphone_core_set_avpf_mode([LinphoneManager getLc], LinphoneAVPFDisabled);
            [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"avpf_preference"];
            LinphoneProxyConfig *defaultProxy = linphone_core_get_default_proxy_config([LinphoneManager getLc]);
            linphone_proxy_config_enable_avpf(defaultProxy, FALSE);
            lp_config_set_int([[LinphoneManager instance] configDb],  "rtp", "rtcp_fb_implicit_rtcp_fb", 1);
        }
        else if([rtcpFeedbackMode isEqualToString:@"Explicit"]){
            linphone_core_set_avpf_mode([LinphoneManager getLc], LinphoneAVPFEnabled);
            [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"avpf_preference"];
            LinphoneProxyConfig *defaultProxy = linphone_core_get_default_proxy_config([LinphoneManager getLc]);
            linphone_proxy_config_enable_avpf(defaultProxy, TRUE);
            lp_config_set_int([[LinphoneManager instance] configDb],  "rtp", "rtcp_fb_implicit_rtcp_fb", 1);
        }
        else{
            linphone_core_set_avpf_mode([LinphoneManager getLc], LinphoneAVPFDisabled);
            [[NSUserDefaults standardUserDefaults] setBool:FALSE forKey:@"avpf_preference"];
            LinphoneProxyConfig *defaultProxy = linphone_core_get_default_proxy_config([LinphoneManager getLc]);
            linphone_proxy_config_enable_avpf(defaultProxy, FALSE);
            lp_config_set_int([[LinphoneManager instance] configDb],  "rtp", "rtcp_fb_implicit_rtcp_fb", 0);
        }
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:rtcpFeedbackMode forKey:@"rtcp_feedback_pref"];
        [defaults synchronize];
    }
    else if([@"use_ipv6" compare:notif.object] == NSOrderedSame){
        BOOL use_ipv6 = [[notif.userInfo objectForKey:@"use_ipv6"] boolValue];
        linphone_core_enable_ipv6([LinphoneManager getLc], use_ipv6);
        [[LinphoneManager instance] lpConfigSetBool:use_ipv6 forKey:@"use_ipv6"];
        [[NSUserDefaults standardUserDefaults] setBool:use_ipv6 forKey:@"use_ipv6"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    else if ([@"mute_microphone_preference" compare:notif.object] == NSOrderedSame) {
        BOOL isMuted = [[notif.userInfo objectForKey:@"mute_microphone_preference"] boolValue];
        linphone_core_mute_mic([LinphoneManager getLc], isMuted);
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:isMuted forKey:@"mute_microphone_preference"];
        [defaults synchronize];

    }
    else if ([@"pref_text_settings_send_mode_key" compare:notif.object] == NSOrderedSame) {
        NSString *text_send_mode = [notif.userInfo objectForKey:@"pref_text_settings_send_mode_key"];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:text_send_mode forKey:@"pref_text_settings_send_mode_key"];
        [defaults synchronize];

    }
    else if ([@"mute_speaker_preference" compare:notif.object] == NSOrderedSame) {
        BOOL isSpeakerMuted = [[notif.userInfo objectForKey:@"mute_speaker_preference"] boolValue];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:isSpeakerMuted forKey:@"mute_speaker_preference"];
        [defaults synchronize];
    }
    else if([@"mwi_uri_preference" compare:notif.object] == NSOrderedSame){
         NSString *mwi_uri = [notif.userInfo objectForKey:@"mwi_uri_preference"];
        [[NSUserDefaults standardUserDefaults] setObject:mwi_uri forKey:@"mwi_uri_preference"];
    }
    else if([@"video_mail_uri_preference" compare:notif.object] == NSOrderedSame){
         NSString *video_mail_uri = [notif.userInfo objectForKey:@"video_mail_uri_preference"];
        [[NSUserDefaults standardUserDefaults] setObject:video_mail_uri forKey:@"video_mail_uri_preference"];
    }

    else if([@"max_upload_preference" compare:notif.object] == NSOrderedSame){
        linphone_core_set_upload_bandwidth([LinphoneManager getLc], [[notif.userInfo objectForKey:@"max_upload_preference"] intValue]);
    }
    else if([@"max_download_preference" compare:notif.object] == NSOrderedSame){
        linphone_core_set_download_bandwidth([LinphoneManager getLc], [[notif.userInfo objectForKey:@"max_download_preference"] intValue]);
    }
    else if([@"enable_auto_answer_preference" compare:notif.object] == NSOrderedSame){
        
    }
    
    else if([@"adaptive_rate_control_preference" compare:notif.object] == NSOrderedSame){
        BOOL enabled = ([[notif.userInfo objectForKey:@"adaptive_rate_control_preference"] boolValue]) ? YES : NO;
        linphone_core_enable_adaptive_rate_control([LinphoneManager getLc], enabled);
    }
    else if([@"wifi_only_preference" compare:notif.object] == NSOrderedSame){
        BOOL enabled = ([[notif.userInfo objectForKey:@"wifi_only_preference"] boolValue]) ? YES : NO;
        [[LinphoneManager instance] lpConfigSetBool:enabled forKey:@"wifi_only_preference"];
    }
    /***** VIDEO CODEC PREFS *****/
    else if([@"h264_preference" compare:notif.object] == NSOrderedSame){
        BOOL enabled = ([[notif.userInfo objectForKey:@"h264_preference"] boolValue]) ? YES : NO;
        PayloadType *pt=linphone_core_find_payload_type([LinphoneManager getLc],"H264", 90000, -1);
        if(pt != NULL){
            NSString *pref = [SDPNegotiationService getPreferenceForCodec:pt->mime_type withRate:pt->clock_rate];
            linphone_core_enable_payload_type([LinphoneManager getLc], pt, enabled);

            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:enabled forKey:pref];
            [defaults synchronize];
        }
    }
    else if([@"video_preferred_size_preference" compare:notif.object] == NSOrderedSame){
        NSString *value =  [notif.userInfo objectForKey:@"video_preferred_size_preference"];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:value forKey:@"video_preferred_size_preference"];
        [defaults synchronize];
        
        MSVideoSize vsize;
        if([value isEqualToString:@"vga"]){
            MS_VIDEO_SIZE_ASSIGN(vsize, VGA);
        }
        else if([value isEqualToString:@"cif"]){
            MS_VIDEO_SIZE_ASSIGN(vsize, CIF);
        }
        else if([value isEqualToString:@"qvga"]){
            MS_VIDEO_SIZE_ASSIGN(vsize, QVGA);
        }
        else{
            MS_VIDEO_SIZE_ASSIGN(vsize, CIF);
        }

        linphone_core_set_preferred_video_size([LinphoneManager getLc], vsize);
    }
    else if([@"h263_preference" compare:notif.object] == NSOrderedSame){
        BOOL enabled = ([[notif.userInfo objectForKey:@"h263_preference"] boolValue]) ? YES : NO;
        PayloadType *pt=linphone_core_find_payload_type([LinphoneManager getLc],"H263", 90000, -1);
        if(pt != NULL){
            NSString *pref = [SDPNegotiationService getPreferenceForCodec:pt->mime_type withRate:pt->clock_rate];
            linphone_core_enable_payload_type([LinphoneManager getLc], pt, enabled);

            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:enabled forKey:pref];
            [defaults synchronize];
        }
    }
    else if([@"vp8_preference" compare:notif.object] == NSOrderedSame){
        BOOL enabled = ([[notif.userInfo objectForKey:@"vp8_preference"] boolValue]) ? YES : NO;
        PayloadType *pt=linphone_core_find_payload_type([LinphoneManager getLc],"VP8", 90000, -1);
        if(pt != NULL){
            NSString *pref = [SDPNegotiationService getPreferenceForCodec:pt->mime_type withRate:pt->clock_rate];
            linphone_core_enable_payload_type([LinphoneManager getLc], pt, enabled);

            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:enabled forKey:pref];
            [defaults synchronize];
        }
    }
    else if([@"mp4v-es_preference" compare:notif.object] == NSOrderedSame){
        BOOL enabled = ([[notif.userInfo objectForKey:@"mp4v-es_preference"] boolValue]) ? YES : NO;
        PayloadType *pt=linphone_core_find_payload_type([LinphoneManager getLc],"MP4V-ES", 90000, -1);
        if(pt != NULL){
            NSString *pref = [SDPNegotiationService getPreferenceForCodec:pt->mime_type withRate:pt->clock_rate];
            linphone_core_enable_payload_type([LinphoneManager getLc], pt, enabled);


            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:enabled forKey:pref];
            [defaults synchronize];
        }
    }
    /******** AUDIO CODEC PREFS *******/
    else if([@"speex_16k_preference" compare:notif.object] == NSOrderedSame){
        BOOL enabled = ([[notif.userInfo objectForKey:@"speex_16k_preference"] boolValue]) ? YES : NO;
        PayloadType *pt = [[LinphoneManager instance] findCodec:@"speex_16k_preference"];
        if (pt) {
            NSString *pref = [SDPNegotiationService getPreferenceForCodec:pt->mime_type withRate:pt->clock_rate];
            linphone_core_enable_payload_type([LinphoneManager getLc], pt, enabled);
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:enabled forKey:pref];
            [defaults synchronize];
        }
    }
    
    else if([@"speex_8k_preference" compare:notif.object] == NSOrderedSame){
        BOOL enabled = ([[notif.userInfo objectForKey:@"speex_8k_preference"] boolValue]) ? YES : NO;
        PayloadType *pt = [[LinphoneManager instance] findCodec:@"speex_8k_preference"];
        if (pt) {
            NSString *pref = [SDPNegotiationService getPreferenceForCodec:pt->mime_type withRate:pt->clock_rate];
            linphone_core_enable_payload_type([LinphoneManager getLc], pt, enabled);
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:enabled forKey:pref];
            [defaults synchronize];
        }
    }
    else if([@"g722_preference" compare:notif.object] == NSOrderedSame){
        BOOL enabled = ([[notif.userInfo objectForKey:@"g722_preference"] boolValue]) ? YES : NO;
        PayloadType *pt = [[LinphoneManager instance] findCodec:@"g722_preference"];
        if (pt) {
            NSString *pref = [SDPNegotiationService getPreferenceForCodec:pt->mime_type withRate:pt->clock_rate];
            linphone_core_enable_payload_type([LinphoneManager getLc], pt, enabled);
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:enabled forKey:pref];
            [defaults synchronize];
        }
    }
    else if([@"pcmu_preference" compare:notif.object] == NSOrderedSame){
        BOOL enabled = ([[notif.userInfo objectForKey:@"pcmu_preference"] boolValue]) ? YES : NO;
        PayloadType *pt = [[LinphoneManager instance] findCodec:@"pcmu_preference"];
        if (pt) {
            NSString *pref = [SDPNegotiationService getPreferenceForCodec:pt->mime_type withRate:pt->clock_rate];
            linphone_core_enable_payload_type([LinphoneManager getLc], pt, enabled);
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:enabled forKey:pref];
            [defaults synchronize];
        }
    }
    else if([@"pcma_preference" compare:notif.object] == NSOrderedSame){
        BOOL enabled = ([[notif.userInfo objectForKey:@"pcma_preference"] boolValue]) ? YES : NO;
        PayloadType *pt = [[LinphoneManager instance] findCodec:@"pcma_preference"];
        if (pt) {
            NSString *pref = [SDPNegotiationService getPreferenceForCodec:pt->mime_type withRate:pt->clock_rate];
            linphone_core_enable_payload_type([LinphoneManager getLc], pt, enabled);
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:enabled forKey:pref];
            [defaults synchronize];
        }
    }
    else if([@"signaling_preference" compare:notif.object] == NSOrderedSame) {
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"QoS"] boolValue]) {
            [self refreshTable];
        } else {
            int signalValue = [[notif.userInfo objectForKey:@"signaling_preference"] intValue];
            linphone_core_set_sip_dscp([LinphoneManager getLc], signalValue);
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setInteger:signalValue forKey:@"signaling_preference"];
            [defaults synchronize];
        }
    }
    else if([@"audio_preference" compare:notif.object] == NSOrderedSame) {
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"QoS"] boolValue]) {
            [self refreshTable];
        } else {
            int audioValue = [[notif.userInfo objectForKey:@"audio_preference"] intValue];
            linphone_core_set_audio_dscp([LinphoneManager getLc], audioValue);
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setInteger:audioValue forKey:@"audio_preference"];
            [defaults synchronize];
            if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"QoS"] boolValue]) {
                [settingsStore setBool:1 forKey:@"echo_cancel_preference"];
                [self refreshTable];
            }
        }
    }
    else if([@"video_preference" compare:notif.object] == NSOrderedSame) {
        if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"QoS"] boolValue]) {
            [self refreshTable];
        } else {
            int videoValue = [[notif.userInfo objectForKey:@"video_preference"] intValue];
            linphone_core_set_video_dscp([LinphoneManager getLc], videoValue);
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setInteger:videoValue forKey:@"video_preference"];
            [defaults synchronize];
            if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"QoS"] boolValue]) {
                [settingsStore setBool:1 forKey:@"echo_cancel_preference"];
                [self refreshTable];
            }
        }
    }
    else if([@"echo_cancel_preference" compare:notif.object] == NSOrderedSame){
        BOOL isEchoCancelEnabled = ([[notif.userInfo objectForKey:@"echo_cancel_preference"] boolValue]) ? YES : NO;
        linphone_core_enable_echo_cancellation([LinphoneManager getLc], isEchoCancelEnabled);
    } else if([@"QoS" compare:notif.object] == NSOrderedSame) {
        BOOL enabled = ([[notif.userInfo objectForKey:@"QoS"] boolValue]) ? YES : NO;
        if (enabled) {
            int signalValue = 24;
            int audioValue = 46;
            int videoValue = 46;
            if ([[NSUserDefaults standardUserDefaults] objectForKey:@"signaling_preference"] ||
                [[NSUserDefaults standardUserDefaults] objectForKey:@"audio_preference"] ||
                [[NSUserDefaults standardUserDefaults] objectForKey:@"video_preference"]) {
                signalValue = [[[NSUserDefaults standardUserDefaults] objectForKey:@"signaling_preference"] intValue];
                audioValue = [[[NSUserDefaults standardUserDefaults] objectForKey:@"audio_preference"] intValue];
                videoValue = [[[NSUserDefaults standardUserDefaults] objectForKey:@"video_preference"] intValue];
            }
            linphone_core_set_sip_dscp([LinphoneManager getLc], signalValue);
            linphone_core_set_audio_dscp([LinphoneManager getLc], audioValue);
            linphone_core_set_video_dscp([LinphoneManager getLc], videoValue);
            [settingsStore setInteger:signalValue forKey:@"signaling_preference"];
            [settingsStore setInteger:audioValue forKey:@"audio_preference"];
            [settingsStore setInteger:videoValue forKey:@"video_preference"];
        } else {
            // Default values
            linphone_core_set_sip_dscp([LinphoneManager getLc], 0);
            linphone_core_set_audio_dscp([LinphoneManager getLc], 0);
            linphone_core_set_video_dscp([LinphoneManager getLc], 0);
            [settingsStore setObject:@"0" forKey:@"signaling_preference"];
            [settingsStore setObject:@"0" forKey:@"audio_preference"];
            [settingsStore setObject:@"0" forKey:@"video_preference"];
        }
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:enabled forKey:@"QoS"];
        [defaults synchronize];
        [self refreshTable];
    }
    else if([@"force_508_preference" compare:notif.object] == NSOrderedSame){
        BOOL is508Enabled = ([[notif.userInfo objectForKey:@"force_508_preference"] boolValue]) ? YES : NO;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:is508Enabled forKey:@"force508"];
        [defaults synchronize];
        
        [settingsStore transformLinphoneCoreToKeys];
        settingsController.hiddenKeys = [self findHiddenKeys];
        [settingsController.tableView reloadData];
    }

	for (NSString *key in keys) {
		if (removeFromHiddenKeys)
			[hiddenKeys removeObject:key];
		else
			[hiddenKeys addObject:key];
	}

	[settingsController setHiddenKeys:hiddenKeys animated:TRUE];
}

- (void)refreshTable {
    [settingsStore transformLinphoneCoreToKeys];
    settingsController.hiddenKeys = [self findHiddenKeys];
    [settingsController.tableView reloadData];
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

- (UIColor *)darkerColorForColor:(UIColor *)c
{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MAX(r - 0.1, 0.0)
                               green:MAX(g - 0.1, 0.0)
                                blue:MAX(b - 0.1, 0.0)
                               alpha:a];
    return nil;
}
             
- (void) colorPickerControllerDidFinish: (InfColorPickerController*) picker
    {
        NSString *key = ([picker.title isEqualToString:@"Foreground Color"]) ? @"foreground_color_preference" : @"background_color_preference";
         NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:picker.resultColor];
        [[NSUserDefaults standardUserDefaults] setObject:colorData forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        if ([key isEqualToString:@"background_color_preference"]) {
            [[NSUserDefaults standardUserDefaults] setObject:colorData forKey:@"main_bar_background_color_preference"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"backgroundColorChanged" object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"foregroundColorChanged" object:nil];
        }
        
        settingsController.tableView.opaque = NO;
        UIColor *color = [self darkerColorForColor:picker.resultColor];
        settingsController.tableView.backgroundColor = color;
        settingsController.tableView.backgroundView  = nil;
        
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
/*** Commented out for GA ***/
//#ifndef DEBUG
//	[hiddenKeys addObject:@"release_button"];
//	[hiddenKeys addObject:@"clear_cache_button"];
//	[hiddenKeys addObject:@"battery_alert_button"];
//#endif

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

//	if (![LinphoneManager runningOnIpad]) {
//		[hiddenKeys addObject:@"preview_preference"];
//	}
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
        [hiddenKeys addObject:@"avpf_preference"];
        [hiddenKeys addObject:@"outbound_proxy_preference"];
        [hiddenKeys addObject:@"password_preference"];
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
/***** Dangerous settings, commented for GA *****/
//	if ([key isEqual:@"release_button"]) {
//		[UIApplication sharedApplication].keyWindow.rootViewController = nil;
//		[[UIApplication sharedApplication].keyWindow setRootViewController:nil];
//		[[LinphoneManager instance] destroyLinphoneCore];
//		[LinphoneManager instanceRelease];
//	} else if ([key isEqual:@"clear_cache_button"]) {
//		[[PhoneMainView instance]
//				.mainViewController clearCache:[NSArray arrayWithObject:[[PhoneMainView instance] currentView]]];
//	} else if ([key isEqual:@"battery_alert_button"]) {
//		[[UIDevice currentDevice] _setBatteryState:UIDeviceBatteryStateUnplugged];
//		[[UIDevice currentDevice] _setBatteryLevel:0.01f];
//		[[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceBatteryLevelDidChangeNotification
//															object:self];
//	}
#endif
	if ([key isEqual:@"wizard_button"]) {
		if (linphone_core_get_default_proxy_config(lc) == NULL) {
			[self goToWizard];
			return;
		}
		DTAlertView *alert = [[DTAlertView alloc]
                    initWithTitle:NSLocalizedString(@"Warning", nil)
					  message:NSLocalizedString(@"Launching the Wizard will delete any existing proxy config.\nAre you sure to want to logout?",nil)];
        [alert addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:nil];
        [alert addButtonWithTitle:NSLocalizedString(@"Launch Wizard", nil)
                            block:^{
                                linphone_core_clear_proxy_config(lc);
                                linphone_core_clear_all_auth_info(lc);
                                [self goToWizard];
                            }];
        [alert setDelegate:self];
        
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
                              NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
                              [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
							  linphone_core_clear_proxy_config(lc);
							  linphone_core_clear_all_auth_info(lc);
							  [settingsStore transformLinphoneCoreToKeys];
							  [settingsController.tableView reloadData];
							}];
		[alert show];

	} else if ([key isEqual:@"about_button"]) {
		[[PhoneMainView instance] changeCurrentView:[AboutViewController compositeViewDescription] push:TRUE];
	}
    else if([key isEqualToString:@"view_tss_button"]){
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Technical Support Sheet",nil)
                                                                       message:[SystemInfo formatedSystemInformation]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert.view setBackgroundColor:[UIColor blackColor]];
        [alert setModalPresentationStyle:UIModalPresentationPopover];
        
        UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
        popPresenter.sourceView = self.view;
        popPresenter.sourceRect = self.view.bounds;
        UIAlertAction* confirm = [UIAlertAction actionWithTitle:NSLocalizedString(@"Confirm", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * action) {
                                                            
                                                        }];
        [alert addAction:confirm];
        [self presentViewController:alert animated:YES completion:nil];

    }
    else if([key isEqualToString:@"send_tss_button"]){
        NSMutableArray *TSS = [[NSMutableArray alloc] init];
        [TSS addObject:@"\n\nTechnical support sheet:\n"];
        [TSS addObject:[SystemInfo formatedSystemInformation]];
        [[BITHockeyManager sharedHockeyManager].feedbackManager showFeedbackComposeViewWithPreparedItems:TSS];
    }
    else if ([key isEqualToString:@"reset_logs_button"]) {
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
		}
        
        else {
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
    
    if ([key isEqual:@"reset_all_settings"]) {
        DTAlertView *alert =
        [[DTAlertView alloc] initWithTitle:@"Warning" message:NSLocalizedString(@"Are you sure you want to reset all settings to default?", nil)];
        [alert addCancelButtonWithTitle:NSLocalizedString(@"No", nil) block:nil];
        [alert addButtonWithTitle:NSLocalizedString(@"Yes", nil) block:^{
                                                                            [self factoryReset];
                                                                        }];
        [alert show];
    }
}

-(void) resetMediaSettings{
    if([LinphoneManager getLc]){
        //Default to no media encryption
        linphone_core_set_media_encryption([LinphoneManager getLc], LinphoneMediaEncryptionNone);
    }
}

- (void)factoryReset {
    [self resetTheme];
    [self clearUserDefaults];
    [self deleteStorageFiles];
    [self clearCacheData];
    [self resetMediaSettings];
    [self goToWizard];
}

- (void)resetTheme {
    NSData *colorDataWhite = [NSKeyedArchiver archivedDataWithRootObject:[UIColor whiteColor]];
    NSData *colorDataMainBarColor = [NSKeyedArchiver archivedDataWithRootObject: [UIColor colorWithRed:85/255. green:85/255. blue:85/255. alpha:1.0]];
    [[NSUserDefaults standardUserDefaults] setObject:colorDataWhite forKey:@"background_color_preference"];
    [[NSUserDefaults standardUserDefaults] setObject:colorDataMainBarColor forKey:@"main_bar_background_color_preference"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"backgroundColorChanged" object:nil];
    
    NSData *colorData = [NSKeyedArchiver archivedDataWithRootObject:[UIColor whiteColor]];
    [[NSUserDefaults standardUserDefaults] setObject:colorData forKey:@"foreground_color_preference"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"foregroundColorChanged" object:nil];
    
    //tableview header views' background colors
    settingsController.tableView.opaque = YES;
    settingsController.tableView.backgroundColor = LINPHONE_SETTINGS_BG_IOS7;
    settingsController.tableView.backgroundView.backgroundColor = [UIColor whiteColor];
}

- (void)clearUserDefaults {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
}

- (void)deleteStorageFiles {
    [self removeFileFromDocumentFolder:@"linphonerc"];
    [self removeFileFromDocumentFolder:@"linphone_chats.db"];
}

- (void)clearCacheData {
    [[PhoneMainView instance].mainViewController clearCache:[NSArray arrayWithObject:[[PhoneMainView instance] currentView]]];
}

- (BOOL)removeFileFromDocumentFolder:(NSString *)fileName {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:fileName];
    NSError *error;
    BOOL success = [fileManager removeItemAtPath:filePath error:&error];
    if (!success) {
        NSLog(@"Could not delete file -:%@ ",[error localizedDescription]);
        return NO;
    }
    
    return YES;
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != 1)
		return; /* cancel */
    else {
        [self goToWizard];
    }
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
