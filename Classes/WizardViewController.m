
/* WizardViewController.m
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
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "WizardViewController.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "UITextField+DoneButton.h"
#import "DTAlertView.h"
#import <XMLRPCConnection.h>
#import <XMLRPCConnectionManager.h>
#import <XMLRPCResponse.h>
#import <XMLRPCRequest.h>


#define DATEPICKER_HEIGHT 230
#define DEFAULT_ERROR_DATA_MESSAGE @"Improper registration data."

typedef enum _ViewElement {
	ViewElement_Username = 100,
	ViewElement_Password = 101,
	ViewElement_Password2 = 102,
	ViewElement_Email = 103,
	ViewElement_Domain = 104,
	ViewElement_Label = 200,
	ViewElement_Error = 201,
	ViewElement_Username_Error = 404
} ViewElement;

@implementation WizardViewController
{
    UIImageView *providerButtonLeftImageView;
    UIImageView *providerButtonRightImageView;
    BOOL acceptButtonClicked;
    UIAlertView *registrationError;
}
@synthesize contentView;
@synthesize welcomeView;
@synthesize choiceView;
@synthesize createAccountView;
@synthesize connectAccountView;
@synthesize externalAccountView;
@synthesize validateAccountView;
@synthesize provisionedAccountView;
@synthesize serviceSelectionView;
@synthesize loginView;
@synthesize waitView;
@synthesize backButton;
@synthesize startButton;
@synthesize createAccountButton;
@synthesize connectAccountButton;
@synthesize externalAccountButton;
@synthesize remoteProvisioningButton;
@synthesize provisionedDomain, provisionedPassword, provisionedUsername;
@synthesize choiceViewLogoImageView;
@synthesize viewTapGestureRecognizer;
@synthesize scrollView;

static NSMutableArray *cdnResources;
#pragma mark - Lifecycle Functions
- (id)init {
	self = [super initWithNibName:@"WizardViewController" bundle:[NSBundle mainBundle]];
	if (self != nil) {
		[[NSBundle mainBundle] loadNibNamed:@"WizardViews" owner:self options:nil];
		self->historyViews = [[NSMutableArray alloc] init];
		self->currentView = nil;
		self->viewTapGestureRecognizer =
			[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onViewTap:)];
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"Wizard"
																content:@"WizardViewController"
															   stateBar:nil
														stateBarEnabled:false
																 tabBar:nil
														  tabBarEnabled:false
															 fullscreen:false
														  landscapeMode:[LinphoneManager runningOnIpad]
														   portraitMode:true];
		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}


#pragma mark - ViewController Functions
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationUpdateEvent:)
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(configuringUpdate:)
                                                 name:kLinphoneConfiguringStateUpdate
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    [self showAcceptanceScreen];
    [self loadProviderDomainsFromCache];
    self.asyncProviderLookupOperation = [[AsyncProviderLookupOperation alloc] init];
    //Set delegate to self in order to retreive result
    self.asyncProviderLookupOperation.delegate = self;
    [self.asyncProviderLookupOperation reloadProviderDomains];
    
    [self.scrollView setContentSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height + self.buttonLogin.frame.size.height * 2)];
}

-(void)setProviderImageAndDomainByProviderAtIndex:(int)index{
    if(cdnResources && cdnResources.count > 0 && cdnResources.count > index) {
        NSString *domain;
        if([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:[NSString stringWithFormat:@"provider%d_domain", index]]){
            domain = [[NSUserDefaults standardUserDefaults] stringForKey:[NSString stringWithFormat:@"provider%d_domain", index]];
            self.textFieldDomain.text = (domain != nil)?domain:@"";
            [self.selectProviderButton setTitle:[cdnResources objectAtIndex:index] forState:UIControlStateNormal];
            
            UIImage *image = [self fetchProviderImageWithDomain:[cdnResources objectAtIndex:index]];
            if(image){
                [providerButtonLeftImageView removeFromSuperview];
                providerButtonLeftImageView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 9, 25, 25)];
                [providerButtonLeftImageView setContentMode:UIViewContentModeCenter];
                [providerButtonLeftImageView setImage:image];
                providerButtonLeftImageView.contentMode = UIViewContentModeScaleAspectFit;
                [self.selectProviderButton addSubview:providerButtonLeftImageView];
            }
            [[NSUserDefaults standardUserDefaults] setInteger:index forKey:(NSString*)LOGIN_INDEX_KEY];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (void)loadProviderDomainsFromCache {
    NSString *name;
    if(!cdnResources){
        cdnResources = [[NSMutableArray alloc] init];
        name = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"provider%d", 0]];
        for (int i = 1; name; i++) {
            [cdnResources addObject:name];
            name = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"provider%d", i]];
        }
    }
    
    NSInteger cachedSelection = [[NSUserDefaults standardUserDefaults] integerForKey:(NSString*)LOGIN_INDEX_KEY];
    if(cdnResources.count > 0) {
        if(cachedSelection >= cdnResources.count) { cachedSelection = 0; }
        [self setProviderImageAndDomainByProviderAtIndex:[NSNumber numberWithInteger:cachedSelection].intValue];
    }
}

+ (NSMutableArray *)getProvidersFromCDN {
    return cdnResources;
}

- (void)viewDidLoad {

    [super viewDidLoad];
    
    [DefaultSettingsManager sharedInstance].delegate = self;
    acceptButtonClicked = NO;
    [self.buttonVideoRelayService.layer setBorderColor:[UIColor whiteColor].CGColor];
    [self.buttonVideoRelayService.layer setBorderWidth:1.0];
    [self.buttonVideoRelayService.layer setCornerRadius:5];
    [self.buttonIPRelay.layer setBorderColor:[UIColor whiteColor].CGColor];
    [self.buttonIPRelay.layer setBorderWidth:1.0];
    [self.buttonIPRelay.layer setCornerRadius:5];
    [self.buttonIPCTS.layer setBorderColor:[UIColor whiteColor].CGColor];
    [self.buttonIPCTS.layer setBorderWidth:1.0];
    [self.buttonIPCTS.layer setCornerRadius:5];
    [self.buttonLogin.layer setBorderColor:[UIColor whiteColor].CGColor];
    [self.buttonLogin.layer setBorderWidth:1.0];
    [self.buttonLogin.layer setCornerRadius:5];
    [self.selectProviderButton.layer setBorderColor:[UIColor whiteColor].CGColor];
    [self.selectProviderButton.layer setBorderWidth:1.0];
    [self.selectProviderButton.layer setCornerRadius:5];
    [self.viewUsernameBG.layer setBorderColor:[UIColor whiteColor].CGColor];
    [self.viewUsernameBG.layer setBorderWidth:1.0];
    [self.viewUsernameBG.layer setCornerRadius:5];
    [self.viewPasswordBG.layer setBorderColor:[UIColor whiteColor].CGColor];
    [self.viewPasswordBG.layer setBorderWidth:1.0];
    [self.viewPasswordBG.layer setCornerRadius:5];
    // advanced text fields
    [self.textFieldDomain.layer setBorderColor:[UIColor whiteColor].CGColor ];
    [self.textFieldDomain.layer setBorderWidth:1.0];
    [self.textFieldDomain.layer setCornerRadius:5];
    [self.textFieldPort.layer setBorderColor:[UIColor whiteColor].CGColor ];
    [self.textFieldPort.layer setBorderWidth:1.0];
    [self.textFieldPort.layer setCornerRadius:5];
    self.textFieldPort.text = @"25060";
    [self.transportTextField.layer setBorderColor:[UIColor whiteColor].CGColor ];
    [self.transportTextField.layer setBorderWidth:1.0];
    [self.transportTextField.layer setCornerRadius:5];
    self.transportTextField.text = @"TCP";
    [self.textFieldUserId.layer setBorderColor:[UIColor whiteColor].CGColor ];
    [self.textFieldUserId.layer setBorderWidth:1.0];
    [self.textFieldUserId.layer setCornerRadius:5];
    
    [viewTapGestureRecognizer setCancelsTouchesInView:FALSE];
    [viewTapGestureRecognizer setDelegate:self];
    [contentView addGestureRecognizer:viewTapGestureRecognizer];

    if([LinphoneManager runningOnIpad]) {
        [LinphoneUtils adjustFontSize:welcomeView mult:2.22f];
        [LinphoneUtils adjustFontSize:choiceView mult:2.22f];
        [LinphoneUtils adjustFontSize:createAccountView mult:2.22f];
        [LinphoneUtils adjustFontSize:connectAccountView mult:2.22f];
        [LinphoneUtils adjustFontSize:externalAccountView mult:2.22f];
        [LinphoneUtils adjustFontSize:validateAccountView mult:2.22f];
        [LinphoneUtils adjustFontSize:provisionedAccountView mult:2.22f];
    }

	BOOL usePhoneNumber = [[LinphoneManager instance] lpConfigBoolForKey:@"use_phone_number"];
	for (UILinphoneTextField *text in
		 [NSArray arrayWithObjects:provisionedUsername, _createAccountUsername, _connectAccountUsername,
								   _externalAccountUsername, nil]) {
		if (usePhoneNumber) {
			text.keyboardType = UIKeyboardTypePhonePad;
			text.placeholder = NSLocalizedString(@"Phone number", nil);
			[text addDoneButton];
		} else {
			text.keyboardType = UIKeyboardTypeDefault;
			text.placeholder = NSLocalizedString(@"Username", nil);
		}
	}
}


#pragma mark - DefaultSettingsManager delegate method
- (void)didFinishLoadingConfigData {
    [self initLoginSettingsFields];
    [self apiSignIn];
}

- (void)didFinishWithError {
    @try{
        //Try signing in even though rue config not found via SRV
        [self apiSignIn];
    }
    @catch(NSException *e){
        NSLog(@"%@", [e description]);
    }
}

- (void)initLoginSettingsFields {
    self.textFieldDomain.text = [[DefaultSettingsManager sharedInstance].sipRegisterDomain stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    self.transportTextField.text = [[[DefaultSettingsManager sharedInstance].sipRegisterTransport uppercaseString] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    self.textFieldPort.text = [NSString stringWithFormat:@"%d", [DefaultSettingsManager sharedInstance].sipRegisterPort];
    self.textFieldUserId.text = [[DefaultSettingsManager sharedInstance].sipAuthUsername stringByReplacingOccurrencesOfString:@"\"" withString:@""];
}


#pragma mark -
+ (void)cleanTextField:(UIView *)view {
	if ([view isKindOfClass:[UITextField class]]) {
		[(UITextField *)view setText:@""];
	} else {
		for (UIView *subview in view.subviews) {
			[WizardViewController cleanTextField:subview];
		}
	}
}

- (void)fillDefaultValues {

	LinphoneCore *lc = [LinphoneManager getLc];
	[self resetTextFields];

	LinphoneProxyConfig *current_conf = NULL;
	linphone_core_get_default_proxy([LinphoneManager getLc], &current_conf);
	if (current_conf != NULL) {
		const char *proxy_addr = linphone_proxy_config_get_identity(current_conf);
		if (proxy_addr) {
			LinphoneAddress *addr = linphone_address_new(proxy_addr);
			if (addr) {
				const LinphoneAuthInfo *auth = linphone_core_find_auth_info(
					lc, NULL, linphone_address_get_username(addr), linphone_proxy_config_get_domain(current_conf));
				linphone_address_destroy(addr);
				if (auth) {
					LOGI(@"A proxy config was set up with the remote provisioning, skip wizard");
					[self onCancelClick:nil];
				}
			}
		}
	}

	LinphoneProxyConfig *default_conf = linphone_core_create_proxy_config([LinphoneManager getLc]);
	const char *identity = linphone_proxy_config_get_identity(default_conf);
	if (identity) {
		LinphoneAddress *default_addr = linphone_address_new(identity);
		if (default_addr) {
			const char *domain = linphone_address_get_domain(default_addr);
			const char *username = linphone_address_get_username(default_addr);
			if (domain && strlen(domain) > 0) {
				// UITextField* domainfield = [WizardViewController findTextField:ViewElement_Domain
				// view:externalAccountView];
				[provisionedDomain setText:[NSString stringWithUTF8String:domain]];
			}

			if (username && strlen(username) > 0 && username[0] != '?') {
				// UITextField* userField = [WizardViewController findTextField:ViewElement_Username
				// view:externalAccountView];
				[provisionedUsername setText:[NSString stringWithUTF8String:username]];
			}
		}
	}

	[self changeView:provisionedAccountView back:FALSE animation:TRUE];

	linphone_proxy_config_destroy(default_conf);
}

- (void)resetTextFields {
	[WizardViewController cleanTextField:welcomeView];
	[WizardViewController cleanTextField:choiceView];
	[WizardViewController cleanTextField:createAccountView];
	[WizardViewController cleanTextField:connectAccountView];
	[WizardViewController cleanTextField:externalAccountView];
	[WizardViewController cleanTextField:validateAccountView];
	[WizardViewController cleanTextField:provisionedAccountView];
}

- (void)reset {
	[[LinphoneManager instance] removeAllAccounts];
	[[LinphoneManager instance] lpConfigSetBool:FALSE forKey:@"pushnotification_preference"];

	LinphoneCore *lc = [LinphoneManager getLc];
	//LCSipTransports transportValue = {25060, 25060, -1, -1};

	//if (linphone_core_set_sip_transports(lc, &transportValue)) {
	//	LOGE(@"cannot set transport");
	//}

	[[LinphoneManager instance] lpConfigSetBool:FALSE forKey:@"ice_preference"];
	[[LinphoneManager instance] lpConfigSetString:@"" forKey:@"stun_preference"];
	linphone_core_set_stun_server(lc, NULL);
	linphone_core_set_firewall_policy(lc, LinphonePolicyNoFirewall);
	[self resetTextFields];
	if ([[LinphoneManager instance] lpConfigBoolForKey:@"hide_wizard_welcome_view_preference"] == true) {
		[self changeView:choiceView back:FALSE animation:FALSE];
	} else {
        // Temporary removed Service selection View
        //[self changeView:serviceSelectionView back:FALSE animation:FALSE];
		[self changeView:loginView back:TRUE animation:FALSE];
	}
	[waitView setHidden:TRUE];
}

+ (UIView *)findView:(ViewElement)tag view:(UIView *)view {
	for (UIView *child in [view subviews]) {
		if ([child tag] == tag) {
			return (UITextField *)child;
		} else {
			UIView *o = [WizardViewController findView:tag view:child];
			if (o)
				return o;
		}
	}
	return nil;
}

+ (UITextField *)findTextField:(ViewElement)tag view:(UIView *)view {
	UIView *aview = [WizardViewController findView:tag view:view];
	if ([aview isKindOfClass:[UITextField class]])
		return (UITextField *)aview;
	return nil;
}

+ (UILabel *)findLabel:(ViewElement)tag view:(UIView *)view {
	UIView *aview = [WizardViewController findView:tag view:view];
	if ([aview isKindOfClass:[UILabel class]])
		return (UILabel *)aview;
	return nil;
}

- (void)clearHistory {
	[historyViews removeAllObjects];
}

- (void)changeView:(UIView *)view back:(BOOL)back animation:(BOOL)animation {

	static BOOL placement_done = NO; // indicates if the button placement has been done in the wizard choice view

	// Change toolbar buttons following view
	if (view == welcomeView) {
		[startButton setHidden:false];
		[backButton setHidden:true];
	} else {
		[startButton setHidden:true];
		[backButton setHidden:false];
	}

	if (view == validateAccountView) {
		[backButton setEnabled:FALSE];
	} else if (view == choiceView) {
		if ([[LinphoneManager instance] lpConfigBoolForKey:@"hide_wizard_welcome_view_preference"] == true) {
			[backButton setEnabled:FALSE];
		} else {
			[backButton setEnabled:TRUE];
		}
	} else {
		[backButton setEnabled:TRUE];
	}

	if (view == choiceView) {
		// layout is this:
		// [ Logo         ]
		// [ Create Btn   ]
		// [ Connect Btn  ]
		// [ External Btn ]
		// [ Remote Prov  ]

		BOOL show_logo = [[LinphoneManager instance] lpConfigBoolForKey:@"show_wizard_logo_in_choice_view_preference"];
		BOOL show_extern = ![[LinphoneManager instance] lpConfigBoolForKey:@"hide_wizard_custom_account"];
		BOOL show_new = ![[LinphoneManager instance] lpConfigBoolForKey:@"hide_wizard_create_account"];

		if (!placement_done) {
			// visibility
			choiceViewLogoImageView.hidden = !show_logo;
			externalAccountButton.hidden = !show_extern;
			createAccountButton.hidden = !show_new;

			// placement
			if (show_logo && show_new && !show_extern) {
				// lower both remaining buttons
				[createAccountButton setCenter:[connectAccountButton center]];
				[connectAccountButton setCenter:[externalAccountButton center]];

			} else if (!show_logo && !show_new && show_extern) {
				// move up the extern button
				[externalAccountButton setCenter:[createAccountButton center]];
			}
			placement_done = YES;
		}
		if (!show_extern && !show_logo) {
			// no option to create or specify a custom account: go to connect view directly
			view = connectAccountView;
		}
	}

	// Animation
	if (animation && [[LinphoneManager instance] lpConfigBoolForKey:@"animations_preference"] == true) {
		CATransition *trans = [CATransition animation];
		[trans setType:kCATransitionPush];
		[trans setDuration:0.35];
		[trans setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
		if (back) {
			[trans setSubtype:kCATransitionFromLeft];
		} else {
			[trans setSubtype:kCATransitionFromRight];
		}
		[contentView.layer addAnimation:trans forKey:@"Transition"];
	}

	// Stack current view
	if (currentView != nil) {
		if (!back)
			[historyViews addObject:currentView];
		[currentView removeFromSuperview];
	}

	// Set current view
	LOGI(@"Changig assistant view %d -> %d", currentView.tag, view.tag);
	currentView = view;
	[contentView insertSubview:view atIndex:0];
	[view setFrame:[contentView bounds]];
	[contentView setContentSize:[view bounds].size];
    [self setProviderSelectionButton];
}

- (void)setProviderSelectionButton {
    [providerButtonRightImageView removeFromSuperview];
    UIImage *image = [UIImage imageNamed:@"backArrow.png"];
    providerButtonRightImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.selectProviderButton.frame.size.width - 46, 0, 41, 41)];
    [providerButtonRightImageView setContentMode:UIViewContentModeCenter];
    [providerButtonRightImageView setImage:image];
    providerButtonRightImageView.transform = CGAffineTransformMakeRotation(M_PI);
    [self.selectProviderButton addSubview:providerButtonRightImageView];
}

- (BOOL)addProxyConfig:(NSString*)username
              password:(NSString*)password
                domain:(NSString*)domain
         withTransport:(NSString*)transport
                  port:(int)port {
    [self setConfigurationSettingsInitialValues];
    transport = [transport lowercaseString];
    LinphoneCore* lc = [LinphoneManager getLc];
    
    LinphoneProxyConfig* proxyCfg = linphone_core_create_proxy_config(lc);
    NSString* server_address = domain;
    
    NSLog(@"addProxyConfig transport=%@",transport);
    
    char normalizedUserName[256];
    linphone_proxy_config_normalize_number(proxyCfg, [username cStringUsingEncoding:[NSString defaultCStringEncoding]], normalizedUserName, sizeof(normalizedUserName));
    
    const char* identity = linphone_proxy_config_get_identity(proxyCfg);
    
    if( !identity || !*identity ) identity = "sip:user@example.com";
    
    LinphoneAddress* linphoneAddress = linphone_address_new(identity);
    linphone_address_set_username(linphoneAddress, normalizedUserName);
    
    if( domain && [domain length] != 0) {
        if( transport != nil ){
            server_address = [NSString stringWithFormat:@"%@;transport=%@", server_address, [transport lowercaseString]];
            
            if ([transport isEqualToString:@"tls"]) {
                
//                NSString *cer_file = [Utils resourcePathForFile:@"cafile" Type:@"pem"];
                
 //               if (cer_file) {
 //                   linphone_core_set_root_ca(lc, [cer_file UTF8String]);
//                }
            }
        }
        // when the domain is specified (for external login), take it as the server address
        int result = linphone_proxy_config_set_server_addr(proxyCfg, [server_address UTF8String]);
        
        if (result) {
            [self showDefaultRegistrationFailedMessage];
            [waitView setHidden:true];
            return NO;
        }

        result = linphone_address_set_domain(linphoneAddress, [domain UTF8String]);
        
        if (result) {
            [self showDefaultRegistrationFailedMessage];
            [waitView setHidden:true];
            return NO;
        }
    }
    
    char* extractedAddres = linphone_address_as_string_uri_only(linphoneAddress);
    
    LinphoneAddress* parsedAddress = linphone_address_new(extractedAddres);
    ms_free(extractedAddres);
    
    if( parsedAddress == NULL || !linphone_address_is_sip(parsedAddress) ){
        if( parsedAddress ) linphone_address_destroy(parsedAddress);
//        
//        NSAlert *alert = [[NSAlert alloc]init];
//        [alert addButtonWithTitle:NSLocalizedString(@"Continue",nil)];
//        [alert setMessageText:NSLocalizedString(@"Please enter a valid username", nil)];
//        [alert runModal];
        
        return FALSE;
    }
    
    char *c_parsedAddress = linphone_address_as_string_uri_only(parsedAddress);
    
    int result = linphone_proxy_config_set_identity(proxyCfg, c_parsedAddress);
    
    if (result) {
        [self showDefaultRegistrationFailedMessage];
        [waitView setHidden:true];
        return NO;
    }

    linphone_address_destroy(parsedAddress);
    ms_free(c_parsedAddress);
    
    LinphoneAuthInfo* info = linphone_auth_info_new([username UTF8String]
                                                    , (self.textFieldUserId.text) ? [self.textFieldUserId.text UTF8String] : "", [password UTF8String]
                                                    , NULL
                                                    , NULL
                                                    ,linphone_proxy_config_get_domain(proxyCfg));
    
    // sip_auth_username
    linphone_auth_info_set_username(info, self.textFieldUsername.text.UTF8String);
    
    linphone_auth_info_set_userid(info, self.textFieldUserId.text.UTF8String);
    //sip_auth_password
    linphone_auth_info_set_passwd(info, self.textFieldPassword.text.UTF8String);
    
    
    [self setDefaultSettings:proxyCfg];
    
    [self clearProxyConfig];
    
    NSString *serverAddress = [NSString stringWithFormat:@"sip:%@:%d;transport=%@", domain, port, transport];
    linphone_proxy_config_enable_register(proxyCfg, true);
    linphone_proxy_config_set_server_addr(proxyCfg, [serverAddress UTF8String]);
    linphone_core_add_auth_info(lc, info);
    linphone_core_add_proxy_config(lc, proxyCfg);
    linphone_core_set_default_proxy_config(lc, proxyCfg);
    
    // expiration_time
    linphone_proxy_config_set_expires(proxyCfg, ([DefaultSettingsManager sharedInstance].exparitionTime)?[DefaultSettingsManager sharedInstance].exparitionTime:280);
    
    PayloadType *pt;
    const MSList *elem;
    
    for (elem=linphone_core_get_video_codecs(lc);elem!=NULL;elem=elem->next){
        pt=(PayloadType*)elem->data;
//        NSString *pref=[LinphoneManager getPreferenceForCodec:pt->mime_type withRate:pt->clock_rate];
        int enable = linphone_core_enable_payload_type(lc,pt,1);

        NSLog(@"enable: %d, %@ Core %s", enable, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
              linphone_core_get_version());
    }
    
    // enable_video
    linphone_core_enable_video(lc, [DefaultSettingsManager sharedInstance].enableVideo, [DefaultSettingsManager sharedInstance].enableVideo);
    
    LpConfig *config = linphone_core_get_config(lc);
    LinphoneVideoPolicy policy;
    policy.automatically_accept = [[DefaultSettingsManager sharedInstance] enableVideo];
    policy.automatically_initiate = [[DefaultSettingsManager sharedInstance] enableVideo];
    linphone_core_set_video_policy(lc, &policy);
    linphone_core_enable_self_view(lc, [[DefaultSettingsManager sharedInstance] enableVideo]); // [self boolForKey:@"self_video_preference"]
    BOOL preview_preference = [[DefaultSettingsManager sharedInstance] enableVideo];//[self boolForKey:@"preview_preference"];
    lp_config_set_int(config, [LINPHONERC_APPLICATION_KEY UTF8String], "preview_preference", preview_preference);
    
    NSString *first = [[NSUserDefaults standardUserDefaults] objectForKey:@"ACE_FIRST_OPEN"];
    
    if(![[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"video_preferred_size_preference"]){
        [[NSUserDefaults standardUserDefaults] setObject:@"cif" forKey:@"video_preferred_size_preference"];

        MSVideoSize vsize;
        MS_VIDEO_SIZE_ASSIGN(vsize, CIF);
        linphone_core_set_preferred_video_size([LinphoneManager getLc], vsize);
        linphone_core_set_download_bandwidth([LinphoneManager getLc], [[DefaultSettingsManager sharedInstance] downloadBandwidth]);
        linphone_core_set_upload_bandwidth([LinphoneManager getLc],[ [DefaultSettingsManager sharedInstance] uploadBandwidth]);
        
        [[NSUserDefaults standardUserDefaults] setObject:@"Implicit" forKey:@"rtcp_feedback_pref"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    // video_resolution_maximum
    if (!first) {
        MSVideoSize vsize;
        NSString *videoPreferredSize = [DefaultSettingsManager sharedInstance].videoResolutionMaximum;
        
        if ([videoPreferredSize isEqualToString:@"cif"]) {
            MS_VIDEO_SIZE_ASSIGN(vsize, CIF);
        }
        
        if ([videoPreferredSize isEqualToString:@"qcif"]) {
            MS_VIDEO_SIZE_ASSIGN(vsize, QCIF);
        }
        
        if ([videoPreferredSize isEqualToString:@"vga"]) {
            MS_VIDEO_SIZE_ASSIGN(vsize, VGA);
        }
        
        linphone_core_set_preferred_video_size([LinphoneManager getLc], vsize);
        
        [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"ACE_FIRST_OPEN"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
   // [self setConfigurationSettingsInitialValues];
    LinphoneCoreSettingsStore *settingsStore = [[LinphoneCoreSettingsStore alloc] init];
    [settingsStore transformLinphoneCoreToKeys];
    [settingsStore synchronize];

    return TRUE;
}

- (void)setDefaultSettings:(LinphoneProxyConfig*)proxyCfg {
    LinphoneManager* lm = [LinphoneManager instance];
    
    [lm configurePushTokenForProxyConfig:proxyCfg];
    
}

- (void)clearProxyConfig {
    linphone_core_clear_proxy_config([LinphoneManager getLc]);
    linphone_core_clear_all_auth_info([LinphoneManager getLc]);
}

- (void)addProvisionedProxy:(NSString *)username withPassword:(NSString *)password withDomain:(NSString *)domain {
	[[LinphoneManager instance] removeAllAccounts];
	LinphoneProxyConfig *proxyCfg = linphone_core_create_proxy_config([LinphoneManager getLc]);

	const char *addr = linphone_proxy_config_get_domain(proxyCfg);
	char normalizedUsername[256];
	LinphoneAddress *linphoneAddress = linphone_address_new(addr);

	linphone_proxy_config_normalize_number(proxyCfg, [username UTF8String], normalizedUsername,
										   sizeof(normalizedUsername));

	linphone_address_set_username(linphoneAddress, normalizedUsername);
	linphone_address_set_domain(linphoneAddress, [domain UTF8String]);

	const char *identity = linphone_address_as_string_uri_only(linphoneAddress);
	linphone_proxy_config_set_identity(proxyCfg, identity);

	LinphoneAuthInfo *info =
		linphone_auth_info_new([username UTF8String], NULL, [password UTF8String], NULL, NULL, [domain UTF8String]);

	linphone_proxy_config_enable_register(proxyCfg, true);
	linphone_core_add_auth_info([LinphoneManager getLc], info);
	linphone_core_add_proxy_config([LinphoneManager getLc], proxyCfg);
	linphone_core_set_default_proxy_config([LinphoneManager getLc], proxyCfg);
	// reload address book to prepend proxy config domain to contacts' phone number
	[[[LinphoneManager instance] fastAddressBook] reload];
}

- (NSString *)identityFromUsername:(NSString *)username {
	char normalizedUserName[256];
	LinphoneAddress *linphoneAddress = linphone_address_new("sip:user@domain.com");
	linphone_proxy_config_normalize_number(NULL, [username UTF8String], normalizedUserName, sizeof(normalizedUserName));
	linphone_address_set_username(linphoneAddress, normalizedUserName);
	linphone_address_set_domain(
		linphoneAddress, [[[LinphoneManager instance] lpConfigStringForKey:@"domain" forSection:@"wizard"] UTF8String]);
	NSString *uri = [NSString stringWithUTF8String:linphone_address_as_string_uri_only(linphoneAddress)];
	NSString *scheme = [NSString stringWithUTF8String:linphone_address_get_scheme(linphoneAddress)];
	return [uri substringFromIndex:[scheme length] + 1];
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
    float sysVer = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    if (sysVer >= 8.0) {
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

    } else {
        if (!image) {
            NSString *localImageName = nil;
            if ([lowercaseName rangeOfString:@"sorenson"].location != NSNotFound) {
                localImageName = @"provider0.png";
            }
            else if ([lowercaseName rangeOfString:@"zvrs"].location != NSNotFound) {
                localImageName = @"provider1.png";
            }
            else if ([lowercaseName rangeOfString:@"star"].location != NSNotFound) {
                localImageName = @"provider2.png";
            }
            else if ([lowercaseName rangeOfString:@"convo"].location != NSNotFound) {
                localImageName = @"provider5.png";
            }
            else if ([lowercaseName rangeOfString:@"global"].location != NSNotFound) {
                localImageName = @"provider4.png";
            }
            else if ([lowercaseName rangeOfString:@"purple"].location != NSNotFound) {
                localImageName = @"provider3.png";
            }
            else if ([lowercaseName rangeOfString:@"ace"].location != NSNotFound) {
                localImageName = @"ace_icon2x.png";
            }
            else {
                localImageName = @"ace_icon2x.png";
            }
            image = [UIImage imageNamed:localImageName];
        }
        // prior iOS versions
    }
    
    return image;
}
const NSString *LOGIN_INDEX_KEY = @"login_index";


#pragma mark - Linphone XMLRPC
- (void)checkUserExist:(NSString *)username {
	LOGI(@"XMLRPC check_account %@", username);

	NSURL *URL =
		[NSURL URLWithString:[[LinphoneManager instance] lpConfigStringForKey:@"service_url" forSection:@"wizard"]];
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithURL:URL];
	[request setMethod:@"check_account" withParameters:[NSArray arrayWithObjects:username, nil]];

	XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
	[manager spawnConnectionWithXMLRPCRequest:request delegate:self];

	[waitView setHidden:false];
}

- (void)createAccount:(NSString *)identity password:(NSString *)password email:(NSString *)email {
	NSString *useragent = [LinphoneManager getUserAgent];
	LOGI(@"XMLRPC create_account_with_useragent %@ %@ %@ %@", identity, password, email, useragent);

	NSURL *URL =
		[NSURL URLWithString:[[LinphoneManager instance] lpConfigStringForKey:@"service_url" forSection:@"wizard"]];
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithURL:URL];
	[request setMethod:@"create_account_with_useragent"
		withParameters:[NSArray arrayWithObjects:identity, password, email, useragent, nil]];

	XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
	[manager spawnConnectionWithXMLRPCRequest:request delegate:self];

	[waitView setHidden:false];
}

- (void)checkAccountValidation:(NSString *)identity {
	LOGI(@"XMLRPC check_account_validated %@", identity);

	NSURL *URL =
		[NSURL URLWithString:[[LinphoneManager instance] lpConfigStringForKey:@"service_url" forSection:@"wizard"]];
	XMLRPCRequest *request = [[XMLRPCRequest alloc] initWithURL:URL];
	[request setMethod:@"check_account_validated" withParameters:[NSArray arrayWithObjects:identity, nil]];

	XMLRPCConnectionManager *manager = [XMLRPCConnectionManager sharedManager];
	[manager spawnConnectionWithXMLRPCRequest:request delegate:self];

	[waitView setHidden:false];
}

#pragma mark -
- (void)registrationUpdate:(LinphoneRegistrationState)state message:(NSString *)message {
	switch (state) {
	case LinphoneRegistrationOk: {
        if(self.selectProviderButton){
            if(self.selectProviderButton.titleLabel){
                [[NSUserDefaults standardUserDefaults] setObject:self.selectProviderButton.titleLabel.text forKey:@"selected_provider"];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }
        [waitView setHidden:true];
        [[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]];
		break;
	}
	case LinphoneRegistrationNone:
	case LinphoneRegistrationCleared: {
		[waitView setHidden:true];
		break;
	}
	case LinphoneRegistrationFailed: {
		[waitView setHidden:true];
		if ([message isEqualToString:@"Forbidden"]) {
			message = NSLocalizedString(@"Incorrect username or password.", nil);
		}
        if(!registrationError){
            registrationError = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Registration failure", nil)
														message:message
													   delegate:nil
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
        }
        if(!registrationError.visible){
            [registrationError show];
        }
		break;
	}
	case LinphoneRegistrationProgress: {
		[waitView setHidden:false];
		break;
	}
	default:
		break;
	}
}

- (void)loadWizardConfig:(NSString *)rcFilename {
	NSString *fullPath = [@"file://" stringByAppendingString:[LinphoneManager bundleFile:rcFilename]];
	linphone_core_set_provisioning_uri([LinphoneManager getLc], [fullPath UTF8String]);
	[[LinphoneManager instance] lpConfigSetInt:1 forKey:@"transient_provisioning" forSection:@"misc"];
	[[LinphoneManager instance] resetLinphoneCore];
}

- (BOOL)textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
				replacementString:(NSString *)string {
	// only validate the username when creating a new account
	if ((textField.tag == ViewElement_Username) && (currentView == createAccountView)) {
		BOOL isValidUsername = YES;
		BOOL usePhoneNumber = [[LinphoneManager instance] lpConfigBoolForKey:@"use_phone_number"];
		if (usePhoneNumber) {
			isValidUsername = linphone_proxy_config_is_phone_number(NULL, [string UTF8String]);
		} else {
			NSRegularExpression *regex =
				[NSRegularExpression regularExpressionWithPattern:@"^[a-z0-9-_\\.]*$"
														  options:NSRegularExpressionCaseInsensitive
															error:nil];

			NSArray *matches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
			isValidUsername = ([matches count] != 0);
		}

		if (!isValidUsername) {
			UILabel *error = [WizardViewController findLabel:ViewElement_Username_Error view:contentView];

			// show error with fade animation
			[error setText:[NSString stringWithFormat:NSLocalizedString(@"Illegal character in %@: %@", nil),
													  usePhoneNumber ? NSLocalizedString(@"phone number", nil)
																	 : NSLocalizedString(@"username", nil),
													  string]];
			error.alpha = 0;
			error.hidden = NO;
			[UIView animateWithDuration:0.3
							 animations:^{
							   error.alpha = 1;
							 }];

			// hide again in 2s
			[NSTimer scheduledTimerWithTimeInterval:2.0f
											 target:self
										   selector:@selector(hideError:)
										   userInfo:nil
											repeats:NO];
			return NO;
		}
	}
	return YES;
}

- (void)hideError:(NSTimer *)timer {
	UILabel *error_label = [WizardViewController findLabel:ViewElement_Username_Error view:contentView];
	if (error_label) {
		[UIView animateWithDuration:0.3
			animations:^{
			  error_label.alpha = 0;
			}
			completion:^(BOOL finished) {
			  error_label.hidden = YES;
			}];
	}
}


#pragma mark - Action Functions
- (IBAction)onVideoRelayServiceClick:(id)sender {
    [self changeView:loginView back:FALSE animation:TRUE];
}

- (IBAction)onIPRelayClick:(id)sender {
    [self changeView:loginView back:FALSE animation:TRUE];
}

- (IBAction)onIPCTSClick:(id)sender {
    [self changeView:loginView back:FALSE animation:TRUE];
}
-(NSString*) getProviderSelectTitle{
    return NSLocalizedString(@"Select provider.",nil);
}
-(void) showDomainPopoveriOS7:(id)sender{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[self getProviderSelectTitle]
                                                    message:@""
                                                   delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil, nil];
    
    if (cdnResources) {
        for (NSString *domain in cdnResources) {
            [alert addButtonWithTitle:domain];
        }
    }
    [alert show];
}

-(void) showDomainPopoveriOS8:(id)sender{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:[self getProviderSelectTitle]
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleAlert];
    // alert.view.tintColor = LINPHONE_MAIN_COLOR;
    
    if (cdnResources) {
        for (NSString *domain in cdnResources) {
            UIAlertAction* providerAction =
            
            [UIAlertAction actionWithTitle:domain
                 style:UIAlertActionStyleDefault
               handler:^(UIAlertAction * action) {
                   for (int i = 0; i < cdnResources.count; i++) {
                       if ([action.title isEqualToString:[cdnResources objectAtIndex:i]]) {
                           [self setProviderImageAndDomainByProviderAtIndex:i];
                       }
                   }
               }];
            
            [providerAction setEnabled:YES];
            
            NSString *name = [[domain lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
            NSString *cachePath = [self pathForImageCache];
            NSString *imageName = [NSString stringWithFormat:@"provider_%@.png", name];
            NSString *imagePath = [cachePath stringByAppendingPathComponent:imageName];
            UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
            
            [providerAction setValue:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forKey:@"image"];
            [alert addAction:providerAction];
            [alert.view setBackgroundColor:[UIColor blackColor]];
            [alert setModalPresentationStyle:UIModalPresentationPopover];
            
            UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
            UIButton *button = (UIButton*)sender;
            popPresenter.sourceView = button;
            popPresenter.sourceRect = button.bounds;
            
        }
    }
    
    [self presentViewController:alert animated:YES completion:nil];
}



- (IBAction)onSelectProviderClick:(id)sender {
    if(!cdnResources || cdnResources.count == 0){
        cdnResources = [[NSMutableArray alloc] initWithArray:@[@"Sorenson VRS", @"ZVRS", @"CAAG", @"Purple VRS", @"Global VRS", @"Convo Relay"]];
    }
    
    if([[[UIDevice currentDevice]systemVersion] floatValue] >= 8.0){
        [self showDomainPopoveriOS8:sender];
    }
    else{
        [self showDomainPopoveriOS7:sender];
    }

//    providerPickerView = [[UICustomPicker alloc] initWithFrame:CGRectMake(0, providerButtonLeftImageView.frame.origin.y + DATEPICKER_HEIGHT / 2, self.view.frame.size.width, DATEPICKER_HEIGHT) SourceList:cdnResources];
//    
//    [providerPickerView setAlpha:1.0f];
//    providerPickerView.delegate = self;
//    
//    // Liz E - disable touch in other subviews while the picker is open. Re-enable once the picker is closed.
//    [self setRecursiveUserInteractionEnabled:false];
//    providerPickerView.userInteractionEnabled = true;
//    [self.view addSubview:providerPickerView];
}

- (void)setRecursiveUserInteractionEnabled:(BOOL)value {
    
    //self.view.userInteractionEnabled =   value;
    for (UIView *view in self.view.subviews) {
        view.userInteractionEnabled = value;
    }
}

- (IBAction)onLoginClick:(id)sender {
    
    NSString *rueConfigFormatURL = @"_rueconfig._tls.%domain%";

    NSString *configURL = [rueConfigFormatURL stringByReplacingOccurrencesOfString:@"%domain%" withString:self.textFieldDomain.text];
    NSMutableArray *username = [[NSMutableArray alloc] initWithObjects:self.textFieldUsername.text, nil];
    if (![self checkLoginCredentials]) {
        return;
    }
    if ([[LinphoneManager instance] coreIsRunning]) {
        [[LinphoneManager instance] destroyLinphoneCore];
        [LinphoneManager instanceRelease];
        [LinphoneManager instanceWithUsername:self.textFieldUsername.text andDomain:self.textFieldDomain.text];
        [[LinphoneManager instance] startLinphoneCore];
    }
    [[DefaultSettingsManager sharedInstance] setSipRegisterUserNames:username];
    [[DefaultSettingsManager sharedInstance] setSipAuthUsername:self.textFieldUserId.text];
    [[DefaultSettingsManager sharedInstance] setSipAuthPassword:self.textFieldPassword.text];
    [[DefaultSettingsManager sharedInstance] setSipRegisterDomain:self.textFieldDomain.text];
    [[DefaultSettingsManager sharedInstance] setSipRegisterTransport:self.transportTextField.text];
    [[DefaultSettingsManager sharedInstance] setSipRegisterPort:self.textFieldPort.text.intValue];
    [[DefaultSettingsManager sharedInstance] parseDefaultConfigSettings:configURL];
    
    //Reset video mail count
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"mwi_count"];
}

- (BOOL)checkLoginCredentials {
    
    NSString *errorMessage = @"";
    
    if ([self.textFieldUsername.text length] == 0 ) {
        errorMessage = @"The username can't be empty";
    }
    
    if ([self.textFieldPassword.text length] == 0 && [errorMessage isEqualToString:@""]) {
        errorMessage = @"The password field can't be empty";
    }
    
    if ([self.textFieldDomain.text length] == 0 && [errorMessage isEqualToString:@""]) {
        errorMessage = @"The domain field can't be empty";
    }
    
    if ([self.textFieldPort.text length] == 0 && [errorMessage isEqualToString:@""]) {
        errorMessage = @"The Port field can't be empty";
    }

    if (![errorMessage isEqualToString:@""]) {
        UIAlertView *errorView =
        [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error", nil)
                                   message:errorMessage
                                  delegate:nil
                         cancelButtonTitle:NSLocalizedString(@"Ok", nil)
                         otherButtonTitles:nil, nil];
        [errorView show];
        return NO;
    }
    
    return YES;
}

- (IBAction)onStartClick:(id)sender {
	[self changeView:choiceView back:FALSE animation:TRUE];
}

- (IBAction)onBackClick:(id)sender {
//	if ([historyViews count] > 0) {
//		UIView *view = [historyViews lastObject];
//		[historyViews removeLastObject];
//		[self changeView:view back:TRUE animation:TRUE];
//	}
}

- (IBAction)onCancelClick:(id)sender {
	[[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]];
}

- (IBAction)onCreateAccountClick:(id)sender {
	nextView = createAccountView;
	[self loadWizardConfig:@"wizard_linphone_create.rc"];
}

- (IBAction)onConnectLinphoneAccountClick:(id)sender {
    nextView = connectAccountView;
    [self loadWizardConfig:@"wizard_vtcsecure_existing.rc"];

}

- (IBAction)onExternalAccountClick:(id)sender {
	nextView = externalAccountView;
	[self loadWizardConfig:@"wizard_external_sip.rc"];
}

- (IBAction)onCheckValidationClick:(id)sender {
	NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
	NSString *identity = [self identityFromUsername:username];
	[self checkAccountValidation:identity];
}

- (IBAction)onRemoteProvisioningClick:(id)sender {
	UIAlertView *remoteInput = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter provisioning URL", @"")
														  message:@""
														 delegate:self
												cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
												otherButtonTitles:NSLocalizedString(@"Fetch", @""), nil];
	remoteInput.alertViewStyle = UIAlertViewStylePlainTextInput;

	UITextField *prov_url = [remoteInput textFieldAtIndex:0];
	prov_url.keyboardType = UIKeyboardTypeURL;
	prov_url.text = [[LinphoneManager instance] lpConfigStringForKey:@"config-uri" forSection:@"misc"];
	prov_url.placeholder = @"URL";

	[remoteInput show];
}

- (BOOL)verificationWithUsername:(NSString *)username
						password:(NSString *)password
						  domain:(NSString *)domain
				   withTransport:(NSString *)transport {
	NSMutableString *errors = [NSMutableString string];
	if ([username length] == 0) {
		[errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter a valid username.", nil)]];
		[errors appendString:@"\n"];
	}

	if (domain != nil && [domain length] == 0) {
		[errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter a valid domain.", nil)]];
		[errors appendString:@"\n"];
	}

	if ([errors length]) {
		UIAlertView *errorView =
			[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)", nil)
									   message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
									  delegate:nil
							 cancelButtonTitle:NSLocalizedString(@"Continue", nil)
							 otherButtonTitles:nil, nil];
		[errorView show];
		return FALSE;
	}
	return TRUE;
}

- (void)verificationSignInWithUsername:(NSString *)username
							  password:(NSString *)password
								domain:(NSString *)domain
						 withTransport:(NSString *)transport
                                  port:(int)port {
	if ([self verificationWithUsername:username password:password domain:domain withTransport:transport]) {
		[waitView setHidden:false];
		if ([LinphoneManager instance].connectivity == none) {
			DTAlertView *alert = [[DTAlertView alloc]
				initWithTitle:NSLocalizedString(@"No connectivity", nil)
					  message:NSLocalizedString(@"You can either skip verification or connect to the Internet first.",
												nil)];
			[alert addCancelButtonWithTitle:NSLocalizedString(@"Stay here", nil)
									  block:^{
										[waitView setHidden:true];
									  }];
			[alert
				addButtonWithTitle:NSLocalizedString(@"Continue", nil)
							 block:^{
							   [waitView setHidden:true];
							   [self addProxyConfig:username password:password domain:domain withTransport:transport port:port];
							   [[PhoneMainView instance]
								   changeCurrentView:[DialerViewController compositeViewDescription]];
							 }];
			[alert show];
		} else {
			BOOL success = [self addProxyConfig:username password:password domain:domain withTransport:transport port:port];
			if (!success) {
				waitView.hidden = true;
			}
		}
	}
}

- (IBAction)onSignInExternalClick:(id)sender {
	NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
	NSString *password = [WizardViewController findTextField:ViewElement_Password view:contentView].text;
	NSString *domain = [WizardViewController findTextField:ViewElement_Domain view:contentView].text;
	NSString *transport = [self.transportChooser titleForSegmentAtIndex:self.transportChooser.selectedSegmentIndex];
    
    NSString *port_string = self.textFieldPort.text;
    int port_value = [port_string intValue];
    
    int port = port_value;
    
    [self verificationSignInWithUsername:username password:password domain:domain withTransport:transport port:port];
}

- (IBAction)onSignInClick:(id)sender {
	NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
	NSString *password = [WizardViewController findTextField:ViewElement_Password view:contentView].text;

	// domain and server will be configured from the default proxy values
    [self verificationSignInWithUsername:username password:password domain:nil withTransport:nil port:-1];
}

- (BOOL)verificationRegisterWithUsername:(NSString *)username
								password:(NSString *)password
							   password2:(NSString *)password2
								   email:(NSString *)email {
	NSMutableString *errors = [NSMutableString string];
	NSInteger username_length = [[LinphoneManager instance] lpConfigIntForKey:@"username_length" forSection:@"wizard"];
	NSInteger password_length = [[LinphoneManager instance] lpConfigIntForKey:@"password_length" forSection:@"wizard"];

	if (username_length > (int)username.length) {
		[errors appendString:[NSString stringWithFormat:NSLocalizedString(
															@"The username is too short (minimum %d characters).", nil),
														username_length]];
		[errors appendString:@"\n"];
	}

	if (password_length > (int)password.length) {
		[errors appendString:[NSString stringWithFormat:NSLocalizedString(
															@"The password is too short (minimum %d characters).", nil),
														password_length]];
		[errors appendString:@"\n"];
	}

	if (![password2 isEqualToString:password]) {
		[errors appendString:NSLocalizedString(@"The passwords are different.", nil)];
		[errors appendString:@"\n"];
	}

	NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @".+@.+\\.[A-Za-z]{2}[A-Za-z]*"];
	if (![emailTest evaluateWithObject:email]) {
		[errors appendString:NSLocalizedString(@"The email is invalid.", nil)];
		[errors appendString:@"\n"];
	}

	if ([errors length]) {
		UIAlertView *errorView =
			[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)", nil)
									   message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
									  delegate:nil
							 cancelButtonTitle:NSLocalizedString(@"Continue", nil)
							 otherButtonTitles:nil, nil];
		[errorView show];
		return FALSE;
	}

	return TRUE;
}

- (IBAction)onRegisterClick:(id)sender {
	UITextField *username_tf = [WizardViewController findTextField:ViewElement_Username view:contentView];
	NSString *username = username_tf.text;
	NSString *password = [WizardViewController findTextField:ViewElement_Password view:contentView].text;
	NSString *password2 = [WizardViewController findTextField:ViewElement_Password2 view:contentView].text;
	NSString *email = [WizardViewController findTextField:ViewElement_Email view:contentView].text;

	if ([self verificationRegisterWithUsername:username password:password password2:password2 email:email]) {
		username = [username lowercaseString];
		[username_tf setText:username];
		NSString *identity = [self identityFromUsername:username];
		[self checkUserExist:identity];
	}
}

- (IBAction)onProvisionedLoginClick:(id)sender {
	NSString *username = provisionedUsername.text;
	NSString *password = provisionedPassword.text;

	NSMutableString *errors = [NSMutableString string];
	if ([username length] == 0) {

		[errors appendString:[NSString stringWithFormat:NSLocalizedString(@"Please enter a valid username.", nil)]];
		[errors appendString:@"\n"];
	}

	if ([errors length]) {
		UIAlertView *errorView =
			[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check error(s)", nil)
									   message:[errors substringWithRange:NSMakeRange(0, [errors length] - 1)]
									  delegate:nil
							 cancelButtonTitle:NSLocalizedString(@"Continue", nil)
							 otherButtonTitles:nil, nil];
		[errorView show];
	} else {
		[self.waitView setHidden:false];
		[self addProvisionedProxy:username withPassword:password withDomain:provisionedDomain.text];
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[contentView contentSizeToFit];
}

- (IBAction)onViewTap:(id)sender {
	[LinphoneUtils findAndResignFirstResponder:currentView];
}


#pragma mark - UIAlertViewDelegate

UIAlertView *transportAlert;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  
    if([alertView.title isEqualToString:[self getProviderSelectTitle]]){
        if(cdnResources.count > buttonIndex){
            [self setProviderImageAndDomainByProviderAtIndex:[NSNumber numberWithInteger:buttonIndex].intValue];
        }
    }
    else if([alertView isEqual:transportAlert]){
        if (buttonIndex == 1) {
            [self.transportTextField setText:@"TCP"];
            [self.textFieldPort setText:@"25060"];
        } else if (buttonIndex == 2) {
            [self.transportTextField setText:@"TLS"];
            [self.textFieldPort setText:@"25061"];
        }
        [self.transportTextField becomeFirstResponder];
    }
    else{
        if (buttonIndex == 1) { /* fetch */
            NSString *url = [alertView textFieldAtIndex:0].text;
            if ([url length] > 0) {
                // missing prefix will result in http:// being used
                
                if ([url rangeOfString:@"://"].location == NSNotFound)
                    url = [NSString stringWithFormat:@"http://%@", url];

                    LOGI(@"Should use remote provisioning URL %@", url);
                    linphone_core_set_provisioning_uri([LinphoneManager getLc], [url UTF8String]);

                    [waitView setHidden:false];
                    [[LinphoneManager instance] resetLinphoneCore];
                }
        } else {
            LOGI(@"Canceled remote provisioning");
        }
    }
}

