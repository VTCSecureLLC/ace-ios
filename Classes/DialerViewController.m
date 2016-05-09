/* DialerViewController.h
 *
 * Copyright (C) 2009  Belledonne Comunications, Grenoble, France
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

#import <AVFoundation/AVAudioSession.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SDPNegotiationService.h"
#import "DialerViewController.h"
#import "IncallViewController.h"
#import "DTAlertView.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "Utils.h"
#import "UILinphone.h"
#include "linphone/linphonecore.h"
#import "UICustomPicker.h"

#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"
#import "GAILogger.h"


#define DATEPICKER_HEIGHT 230


@interface DialerViewController() <UICustomPickerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *providerImageView;
@property (nonatomic, strong) UICustomPicker *providerPickerView;
@property NSMutableArray *domains;

@end


@implementation DialerViewController

@synthesize transferMode;
@synthesize addressField;
@synthesize addContactButton;
@synthesize backButton;
@synthesize addCallButton;
@synthesize transferButton;
@synthesize callButton;
@synthesize eraseButton;
@synthesize oneButton;
@synthesize twoButton;
@synthesize threeButton;
@synthesize fourButton;
@synthesize fiveButton;
@synthesize sixButton;
@synthesize sevenButton;
@synthesize eightButton;
@synthesize nineButton;
@synthesize starButton;
@synthesize zeroButton;
@synthesize sharpButton;
@synthesize backgroundView;
@synthesize videoPreview;
@synthesize videoCameraSwitch;


#pragma mark - Lifecycle Functions
- (id)init {
	self = [super initWithNibName:@"DialerViewController" bundle:[NSBundle mainBundle]];
	if (self) {
		self->transferMode = FALSE;
	}
	return self;
}

- (void)dealloc {


	// Remove all observers
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"Dialer"
																content:@"DialerViewController"
															   stateBar:@"UIStateBar"
														stateBarEnabled:true
																 tabBar:@"UIMainBar"
														  tabBarEnabled:true
															 fullscreen:false
														  landscapeMode:[LinphoneManager runningOnIpad]
														   portraitMode:true];
		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}


#pragma mark - ViewController Functions
- (void)viewWillAppear:(BOOL)animated {
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Dialer Screen"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
	[super viewWillAppear:animated];

    self.providerImageView.image = nil;
    self.sipDomainLabel.text = @"";
    self.addressField.sipDomain = nil;
	// Set observer
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(callUpdateEvent:)
												 name:kLinphoneCallUpdate
											   object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(coreUpdateEvent:)
												 name:kLinphoneCoreUpdate
											   object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(togglePreview) name:@"preview_pref_toggle" object:nil];

	// technically not needed, but older versions of linphone had this button
	// disabled by default. In this case, updating by pushing a new version with
	// xcode would result in the callbutton being disabled all the time.
	// We force it enabled anyway now.
	[callButton setEnabled:TRUE];

	// Update on show
	LinphoneManager *mgr = [LinphoneManager instance];
	LinphoneCore *lc = [LinphoneManager getLc];
	LinphoneCall *call = linphone_core_get_current_call(lc);
	LinphoneCallState state = (call != NULL) ? linphone_call_get_state(call) : 0;
	[self callUpdate:call state:state];

	
		BOOL videoEnabled = linphone_core_video_enabled(lc);
		BOOL previewPref = [mgr lpConfigBoolForKey:@"preview_preference"];

		if (videoEnabled && previewPref) {
			linphone_core_set_native_preview_window_id(lc, (__bridge void *)(videoPreview));

			if (!linphone_core_video_preview_enabled(lc)) {
				linphone_core_enable_video_preview(lc, TRUE);
			}

			[backgroundView setHidden:FALSE];
			[videoCameraSwitch setHidden:FALSE];
		} else {
			linphone_core_set_native_preview_window_id(lc, NULL);
			linphone_core_enable_video_preview(lc, FALSE);
			[backgroundView setHidden:TRUE];
			[videoCameraSwitch setHidden:TRUE];
		}
	

	[addressField setText:@""];
    
    /**VATRP-3624: Ensure video capture / display is always on. Going forward all init 
        logic should be moved to a helper class when we refactor after GoLive.**/
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"accept_video_preference"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"start_video_preference"];
    linphone_core_enable_video_capture([LinphoneManager getLc], TRUE);
    linphone_core_enable_video_display([LinphoneManager getLc], TRUE);

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_6_0 // attributed string only available since iOS6
//	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
//		// fix placeholder bar color in iOS7
//		UIColor *color = [UIColor colorWithRed:(140/255.0) green:(201/255.0) blue:(229/255.0) alpha:1] ;
//		NSAttributedString *placeHolderString =
//			[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Enter an address", @"Enter an address")
//											attributes:@{NSForegroundColorAttributeName : color}];
//		addressField.attributedPlaceholder = placeHolderString;
//	}
#endif
    