- (void)configuringUpdate:(NSNotification *)notif {
	LinphoneConfiguringState status = (LinphoneConfiguringState)[[notif.userInfo valueForKey:@"state"] integerValue];

	[waitView setHidden:true];

	switch (status) {
	case LinphoneConfiguringSuccessful:
		if (nextView == nil) {
			[self fillDefaultValues];
		} else {
			[self changeView:nextView back:false animation:TRUE];
			nextView = nil;
		}
		break;
	case LinphoneConfiguringFailed: {
		NSString *error_message = [notif.userInfo valueForKey:@"message"];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Provisioning Load error", nil)
														message:error_message
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"OK", nil)
											  otherButtonTitles:nil];
		[alert show];
		break;
	}

	case LinphoneConfiguringSkipped:
	default:
		break;
	}
}


#pragma mark - Event Functions
- (void)registrationUpdateEvent:(NSNotification *)notif {
	NSString *message = [notif.userInfo objectForKey:@"message"];
	[self registrationUpdate:[[notif.userInfo objectForKey:@"state"] intValue] message:message];
}


#pragma mark - XMLRPCConnectionDelegate Functions
- (void)request:(XMLRPCRequest *)request didReceiveResponse:(XMLRPCResponse *)response {
	LOGI(@"XMLRPC %@: %@", [request method], [response body]);
	[waitView setHidden:true];
	if ([response isFault]) {
		NSString *errorString =
			[NSString stringWithFormat:NSLocalizedString(@"Communication issue (%@)", nil), [response faultString]];
		UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Communication issue", nil)
															message:errorString
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"Continue", nil)
												  otherButtonTitles:nil, nil];
		[errorView show];
	} else if ([response object] != nil) { // Don't handle if not object: HTTP/Communication Error
		if ([[request method] isEqualToString:@"check_account"]) {
			if ([response.object isEqualToNumber:[NSNumber numberWithInt:1]]) {
				UIAlertView *errorView =
					[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Check issue", nil)
											   message:NSLocalizedString(@"Username already exists", nil)
											  delegate:nil
									 cancelButtonTitle:NSLocalizedString(@"Continue", nil)
									 otherButtonTitles:nil, nil];
				[errorView show];
			} else {
				NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
				NSString *password = [WizardViewController findTextField:ViewElement_Password view:contentView].text;
				NSString *email = [WizardViewController findTextField:ViewElement_Email view:contentView].text;
				NSString *identity = [self identityFromUsername:username];
				[self createAccount:identity password:password email:email];
			}
		} else if ([[request method] isEqualToString:@"create_account_with_useragent"]) {
			if ([response.object isEqualToNumber:[NSNumber numberWithInt:0]]) {
				NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
				NSString *password = [WizardViewController findTextField:ViewElement_Password view:contentView].text;
				[self changeView:validateAccountView back:FALSE animation:TRUE];
				[WizardViewController findTextField:ViewElement_Username view:contentView].text = username;
				[WizardViewController findTextField:ViewElement_Password view:contentView].text = password;
			} else {
				UIAlertView *errorView = [[UIAlertView alloc]
						initWithTitle:NSLocalizedString(@"Account creation issue", nil)
							  message:NSLocalizedString(@"Can't create the account. Please try again.", nil)
							 delegate:nil
					cancelButtonTitle:NSLocalizedString(@"Continue", nil)
					otherButtonTitles:nil, nil];
				[errorView show];
			}
		} else if ([[request method] isEqualToString:@"check_account_validated"]) {
			if ([response.object isEqualToNumber:[NSNumber numberWithInt:1]]) {
				NSString *username = [WizardViewController findTextField:ViewElement_Username view:contentView].text;
				NSString *password = [WizardViewController findTextField:ViewElement_Password view:contentView].text;
                [self addProxyConfig:username password:password domain:nil withTransport:nil port:-1];
			} else {
				UIAlertView *errorView =
					[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Account validation issue", nil)
											   message:NSLocalizedString(@"Your account is not validate yet.", nil)
											  delegate:nil
									 cancelButtonTitle:NSLocalizedString(@"Continue", nil)
									 otherButtonTitles:nil, nil];
				[errorView show];
			}
		}
	}
}

- (void)request:(XMLRPCRequest *)request didFailWithError:(NSError *)error {
	NSString *errorString =
		[NSString stringWithFormat:NSLocalizedString(@"Communication issue (%@)", nil), [error localizedDescription]];
	UIAlertView *errorView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Communication issue", nil)
														message:errorString
													   delegate:nil
											  cancelButtonTitle:NSLocalizedString(@"Continue", nil)
											  otherButtonTitles:nil, nil];
	[errorView show];
	[waitView setHidden:true];
}

- (BOOL)request:(XMLRPCRequest *)request canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return FALSE;
}

- (void)request:(XMLRPCRequest *)request didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}

- (void)request:(XMLRPCRequest *)request didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
}


#pragma mark - TPMultiLayoutViewController Functions
- (NSDictionary *)attributesForView:(UIView *)view {
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:[NSValue valueWithCGRect:view.frame] forKey:@"frame"];
	[attributes setObject:[NSValue valueWithCGRect:view.bounds] forKey:@"bounds"];
	if ([view isKindOfClass:[UIButton class]]) {
		UIButton *button = (UIButton *)view;
		[LinphoneUtils buttonMultiViewAddAttributes:attributes button:button];
	}
	[attributes setObject:[NSNumber numberWithInteger:view.autoresizingMask] forKey:@"autoresizingMask"];
	return attributes;
}