//Set digit text alignment, and centering.
   // oneButton.titleLabel.numberOfLines = 0;
  //  [oneButton setImage:image forState:UIControlStateNormal];
  //  oneButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
  //  oneButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
   // UIImage *originalImage = [UIImage imageNamed:@"dial_pad_button_unpressed.png"];
   // UIEdgeInsets insets = UIEdgeInsetsMake(0, -10, 0, 10);
   // UIImage *stretchableImage = [originalImage resizableImageWithCapInsets:insets];
   // [oneButton setBackgroundImage:stretchableImage forState:UIControlStateNormal];
    // the image will be stretched to fill the button, if you resize it.
   // twoButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
    
 
    [self applyButtonToForce508:self.zeroButton];
    [self applyButtonToForce508:self.oneButton];
    [self applyButtonToForce508:self.twoButton];
    [self applyButtonToForce508:self.threeButton];
    [self applyButtonToForce508:self.fourButton];
    [self applyButtonToForce508:self.fiveButton];
    [self applyButtonToForce508:self.sevenButton];
    [self applyButtonToForce508:self.sixButton];
    [self applyButtonToForce508:self.eightButton];
    [self applyButtonToForce508:self.nineButton];
    [self applyButtonToForce508:self.starButton];
    [self applyButtonToForce508:self.sharpButton];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	// Remove observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCoreUpdate object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"preview_pref_toggle" object:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
    
    LinphoneCoreSettingsStore *settingsStore = [[LinphoneCoreSettingsStore alloc] init];
    [settingsStore transformLinphoneCoreToKeys];
    [settingsStore synchronize];
	[zeroButton setDigit:'0'];
	[oneButton setDigit:'1'];
	[twoButton setDigit:'2'];
	[threeButton setDigit:'3'];
	[fourButton setDigit:'4'];
	[fiveButton setDigit:'5'];
	[sixButton setDigit:'6'];
	[sevenButton setDigit:'7'];
	[eightButton setDigit:'8'];
	[nineButton setDigit:'9'];
	[starButton setDigit:'*'];
	[sharpButton setDigit:'#'];

	[addressField setAdjustsFontSizeToFitWidth:TRUE]; // Not put it in IB: issue with placeholder size

	if ([LinphoneManager runningOnIpad]) {
		if ([LinphoneManager instance].frontCamId != nil) {
			// only show camera switch button if we have more than 1 camera
			[videoCameraSwitch setHidden:FALSE];
		}
	}
    [self loadProviderDomainsFromCache];
    self.asyncProviderLookupOperation = [[AsyncProviderLookupOperation alloc] init];
    self.asyncProviderLookupOperation.delegate = self;
    [self.asyncProviderLookupOperation reloadProviderDomains];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    NSString *domain = [[NSUserDefaults standardUserDefaults] objectForKey:@"selected_provider"];
    [self fillProviderImageWithDomain:domain];
}
- (void)viewDidUnload {
	[super viewDidUnload];
}

-(void)togglePreview{
    LinphoneCore *lc = [LinphoneManager getLc];
    LinphoneManager *mgr = [LinphoneManager instance];
    BOOL videoEnabled = linphone_core_video_enabled(lc);
    BOOL previewPref = ![mgr lpConfigBoolForKey:@"preview_preference"];
    [mgr lpConfigSetBool:previewPref forKey:@"preview_preference"];
    
    if (videoEnabled && previewPref) {
        linphone_core_set_native_preview_window_id(lc, (__bridge void *)(videoPreview));
        
        if (!linphone_core_video_preview_enabled(lc)) {
            linphone_core_enable_video_preview(lc, TRUE);
        }
        
        [backgroundView setHidden:FALSE];
        [videoCameraSwitch setHidden:FALSE];
    } else {
        linphone_core_set_native_preview_window_id(lc, NULL);
        linphone_core_enable_video_preview(lc, FALSE);
        [backgroundView setHidden:TRUE];
        [videoCameraSwitch setHidden:TRUE];
    }
}

- (void)loadProviderDomainsFromCache {
    NSString *name;
    self.domains = [[NSMutableArray alloc] init];
    name = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"provider%d", 0]];
    
    for(int i = 1; name; i++){
        [self.domains addObject:name];
        name = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"provider%d", i]];
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
										 duration:(NSTimeInterval)duration {
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	CGRect frame = [videoPreview frame];
	switch (toInterfaceOrientation) {
	case UIInterfaceOrientationPortrait:
		[videoPreview setTransform:CGAffineTransformMakeRotation(0)];
		break;
	case UIInterfaceOrientationPortraitUpsideDown:
		[videoPreview setTransform:CGAffineTransformMakeRotation(M_PI)];
		break;
	case UIInterfaceOrientationLandscapeLeft:
		[videoPreview setTransform:CGAffineTransformMakeRotation(M_PI / 2)];
		break;
	case UIInterfaceOrientationLandscapeRight:
		[videoPreview setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
		break;
	default:
		break;
	}
	[videoPreview setFrame:frame];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && _providerPickerView) {
        _providerPickerView.hidden = YES;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && _providerPickerView) {
        _providerPickerView.hidden = NO;
        CGRect frame = CGRectMake(self.view.frame.size.width - self.toolbarView.frame.size.width + 3, self.view.frame.size.height - DATEPICKER_HEIGHT - self.callButton.frame.size.height + 18, self.toolbarView.frame.size.width, DATEPICKER_HEIGHT - 20);
        _providerPickerView.frame = frame;
    }
}

#pragma mark - Private Functions
- (NSString *)pathForImageCache {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *cachePath = [documentsDirectory stringByAppendingPathComponent:@"ImageCache"];
    
    return cachePath;
}