- (void)applyAttributes:(NSDictionary *)attributes toView:(UIView *)view {
	view.frame = [[attributes objectForKey:@"frame"] CGRectValue];
	view.bounds = [[attributes objectForKey:@"bounds"] CGRectValue];
	if ([view isKindOfClass:[UIButton class]]) {
		UIButton *button = (UIButton *)view;
		[LinphoneUtils buttonMultiViewApplyAttributes:attributes button:button];
	}
	view.autoresizingMask = [[attributes objectForKey:@"autoresizingMask"] integerValue];
}


#pragma mark - UIGestureRecognizerDelegate Functions
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	if ([touch.view isKindOfClass:[UIButton class]]) {
		/* we resign any keyboard that's displayed when a button is touched */
		if ([LinphoneUtils findAndResignFirstResponder:currentView]) {
			return NO;
		}
	}
	return YES;
}


- (void)apiSignIn {
    
    int port = [self.textFieldPort.text intValue];
    NSString *transport = [self.transportTextField.text uppercaseString];
    if(![transport isEqualToString:@"TCP"] && ![transport isEqualToString:@"TLS"]){
        transport = @"TCP";
    }
    [self verificationSignInWithUsername:self.textFieldUsername.text
                                password:self.textFieldPassword.text
                                  domain:self.textFieldDomain.text
                           withTransport:transport
                                    port:port];
}