- (void)fillProviderImageWithDomain:(NSString *)domain {
    if(!domain) return;
    
    NSString *name = [[domain lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    NSString *cachePath = [self pathForImageCache];
    NSString *imageName = [NSString stringWithFormat:@"provider_%@.png", name];
    NSString *imagePath = [cachePath stringByAppendingPathComponent:imageName];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    _providerImageView.image = image;
}


#pragma mark - Event Functions
- (void)callUpdateEvent:(NSNotification *)notif {
	LinphoneCall *call = [[notif.userInfo objectForKey:@"call"] pointerValue];
	LinphoneCallState state = [[notif.userInfo objectForKey:@"state"] intValue];
	[self callUpdate:call state:state];
}

- (void)coreUpdateEvent:(NSNotification *)notif {
	
		LinphoneCore *lc = [LinphoneManager getLc];
		if (linphone_core_video_enabled(lc) && linphone_core_video_preview_enabled(lc)) {
			linphone_core_set_native_preview_window_id(lc, (__bridge void *)(videoPreview));
			[backgroundView setHidden:FALSE];
			[videoCameraSwitch setHidden:FALSE];
		} else {
			linphone_core_set_native_preview_window_id(lc, NULL);
			[backgroundView setHidden:TRUE];
			[videoCameraSwitch setHidden:TRUE];
		}
	
}


#pragma mark - Debug Functions
- (void)presentMailViewWithTitle:(NSString *)subject forRecipients:(NSArray *)recipients attachLogs:(BOOL)attachLogs {
	if ([MFMailComposeViewController canSendMail]) {
		MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
		if (controller) {
			controller.mailComposeDelegate = self;
			[controller setSubject:subject];
			[controller setToRecipients:recipients];

			if (attachLogs) {
				char *filepath = linphone_core_compress_log_collection();
				if (filepath == NULL) {
					LOGE(@"Cannot sent logs: file is NULL");
					return;
				}

				NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
				NSString *filename = [appName stringByAppendingString:@".gz"];
				NSString *mimeType = @"text/plain";

				if ([filename hasSuffix:@".gz"]) {
					mimeType = @"application/gzip";
					filename = [appName stringByAppendingString:@".gz"];
				} else {
					LOGE(@"Unknown extension type: %@, cancelling email", filename);
					return;
				}
				[controller setMessageBody:NSLocalizedString(@"Application logs", nil) isHTML:NO];
				[controller addAttachmentData:[NSData dataWithContentsOfFile:[NSString stringWithUTF8String:filepath]]
									 mimeType:mimeType
									 fileName:filename];

				ms_free(filepath);
			}
			self.modalPresentationStyle = UIModalPresentationPageSheet;
			[self.view.window.rootViewController presentViewController:controller
															  animated:TRUE
															completion:^{
															}];
		}

	} else {
		UIAlertView *alert =
			[[UIAlertView alloc] initWithTitle:subject
									   message:NSLocalizedString(@"Error: no mail account configured", nil)
									  delegate:nil
							 cancelButtonTitle:NSLocalizedString(@"OK", nil)
							 otherButtonTitles:nil];
		[alert show];
	}
}

- (BOOL)displayDebugPopup:(NSString *)address {
	LinphoneManager *mgr = [LinphoneManager instance];
	NSString *debugAddress = [mgr lpConfigStringForKey:@"debug_popup_magic" withDefault:@""];
	if (![debugAddress isEqualToString:@""] && [address isEqualToString:debugAddress]) {
		DTAlertView *alertView = [[DTAlertView alloc] initWithTitle:NSLocalizedString(@"Debug", nil)
															message:NSLocalizedString(@"Choose an action", nil)];

		[alertView addCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:nil];

		[alertView
			addButtonWithTitle:NSLocalizedString(@"Send logs", nil)
						 block:^{
						   NSString *appName =
							   [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
						   NSString *logsAddress =
							   [mgr lpConfigStringForKey:@"debug_popup_email" withDefault:@"linphone-ios@linphone.org"];
						   [self presentMailViewWithTitle:appName forRecipients:@[ logsAddress ] attachLogs:true];
						 }];

		BOOL debugEnabled = [[LinphoneManager instance] lpConfigBoolForKey:@"debugenable_preference"];
		NSString *actionLog =
			(debugEnabled ? NSLocalizedString(@"Disable logs", nil) : NSLocalizedString(@"Enable logs", nil));
		[alertView addButtonWithTitle:actionLog
								block:^{
								  // enable / disable
								  BOOL enableDebug = ![mgr lpConfigBoolForKey:@"debugenable_preference"];
								  [mgr lpConfigSetBool:enableDebug forKey:@"debugenable_preference"];
								  [mgr setLogsEnabled:enableDebug];
								}];

		[alertView show];
		return true;
	}
	return false;
}


#pragma mark -
- (void)callUpdate:(LinphoneCall *)call state:(LinphoneCallState)state {
	LinphoneCore *lc = [LinphoneManager getLc];
	if (linphone_core_get_calls_nb(lc) > 0) {
		if (transferMode) {
			[addCallButton setHidden:true];
            [addCallButton setEnabled:NO];
			[transferButton setHidden:false];
            [transferButton setEnabled:YES];
		} else {
			[addCallButton setHidden:false];
            [addCallButton setEnabled:YES];
			[transferButton setHidden:true];
            [transferButton setEnabled:NO];
		}
		[callButton setHidden:true];
		[backButton setHidden:false];
		[addContactButton setHidden:true];

	} else {
		[addCallButton setHidden:true];
		[callButton setHidden:false];
		[backButton setHidden:true];
		[addContactButton setHidden:false];
		[transferButton setHidden:true];
	}
    
    if (linphone_core_get_calls_nb(lc) == 1) {
        UIApplicationState state = [[UIApplication sharedApplication] applicationState];
        if (state == UIApplicationStateBackground || state == UIApplicationStateInactive) {
            [callButton setHidden:false];
        }
    }
}

- (void)setAddress:(NSString *)address {
	[addressField setText:address];
}

- (void)setTransferMode:(BOOL)atransferMode {
	transferMode = atransferMode;
	LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
	LinphoneCallState state = (call != NULL) ? linphone_call_get_state(call) : 0;
	[self callUpdate:call state:state];
}

- (void)call:(NSString *)address {
	NSString *displayName = nil;
	ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:address];
	if (contact) {
		displayName = [FastAddressBook getContactDisplayName:contact];
	}
	[self call:address displayName:displayName];
}

- (void)call:(NSString *)address displayName:(NSString *)displayName {
	[[LinphoneManager instance] call:address displayName:displayName transfer:transferMode];
}


#pragma mark - UITextFieldDelegate Functions
- (BOOL)textField:(UITextField *)textField
	shouldChangeCharactersInRange:(NSRange)range
				replacementString:(NSString *)string {
	//[textField performSelector:@selector() withObject:nil afterDelay:0];
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (textField == addressField) {
		[addressField resignFirstResponder];
	}
	return YES;
}


#pragma mark - MFComposeMailDelegate
- (void)mailComposeController:(MFMailComposeViewController *)controller
		  didFinishWithResult:(MFMailComposeResult)result
						error:(NSError *)error {
	[controller dismissViewControllerAnimated:TRUE
								   completion:^{
								   }];
	[self.navigationController setNavigationBarHidden:TRUE animated:FALSE];
}


#pragma mark - UICustomPickerDelegate
- (void)didCancelUICustomPicker:(UICustomPicker*)customPicker {
    
    [self setRecursiveUserInteractionEnabled:YES];
}

- (void)didSelectUICustomPicker:(UICustomPicker *)customPicker selectedItem:(NSString*)item {
    
    NSString *domain = @"";
    for (int i = 0; i < self.domains.count; ++i) {
        if ([item isEqualToString:[self.domains objectAtIndex:i]]) {
            [self fillProviderImageWithDomain:item];
            domain = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"provider%d_domain", i]];
        }
    }
    if(!domain) { domain = @""; }
    self.sipDomainLabel.text = [@"@" stringByAppendingString:domain];
    self.addressField.sipDomain = domain;
    [self setRecursiveUserInteractionEnabled:YES];
}