- (void)setConfigurationSettingsInitialValues {
    LinphoneManager *lm = [LinphoneManager instance];
    LinphoneCore *lc = [LinphoneManager getLc];
    
    // version - ?
    
    // expiration_time - set
    
    // configuration_auth_password - ?
    
    // configuration_auth_expiration - ?
    
    // sip_registration_maximum_threshold - ?
    
    // sip_register_usernames - ?
    
    // sip_auth_username - set
    
    // sip_auth_password - set
    
    // sip_register_domain - set
    
    // sip_register_port - set
    
    // sip_register_transport - set
    
    // enable_echo_cancellation
    linphone_core_enable_echo_cancellation(lc, [DefaultSettingsManager sharedInstance].enableEchoCancellation);
    
    // enable_video - set

    // enable_rtt
    [lm lpConfigSetBool:[DefaultSettingsManager sharedInstance].enableRtt forKey:@"rtt"];
    
    // enable_adaptive_rate
    linphone_core_enable_adaptive_rate_control(lc, [DefaultSettingsManager sharedInstance].enableAdaptiveRate);
    
    // enabled_codecs
    [self enableAppropriateCodecs:linphone_core_get_video_codecs(lc)];

    // bwLimit - ? the name bwlimit is confusing
    linphone_core_set_video_preset(lc, "high-fps");
    
    // upload_bandwidth
    linphone_core_set_upload_bandwidth(lc, [DefaultSettingsManager sharedInstance].uploadBandwidth);

    // download_bandwidth , related to the document
    linphone_core_set_download_bandwidth(lc, ([DefaultSettingsManager sharedInstance].downloadBandwidth)?[DefaultSettingsManager sharedInstance].downloadBandwidth:1500);
    
    // enable_stun, related to the document
    linphone_core_set_firewall_policy(lc, ([DefaultSettingsManager sharedInstance].enableStun)?LinphonePolicyUseStun:LinphonePolicyUseStun);
    
    //stun_server
    linphone_core_set_stun_server(lc, ([DefaultSettingsManager sharedInstance].stunServer.UTF8String)?[DefaultSettingsManager sharedInstance].stunServer.UTF8String : self.textFieldDomain.text.UTF8String);
    
    // enable_ice
    if ([DefaultSettingsManager sharedInstance].enableIce) {
         linphone_core_set_firewall_policy(lc, LinphonePolicyUseIce);
        [lm lpConfigSetInt:1 forKey:@"ice_preference"];
    } else {
        [lm lpConfigSetInt:0 forKey:@"ice_preference"];
    }
    
    // logging
    linphone_core_set_log_level([self logLevel:[DefaultSettingsManager sharedInstance].logging]);
    linphone_core_set_log_handler((OrtpLogFunc)linphone_iphone_log_handler);
    
    
    LinphoneAuthInfo *info = linphone_auth_info_new(self.textFieldUsername.text.UTF8String, self.textFieldUserId.text.UTF8String, self.textFieldPassword.text.UTF8String, NULL, NULL, self.textFieldDomain.text.UTF8String);
    
    linphone_core_add_auth_info([LinphoneManager getLc], info);
    [LinphoneManager.instance refreshRegisters];
//    
//    LinphoneProxyConfig *cfg = linphone_core_get_default_proxy_config([LinphoneManager getLc]);
//    if(cfg){
//        //If autoconfig fails, but you have a valid proxy config, continue to register
//        [[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]];
//        linphone_proxy_config_enable_register(cfg, TRUE);
//        if(!linphone_proxy_config_is_registered(cfg)){
//            [[LinphoneManager instance] refreshRegisters];
//        }
//    }
    // sip_mwi_uri - ?
    
    // sip_videomail_uri - ?
    
    // video_resolution_maximum - set
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)enableAppropriateCodecs:(const MSList *)codecs {
    LinphoneCore *lc = [LinphoneManager getLc];
    PayloadType *pt;
    const MSList *elem;
    
    for (elem = codecs; elem != NULL; elem = elem->next) {
        pt = (PayloadType *)elem->data;
        linphone_core_enable_payload_type(lc, pt, [[DefaultSettingsManager sharedInstance].enabledCodecs containsObject:[NSString stringWithUTF8String:pt->mime_type]]);
        
    }
}

- (OrtpLogLevel)logLevel:(NSString *)logInfo {
    
    if ([logInfo isEqualToString:@"info"]) {
        return ORTP_MESSAGE;
    }
    
    if ([logInfo isEqualToString:@"debug"]) {
        [[LinphoneManager instance] lpConfigSetInt:1 forKey:@"debugenable_preference"];
        return ORTP_DEBUG;
    }
    
    if ([logInfo isEqualToString:@"all"]) {
        return ORTP_TRACE;
    }
    
    
    return ORTP_DEBUG;
}

- (void)showAlert:(NSString*)message {
    NSLog(@"VisualAccessHomeViewController showAlert %@",message);
    if([UIApplication sharedApplication].applicationState == UIApplicationStateActive){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"VisualAccess"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles: nil];
        [alert show];
    }
}

static BOOL isAdvancedShown = NO;
- (IBAction)onToggleAdvanced:(id)sender {
    UIButton *toggle = (UIButton*) sender;
    if(!isAdvancedShown){
        [toggle setTitle:@"-" forState:UIControlStateNormal];
        [_advancedPanel setHidden:NO];
        isAdvancedShown = YES;
    }
    else{
        [toggle setTitle:@"Advanced" forState:UIControlStateNormal];
        [_advancedPanel setHidden:YES];
        isAdvancedShown = NO;
    }
}