#pragma mark - Action Functions
- (IBAction)onAddContactClick: (id) event {
    [ContactSelection setSelectionMode:ContactSelectionModeEdit];
    [ContactSelection setAddAddress:[addressField text]];
    [ContactSelection setSipFilter:nil];
    [ContactSelection setNameOrEmailFilter:nil];
    [ContactSelection enableEmailFilter:FALSE];
    ContactsViewController *controller = DYNAMIC_CAST([[PhoneMainView instance] changeCurrentView:[ContactsViewController compositeViewDescription] push:TRUE], ContactsViewController);
    if(controller != nil) {
        
    }
}

- (IBAction)onBackClick:(id)event {
	[[PhoneMainView instance] changeCurrentView:[InCallViewController compositeViewDescription]];
}

- (IBAction)onAddressChange:(id)sender {
	if ([self displayDebugPopup:self.addressField.text]) {
		self.addressField.text = @"";
	}
	if ([[addressField text] length] > 0) {
		[addContactButton setEnabled:TRUE];
		[eraseButton setEnabled:TRUE];
		[addCallButton setEnabled:TRUE];
		[transferButton setEnabled:TRUE];
	} else {
		[addContactButton setEnabled:FALSE];
		[eraseButton setEnabled:FALSE];
		[addCallButton setEnabled:FALSE];
		[transferButton setEnabled:FALSE];
	}
}

// VTCSecure - select a domain
- (void)showProviderPickerView {
    
    CGRect frame = CGRectZero;
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        frame = CGRectMake(self.view.frame.size.width - self.toolbarView.frame.size.width + 3, self.view.frame.size.height - DATEPICKER_HEIGHT - self.callButton.frame.size.height + 18, self.toolbarView.frame.size.width, DATEPICKER_HEIGHT - 20);
    } else {
        frame = CGRectMake(0, self.view.frame.size.height - DATEPICKER_HEIGHT - self.callButton.frame.size.height - 6, self.view.frame.size.width, DATEPICKER_HEIGHT);
    }
    
    _providerPickerView = [[UICustomPicker alloc] initWithFrame:frame SourceList:self.domains];
    _providerPickerView.delegate = self;
    _providerPickerView.userInteractionEnabled = true;
    [_providerPickerView setAlpha:1.0f];
    [self.view addSubview:_providerPickerView];
}

- (void)setRecursiveUserInteractionEnabled:(BOOL)value {
    
    for (UIView *view in self.view.subviews) {
        view.userInteractionEnabled = value;
    }
}

- (IBAction)domainSelectorClicked:(id)sender {
    
    [self setRecursiveUserInteractionEnabled:NO];
    [self showProviderPickerView];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{

    [self fillProviderImageWithDomain:[self.domains objectAtIndex:buttonIndex]];
    NSString *domain = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"provider%ld_domain", (long)buttonIndex]];
    if(!domain) { domain = @""; }
    self.sipDomainLabel.text = [@"@" stringByAppendingString:domain];
    self.addressField.sipDomain = domain;
}

- (void)onProviderLookupFinished:(NSMutableArray *)domains {
    self.domains = domains;
}

- (void) applyButtonToForce508:(UIDigitButton*)button {
    float alphe = 0.6;
    [button setBackgroundColor:[UIColor colorWithRed:55.0/255.0 green:55.0/255.0 blue:55.0/255.0 alpha:alphe]];

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"force508"]) {
        alphe = 1.0;
    }
    
    [button.titleLabel setAlpha:alphe];
    [button.layer setBorderColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:alphe].CGColor];
    [button.layer setBorderWidth:1.0];
}

@end