- (IBAction)onTransportEditingEnded:(id)sender {
//    if([[self.transportTextField.text lowercaseString] isEqualToString:@"tcp"]){
//        [self.textFieldPort setText:@"5060"];
//    }
//    else if([[self.transportTextField.text lowercaseString] isEqualToString:@"tls"]){
//        [self.textFieldPort setText:@"5061"];
//    }
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    transportAlert = [[UIAlertView alloc] initWithTitle:@"Select Transport" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"TCP", @"TLS", nil];
    [transportAlert show];
    
    return NO;
}

- (void)didAccept {
    acceptButtonClicked = YES;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (acceptButtonClicked) {
        acceptButtonClicked = NO;
        self.view.frame = CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height);
    }
}

- (void)showAcceptanceScreen {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *firstTime = [defaults objectForKey:@"AcceptanceScreen"];
    if (firstTime.length == 0) {
        AcceptanceVC *acceptanceVC = [[AcceptanceVC alloc] initWithNibName:@"AcceptanceVC" bundle:[NSBundle mainBundle]];
        acceptanceVC.delegate = self;
        [self presentViewController:acceptanceVC animated:YES completion:^{
        }];
    }
}

- (void)onProviderLookupFinished:(NSMutableArray *)domains {
    //If cached providers is same, don't refresh custom picker
    if(![cdnResources isEqualToArray:domains]){
        cdnResources = domains;
    }
}

- (void) showDefaultRegistrationFailedMessage {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Registration failure", nil)
                                                    message:DEFAULT_ERROR_DATA_MESSAGE
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (IBAction)transportSelectionButtonTapped:(id)sender {
    transportAlert = [[UIAlertView alloc] initWithTitle:@"Select Transport" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"TCP", @"TLS", nil];
    [transportAlert show];
}

@end
