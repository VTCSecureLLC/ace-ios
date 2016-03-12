/* InCallViewController.h
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

#import <AudioToolbox/AudioToolbox.h>
#import <AddressBook/AddressBook.h>
#import <QuartzCore/CAAnimation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

#import "InCallViewController.h"
#import "UICallCell.h"
#import "LinphoneManager.h"
#import "PhoneMainView.h"
#import "UILinphone.h"
#import "DTActionSheet.h"
#import "RTTMessageModel.h"
#include "linphone/linphonecore.h"
#import "UILabel+Clipboard.h"
#import "BubbleTableViewCell.h"

const NSInteger SECURE_BUTTON_TAG = 5;

//integers duplicate format as Android
//const NSInteger TEXT_MODE;
const NSInteger NO_TEXT=-1;
const NSInteger RTT=0;
const NSInteger SIP_SIMPLE=1;

typedef NS_ENUM(NSInteger, CallQualityStatus) {
    CallQualityStatusBad,
    CallQualityStatusMedium,
    CallQualityStatusGood,
    CallQualityStatusNone
};


@interface InCallViewController() <BubbleTableViewCellDataSource>
@property (weak, nonatomic) IBOutlet UIButton *closeChatButton;

    @property NSMutableArray *chatEntries;
    @property UITableView *tableView;
    //Index to access remote or local text buffer in data set
    @property int localTextBufferIndex;
    @property int remoteTextBufferIndex;
    // Temp model buffer
    @property RTTMessageModel *localTextBuffer;
    @property RTTMessageModel *remoteTextBuffer;
    @property UIColor *localColor;
    @property UIImageView *cameraStatusModeImageView;
    @property UIView *blackCurtain;

@property BOOL isRTTLocallyEnabled;
@property (weak, nonatomic) IBOutlet UIScrollView *minimizedTextScrollView;

@property (weak, nonatomic) IBOutlet UITextView *incomingTextView;
@property NSTimeInterval year2037TimeStamp;
@property NSTimeInterval year2036TimeStamp;

@end

@implementation InCallViewController {
	BOOL hiddenVolume;
    int RTT_MAX_PARAGRAPH_CHAR;
    int RTT_SOFT_MAX_PARAGRAPH_CHAR;
    UIImageView *callOnHoldImageView;
    UIImageView *callQualityImageView;
    CallQualityStatus callQualityStatus;
    NSTimer *timerCallQuality;
    BOOL isControlsShown;
    UITapGestureRecognizer* singleFingerTap;
}


@synthesize callTableController;
@synthesize callTableView;
@synthesize isRTTEnabled;
@synthesize videoGroup;
@synthesize videoView;
@synthesize videoPreview;
@synthesize videoCameraSwitch;
@synthesize videoWaitingForFirstImage;
#ifdef TEST_VIDEO_VIEW_CHANGE
@synthesize testVideoView;
#endif

#pragma mark - Lifecycle Functions
static InCallViewController *instance;
- (id)init {
	self = [super initWithNibName:@"InCallViewController" bundle:[NSBundle mainBundle]];
	if (self != nil) {
		self->videoZoomHandler = [[VideoZoomHandler alloc] init];
        callQualityStatus = CallQualityStatusNone;
	}
	return self;
}

- (void)dealloc {
	// Remove all observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeGestureRecognizers];
}

#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"InCall"
																content:@"InCallViewController"
															   stateBar:@"UIStateBar"
														stateBarEnabled:true
																 tabBar:@"UICallBar"
														  tabBarEnabled:true
															 fullscreen:false
														  landscapeMode:true
														   portraitMode:true];
		compositeDescription.darkBackground = true;
	}
	return compositeDescription;
}

#pragma mark - ViewController Functions

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];

	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	UIDevice *device = [UIDevice currentDevice];
	device.proximityMonitoringEnabled = YES;
    
	[[PhoneMainView instance] setVolumeHidden:TRUE];
	hiddenVolume = TRUE;
    if(self.incomingTextView){
        [self.incomingTextView setText:@""];
        [self.incomingTextView setHidden:YES];
    }
    
    if(self.closeChatButton){
        [self.closeChatButton setHidden:YES];
    }
    
    self.chatEntries = [[NSMutableArray alloc] init];
    self.localTextBufferIndex = 0;
    self.remoteTextBufferIndex = 0;

    self.localTextBuffer = nil;
    self.remoteTextBuffer = nil;
    minimizedTextBuffer = nil;
    if(self.tableView){
        [self.tableView setHidden:YES];
    }
    self.isChatMode = NO;
    if([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"enable_rtt"]){
        self.isRTTLocallyEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_rtt"];
    }
    else{
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"enable_rtt"];
        self.isRTTLocallyEnabled = YES;
    }
    isControlsShown = true;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
//	if (hideControlsTimer != nil) {
//		[hideControlsTimer invalidate];
//		hideControlsTimer = nil;
//	}

	if (hiddenVolume) {
		[[PhoneMainView instance] setVolumeHidden:FALSE];
		hiddenVolume = FALSE;
	}
    
    if(self.incomingTextView){
        self.incomingTextView.text = @"";
        [self.incomingTextView setHidden:YES];
    }

	// Remove observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneVideModeUpdate object:nil];
    [_blackCurtain removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	// Set observer
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(callUpdateEvent:)
												 name:kLinphoneCallUpdate
											   object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoModeUpdate:)
                                                 name:kLinphoneVideModeUpdate
                                               object:nil];

	// Update on show
	LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
	LinphoneCallState state = (call != NULL) ? linphone_call_get_state(call) : 0;
	[self callUpdate:call state:state animated:FALSE];

	// Set windows (warn memory leaks)
	linphone_core_set_native_video_window_id([LinphoneManager getLc], (__bridge void *)(videoView));
	linphone_core_set_native_preview_window_id([LinphoneManager getLc], (__bridge void *)(videoPreview));

	// Enable tap
	[singleFingerTap setEnabled:TRUE];
    // Hide fields.
    [self.incomingTextView setHidden:YES];
    [self.incomingTextView setText:@""];
    
    //Speaker mute
    const float mute_db = -1000.0f;
   
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isSpeakerMuted = [defaults boolForKey:@"mute_speaker_preference"];
    
    if(![[[defaults dictionaryRepresentation] allKeys] containsObject:@"mute_speaker_preference"]){
        isSpeakerMuted = NO;
    }
    
    if(!isSpeakerMuted){
        linphone_core_set_playback_gain_db([LinphoneManager getLc], 0);
    }
    else{
        linphone_core_set_playback_gain_db([LinphoneManager getLc], mute_db);
    }
    
    self.isRTTEnabled = YES;
    self.isRTTLocallyEnabled = YES;
    
    self.incomingTextView.layoutManager.allowsNonContiguousLayout = FALSE;
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];

	[[UIApplication sharedApplication] setIdleTimerDisabled:false];
	UIDevice *device = [UIDevice currentDevice];
	device.proximityMonitoringEnabled = NO;

	[[PhoneMainView instance] fullScreen:false];
	// Disable tap
	[singleFingerTap setEnabled:FALSE];
}

CGPoint incomingTextChatModePos;

- (void)viewDidLoad {
	[super viewDidLoad];
    [self getBiggestTimeStamps];
    [self addGestureRecognizers];
	[videoZoomHandler setup:videoGroup];
	videoGroup.alpha = 0;

	[videoCameraSwitch setPreview:videoPreview];

	[callTableController.tableView setBackgroundColor:[UIColor clearColor]]; // Can't do it in Xib: issue with ios4
	[callTableController.tableView setBackgroundView:nil];					 // Can't do it in Xib: issue with ios4
/* Disable move of self preview
	UIPanGestureRecognizer *dragndrop =
		[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveVideoPreview:)];
	dragndrop.minimumNumberOfTouches = 1;
	[self.videoPreview addGestureRecognizer:dragndrop];
 */

    if(self.incomingTextView){
        self.incomingTextView.backgroundColor = [UIColor blackColor];
        self.incomingTextView.textColor = [UIColor whiteColor];
        [self.incomingTextView setTextAlignment:NSTextAlignmentLeft];
        self.incomingTextView.text = @"";
        self.incomingTextView.alpha = 0.7;
        [self.incomingTextView setUserInteractionEnabled:YES];

        UITapGestureRecognizer *singleFingerTappedIncomingChat = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openChatMessage:)];
        singleFingerTappedIncomingChat.numberOfTouchesRequired = 1;
        singleFingerTappedIncomingChat.numberOfTapsRequired = 1;
        [singleFingerTappedIncomingChat setCancelsTouchesInView:NO];
        [self.incomingTextView addGestureRecognizer:singleFingerTappedIncomingChat];
        
        [self.incomingTextView canBecomeFirstResponder];
       // [self.incomingTextField enableClipboard:YES];
        
        [self.incomingTextView setHidden:YES];
    }
    if(!self.closeChatButton && self.incomingTextView){
        
        [self.closeChatButton setHidden:YES];
    }
    
    // We listen for incoming text.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textComposeEvent:) name:kLinphoneTextComposeEvent object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    instance = self;
    [self loadRTTChatTableView];
    
    _cameraStatusModeImageView = [[UIImageView alloc] initWithFrame:self.videoGroup.bounds];
    _cameraStatusModeImageView.contentMode = UIViewContentModeScaleAspectFit;
    _blackCurtain = [[UIView alloc] initWithFrame:self.videoGroup.bounds];
    [_blackCurtain setBackgroundColor:[UIColor blackColor]];
}

- (void)addGestureRecognizers {
    singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
    [singleFingerTap setNumberOfTapsRequired:1];
    [singleFingerTap setCancelsTouchesInView:FALSE];
    [self.view addGestureRecognizer:singleFingerTap];
}

- (void)removeGestureRecognizers {
    [self.view removeGestureRecognizer:singleFingerTap];
}

- (void)viewDidUnload {
    [self removeGestureRecognizers];
	[super viewDidUnload];
}
BOOL hasStartedStream = NO;
-(BOOL) isRTTEnabled{
    if(!hasStartedStream){
        return YES;
    }
    return isRTTEnabled;
}
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
										 duration:(NSTimeInterval)duration {
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	// in mode display_filter_auto_rotate=0, no need to rotate the preview
    _blackCurtain.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    callQualityImageView.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    _cameraStatusModeImageView.frame = _blackCurtain.frame;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self previewTouchLift];
}

#pragma mark -

- (void)callUpdate:(LinphoneCall *)call state:(LinphoneCallState)state animated:(BOOL)animated {
	LinphoneCore *lc = [LinphoneManager getLc];
    
	if (hiddenVolume) {
		[[PhoneMainView instance] setVolumeHidden:FALSE];
		hiddenVolume = FALSE;
	}

	// Update table
	[callTableView reloadData];

	// Fake call update
	if (call == NULL) {
		return;
	}
    
    if(state == LinphoneCallPausedByRemote){
        UIImage *img = [UIImage imageNamed:@"Hold.png"];
        callOnHoldImageView = [[UIImageView alloc] initWithImage:img];
        [callOnHoldImageView setCenter:self.videoView.center];
        [callOnHoldImageView setHidden:NO];
        [callOnHoldImageView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
        [self.view addSubview:callOnHoldImageView];
        [self.videoView setHidden:YES];
    }
    else{
        if(callOnHoldImageView){
            [callOnHoldImageView removeFromSuperview];
        }
        [self.videoView setHidden:NO];
    }

	switch (state) {
	case LinphoneCallIncomingReceived:
	case LinphoneCallOutgoingInit: {
		if (linphone_core_get_calls_nb(lc) > 1) {
			[callTableController minimizeAll];
		}
        
        if(!self.isRTTLocallyEnabled){
            linphone_call_params_enable_realtime_text(linphone_core_create_call_params([LinphoneManager getLc], call), FALSE);
        }
        
        callQualityImageView.hidden = YES;
	}
	case LinphoneCallConnected:
	case LinphoneCallStreamsRunning: {
        // check realtime text.
        
        [[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceOrientationDidChangeNotification
                                                            object:nil];
        if(state == LinphoneCallStreamsRunning){
            if(self.isRTTLocallyEnabled){
                if (linphone_call_params_realtime_text_enabled(linphone_call_get_remote_params(call))){
                    self.isRTTEnabled = YES;
                }
                else{
                    self.isRTTEnabled = NO;
                }
            }
            else{
                self.isRTTEnabled = NO;
            }
            hasStartedStream = YES;
        }
        else{
            self.isRTTEnabled = YES;
        }
		// check video
		if (linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
			[self displayVideoCall:animated];
            const LinphoneCallParams *params = linphone_call_get_current_params(call);
            if(params != NULL){
                //If H.263, rotate video sideways when in portrait to work around codec limitations
                if(strcmp(linphone_call_params_get_used_video_codec(params)->mime_type, "H263") == 0){
                    if(linphone_core_get_device_rotation([LinphoneManager getLc]) != 90 &&
                        linphone_core_get_device_rotation([LinphoneManager getLc]) != 270){
                        
                        linphone_core_set_device_rotation([LinphoneManager getLc], 270);
                        linphone_core_update_call([LinphoneManager getLc], call, NULL);
                    }
                }
                else{
                    [[PhoneMainView instance] orientationUpdate:self.interfaceOrientation];
                }
            }
		} else {
			[self displayTableCall:animated];
			const LinphoneCallParams *param = linphone_call_get_current_params(call);
			const LinphoneCallAppData *callAppData =
				(__bridge const LinphoneCallAppData *)(linphone_call_get_user_pointer(call));
			if (state == LinphoneCallStreamsRunning && callAppData->videoRequested &&
				linphone_call_params_low_bandwidth_enabled(param)) {
				// too bad video was not enabled because low bandwidth
				UIAlertView *alert = [[UIAlertView alloc]
						initWithTitle:NSLocalizedString(@"Low bandwidth", nil)
							  message:NSLocalizedString(@"Video cannot be activated because of low bandwidth "
														@"condition, only audio is available",
														nil)
							 delegate:nil
					cancelButtonTitle:NSLocalizedString(@"Continue", nil)
					otherButtonTitles:nil];
				[alert show];
				callAppData->videoRequested = FALSE; /*reset field*/
			}
		}
        
        timerCallQuality = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                            target:self
                                                          selector:@selector(callQualityTimerBody)
                                                          userInfo:nil
                                                           repeats:YES];
        
        [self createCallQuality];
        callQualityImageView.hidden = NO;

		break;
	}
	case LinphoneCallUpdatedByRemote: {
		const LinphoneCallParams *current = linphone_call_get_current_params(call);
		const LinphoneCallParams *remote = linphone_call_get_remote_params(call);
		/* remote wants to add video */
		if (linphone_core_video_enabled(lc) && !linphone_call_params_video_enabled(current) &&
			linphone_call_params_video_enabled(remote) && !linphone_core_get_video_policy(lc)->automatically_accept) {
			linphone_core_defer_call_update(lc, call);
			[self displayAskToEnableVideoCall:call];
		} else if (linphone_call_params_video_enabled(current) && !linphone_call_params_video_enabled(remote)) {
			[self displayTableCall:animated];
		}
		break;
	}
	case LinphoneCallPausing:
	case LinphoneCallPaused:
	case LinphoneCallPausedByRemote: {
		[self displayTableCall:animated];
		break;
	}
	case LinphoneCallEnd:
	case LinphoneCallError: {
        if(self.incomingTextView){
            self.incomingTextView.text = @"";
        }
//        if(self.outgoingTextLabel){
//            self.outgoingTextLabel.text = @"";
//        }
		if (linphone_core_get_calls_nb(lc) <= 2 && !videoShown) {
			[callTableController maximizeAll];
		}
        
        [timerCallQuality invalidate];
        timerCallQuality = nil;
        
        callQualityImageView.hidden = YES;
        
		break;
	}
	default:
		break;
	}
}

-(void)handleSingleTap {
    (isControlsShown)?[self showControls]:[self hideControls];
}

- (void)showControls {
    if(self.isFirstResponder || ![self.tableView isHidden]){
        [self resignFirstResponder];
        [self.tableView setHidden:YES];
        return;
    }
    // we want to recognize the tap as a toggle now since we are removing the hideControlsTimer.
	if ([[[PhoneMainView instance] currentView] equal:[InCallViewController compositeViewDescription]] && videoShown) {
		// show controls
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		[[PhoneMainView instance] showTabBar:true];
		[[PhoneMainView instance] showStateBar:true];
		[callTableView setAlpha:1.0];
		[videoCameraSwitch setAlpha:1.0];
		[UIView commitAnimations];
        isControlsShown = false;
    }
}

- (void)hideControls {
	if ([[[PhoneMainView instance] currentView] equal:[InCallViewController compositeViewDescription]] && videoShown) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		[videoCameraSwitch setAlpha:0.0];
		[callTableView setAlpha:0.0];
		[UIView commitAnimations];
		[[PhoneMainView instance] showTabBar:false];
		[[PhoneMainView instance] showStateBar:false];
        isControlsShown = true;
	}
}

#ifdef TEST_VIDEO_VIEW_CHANGE
// Define TEST_VIDEO_VIEW_CHANGE in IncallViewController.h to enable video view switching testing
- (void)_debugChangeVideoView {
	static bool normalView = false;
	if (normalView) {
		linphone_core_set_native_video_window_id([LinphoneManager getLc], (unsigned long)videoView);
	} else {
		linphone_core_set_native_video_window_id([LinphoneManager getLc], (unsigned long)testVideoView);
	}
	normalView = !normalView;
}
#endif

- (void)enableVideoDisplay:(BOOL)animation {
	if (videoShown && animation)
		return;
    
	videoShown = true;

	if (animation) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:1.0];
	}

	[videoGroup setAlpha:1.0];
	[callTableView setAlpha:0.0];

	UIEdgeInsets insets = {33, 0, 25, 0};
	[callTableView setContentInset:insets];
	[callTableView setScrollIndicatorInsets:insets];
	[callTableController minimizeAll];

	if (animation) {
		[UIView commitAnimations];
	}

	if (linphone_core_self_view_enabled([LinphoneManager getLc])) {
		[videoPreview setHidden:FALSE];
	} else {
		[videoPreview setHidden:TRUE];
	}

	if ([LinphoneManager instance].frontCamId != nil) {
		// only show camera switch button if we have more than 1 camera
		[videoCameraSwitch setHidden:FALSE];
	}
	[videoCameraSwitch setAlpha:0.0];

	[[PhoneMainView instance] fullScreen:true];
	[[PhoneMainView instance] showTabBar:false];
	[[PhoneMainView instance] showStateBar:false];
#ifdef TEST_VIDEO_VIEW_CHANGE
	[NSTimer scheduledTimerWithTimeInterval:5.0
									 target:self
								   selector:@selector(_debugChangeVideoView)
								   userInfo:nil
									repeats:YES];
#endif

	// [self batteryLevelChanged:nil];

	[videoWaitingForFirstImage setHidden:NO];
	[videoWaitingForFirstImage startAnimating];

	LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
	// linphone_call_params_get_used_video_codec return 0 if no video stream enabled
	if (call != NULL && linphone_call_params_get_used_video_codec(linphone_call_get_current_params(call))) {
		linphone_call_set_next_video_frame_decoded_callback(call, hideSpinner, (__bridge void *)(self));
	}
}

- (void)disableVideoDisplay:(BOOL)animation {
	if (!videoShown && animation)
		return;

	videoShown = false;
	if (animation) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:1.0];
	}

	[videoGroup setAlpha:0.0];
	[[PhoneMainView instance] showTabBar:true];

	UIEdgeInsets insets = {10, 0, 25, 0};
	[callTableView setContentInset:insets];
	[callTableView setScrollIndicatorInsets:insets];
	[callTableView setAlpha:1.0];
	if (linphone_core_get_calls_nb([LinphoneManager getLc]) <= 2) {
		[callTableController maximizeAll];
	}

	[callTableView setAlpha:1.0];
	[videoCameraSwitch setHidden:TRUE];

	if (animation) {
		[UIView commitAnimations];
	}

//	if (hideControlsTimer != nil) {
//		[hideControlsTimer invalidate];
//		hideControlsTimer = nil;
//	}

	[[PhoneMainView instance] fullScreen:false];
}

- (void)displayVideoCall:(BOOL)animated {
	[self enableVideoDisplay:FALSE];
}

- (void)displayTableCall:(BOOL)animated {
	[self disableVideoDisplay:FALSE];
}

#pragma mark - Spinner Functions

- (void)hideSpinnerIndicator:(LinphoneCall *)call {
	videoWaitingForFirstImage.hidden = TRUE;
}

static void hideSpinner(LinphoneCall *call, void *user_data) {
	InCallViewController *thiz = (__bridge InCallViewController *)user_data;
	[thiz hideSpinnerIndicator:call];
}

#pragma mark - Event Functions

- (void)callUpdateEvent:(NSNotification *)notif {
	LinphoneCall *call = [[notif.userInfo objectForKey:@"call"] pointerValue];
	LinphoneCallState state = [[notif.userInfo objectForKey:@"state"] intValue];
	[self callUpdate:call state:state animated:TRUE];
}

#pragma mark - ActionSheet Functions

- (void)displayAskToEnableVideoCall:(LinphoneCall *)call {
	if (linphone_core_get_video_policy([LinphoneManager getLc])->automatically_accept)
		return;

	const char *lUserNameChars = linphone_address_get_username(linphone_call_get_remote_address(call));
	NSString *lUserName =
		lUserNameChars ? [[NSString alloc] initWithUTF8String:lUserNameChars] : NSLocalizedString(@"Unknown", nil);
	const char *lDisplayNameChars = linphone_address_get_display_name(linphone_call_get_remote_address(call));
	NSString *lDisplayName = lDisplayNameChars ? [[NSString alloc] initWithUTF8String:lDisplayNameChars] : @"";

	NSString *title = [NSString stringWithFormat:NSLocalizedString(@"'%@' would like to enable video", nil),
												 ([lDisplayName length] > 0) ? lDisplayName : lUserName];
	DTActionSheet *sheet = [[DTActionSheet alloc] initWithTitle:title];
	NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:30
													  target:self
													selector:@selector(dismissVideoActionSheet:)
													userInfo:sheet
													 repeats:NO];
	[sheet addButtonWithTitle:NSLocalizedString(@"Accept", nil)
						block:^() {
						  LOGI(@"User accept video proposal");
						  LinphoneCallParams *paramsCopy =
							  linphone_call_params_copy(linphone_call_get_current_params(call));
						  linphone_call_params_enable_video(paramsCopy, TRUE);
						  linphone_core_accept_call_update([LinphoneManager getLc], call, paramsCopy);
						  linphone_call_params_destroy(paramsCopy);
						  [timer invalidate];
						}];
	DTActionSheetBlock cancelBlock = ^() {
	  LOGI(@"User declined video proposal");
	  LinphoneCallParams *paramsCopy = linphone_call_params_copy(linphone_call_get_current_params(call));
	  linphone_core_accept_call_update([LinphoneManager getLc], call, paramsCopy);
	  linphone_call_params_destroy(paramsCopy);
	  [timer invalidate];
	};
	[sheet addDestructiveButtonWithTitle:NSLocalizedString(@"Decline", nil) block:cancelBlock];
	if ([LinphoneManager runningOnIpad]) {
		[sheet addCancelButtonWithTitle:NSLocalizedString(@"Decline", nil) block:cancelBlock];
	}
	[sheet showInView:[PhoneMainView instance].view];
}

- (void)dismissVideoActionSheet:(NSTimer *)timer {
	DTActionSheet *sheet = (DTActionSheet *)timer.userInfo;
	[sheet dismissWithClickedButtonIndex:sheet.destructiveButtonIndex animated:TRUE];
}

#pragma mark VideoPreviewMoving

- (void)moveVideoPreview:(UIPanGestureRecognizer *)dragndrop {
	CGPoint center = [dragndrop locationInView:videoPreview.superview];
	self.videoPreview.center = center;
	if (dragndrop.state == UIGestureRecognizerStateEnded) {
		[self previewTouchLift];
	}
}

- (CGFloat)coerce:(CGFloat)value betweenMin:(CGFloat)min andMax:(CGFloat)max {
	if (value > max) {
		value = max;
	}
	if (value < min) {
		value = min;
	}
	return value;
}

- (void)previewTouchLift {
	CGRect previewFrame = self.videoPreview.frame;
	previewFrame.origin.x = [self coerce:previewFrame.origin.x
							  betweenMin:5
								  andMax:(self.view.frame.size.width - previewFrame.size.width - 5)];
	previewFrame.origin.y = [self coerce:previewFrame.origin.y
							  betweenMin:5
								  andMax:(self.view.frame.size.height - previewFrame.size.height - 5)];

	if (!CGRectEqualToRect(previewFrame, self.videoPreview.frame)) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		  [UIView animateWithDuration:0.3
						   animations:^{
							 LOGI(@"Recentering preview to %@", NSStringFromCGRect(previewFrame));
							 self.videoPreview.frame = previewFrame;
						   }];
		});
	}
}


#pragma mark RTT Logic

/* A field that must be implemented for the text protocol */
- (BOOL)hasText {
    return YES;
}

/* Can become first responder. This is inly possible in calls with text. */
- (BOOL)canBecomeFirstResponder {
    LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
    if (call)
    {
        if (linphone_call_params_realtime_text_enabled(linphone_call_get_current_params(call)))
            return YES;
    }
    return NO;
}

/* Text Mode RTT or SIP SIMPLE duplicate with Android*/
-(int) getTextMode{
    //SET TO RTT BY DEFAULT, THIS WILL CHANGE IN GLOBAL SETTINGS.
    int TEXT_MODE=RTT;
    
    //prefs = PreferenceManager.getDefaultSharedPreferences(LinphoneActivity.instance());
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   
    //String text_mode=prefs.getString(getString(R.string.pref_text_settings_send_mode_key), "RTT");
    NSString* text_mode_string=[defaults stringForKey:@"pref_text_settings_send_mode_key"];
    
     //Log.d("Text Send Mode" + prefs.getString(getString(R.string.pref_text_settings_send_mode_key), "RTT"));
    NSLog(@"Text mode is %@",text_mode_string);
//    if(text_mode.equals("SIP_SIMPLE")) {
//        TEXT_MODE=SIP_SIMPLE;
//    }else if(text_mode.equals("RTT")) {
//        TEXT_MODE=RTT;
//        
//    }
    
    if([text_mode_string isEqualToString:@"SIP_SIMPLE"]) {
        TEXT_MODE=SIP_SIMPLE;
    }else if([text_mode_string isEqualToString:@"RTT"]) {
        TEXT_MODE=RTT;
    }
    NSLog(@"Text mode is %d",TEXT_MODE);
    //Log.d("TEXT_MODE ", TEXT_MODE);
    return TEXT_MODE;
}

-(void) showLatestMessage{
    if(self.tableView && self.chatEntries){
        NSUInteger indexArr[] = {self.chatEntries.count-1, 0};
        NSIndexPath *index = [[NSIndexPath alloc] initWithIndexes:indexArr length:2];
        if (index.section >= 0 && index.section < (int)self.chatEntries.count) {
            [self.tableView scrollToRowAtIndexPath:index atScrollPosition:UITableViewScrollPositionBottom animated:NO];
        }
    }
}

-(void) showCurrentRemoteTextBuffer{
    if(self.tableView && self.chatEntries){
        NSUInteger indexArr[] = {self.remoteTextBufferIndex, 0};
        NSIndexPath *index = [[NSIndexPath alloc] initWithIndexes:indexArr length:2];
        [self.tableView scrollToRowAtIndexPath:index atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }
}

-(void) showCurrentLocalTextBuffer{
    if(self.tableView && self.chatEntries){
        NSUInteger indexArr[] = {self.localTextBufferIndex, 0};
        NSIndexPath *index = [[NSIndexPath alloc] initWithIndexes:indexArr length:2];
        [self.tableView scrollToRowAtIndexPath:index atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
    }

}

#pragma mark Outgoing Text Logic
-(void)createNewLocalChatBuffer: (NSString*) text {
    self.localTextBuffer = [[RTTMessageModel alloc] initWithString:text];
    self.localTextBuffer.modifiedTimeInterval = self.year2037TimeStamp;
    self.localTextBuffer.color = [UIColor colorWithRed:0 green:0.55 blue:0.6 alpha:0.8];
    self.localColor = self.localTextBuffer.color;
    self.localTextBufferIndex = (int)self.chatEntries.count;
    [self.chatEntries addObject:self.localTextBuffer];
    if(self.isChatMode){
        [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 20, 0)];
        //[self sortChatEntriesArray];
        [self.tableView reloadData];
        [self showLatestMessage];
    }
}

-(void) insertTextIntoBuffer :(NSString*)text {
    
    int asciiCode = [text characterAtIndex:0];
    if (asciiCode == 0) {
        return;
    }
    
    int indx = self.localTextBufferIndex;
//    if ((int)self.chatEntries.count == 0) {
//        indx = 0;
//    } else {
//        indx = (int)self.chatEntries.count - 1;
//    }
    
    if(!self.localTextBuffer|| [text isEqualToString:@"\n"] ||[text isEqualToString:@"0x2028"]){
       
        RTTMessageModel *currentRttModel = [self.chatEntries lastObject];
        NSString *currentCharacter = currentRttModel.msgString;
        
        
        BOOL enter_pressed=[currentCharacter isEqualToString:@"\n"];
                   // if the last one is not mine and it's not a first my messages
            if ([currentRttModel.color isEqual:[UIColor colorWithRed:0 green:0.55 blue:0.6 alpha:0.8]] && (indx != 0) && enter_pressed) {
                return;
            }
            
            if (!enter_pressed) { // do not add row if previous mine is empty
                if (indx == 0) { // if it's the first message
                    [self createNewLocalChatBuffer:text];
                    return;
                } else {
                    self.localTextBuffer = [self.chatEntries objectAtIndex:indx];
                }
                
                // If the previous is my message
                if ([currentRttModel.color isEqual:[UIColor colorWithRed:0 green:0.55 blue:0.6 alpha:0.8]]) {
                    self.localTextBuffer.modifiedTimeInterval = [[NSDate new] timeIntervalSince1970];
                }
                
                [self createNewLocalChatBuffer:text];
                return;
            }
            else{
                [self createNewLocalChatBuffer:text];
                return;
            }
    }
    
    if (self.localTextBufferIndex == 0 && !self.localTextBuffer) { // if it's the first message after others
        [self createNewLocalChatBuffer:text];
        return;
    }
    
    self.localTextBuffer = [self.chatEntries objectAtIndex:indx];
    if(self.localTextBuffer){
        if(self.localTextBuffer.msgString.length + text.length >= RTT_MAX_PARAGRAPH_CHAR){
            [self createNewLocalChatBuffer:text];
            return;
        }
        if(self.localTextBuffer.msgString.length + text.length >= RTT_SOFT_MAX_PARAGRAPH_CHAR){
            if([text isEqualToString:@"."] || [text isEqualToString:@"!"] || [text isEqualToString:@"?"] || [text isEqualToString:@","]){
                [self.localTextBuffer.msgString appendString: text];
                [self.chatEntries setObject:self.localTextBuffer atIndexedSubscript:indx];
                [self createNewLocalChatBuffer:@""];
                return;
            }
        }
        [self.localTextBuffer.msgString appendString: text];
        [self.chatEntries setObject:self.localTextBuffer atIndexedSubscript:indx];

        if(self.isChatMode){
           // [self sortChatEntriesArray];
            [self.tableView reloadData];
            [self showLatestMessage];
        }
    }
}

-(void) backspaceInLocalBuffer{
    if(!self.localTextBuffer){
        return;
    }
    self.localTextBuffer = [self.chatEntries objectAtIndex:self.localTextBufferIndex];
    if(self.localTextBuffer){
        if(self.localTextBuffer.msgString.length > 0){
            [self.localTextBuffer removeLast];
            [self.chatEntries setObject:self.localTextBuffer atIndexedSubscript:self.localTextBufferIndex];
            if(self.isChatMode){
               // [self sortChatEntriesArray];
                [self.tableView reloadData];
                [self showLatestMessage];
            }
        }
    }
}

/* Called when text is inserted */
- (void)insertText:(NSString *)theText {
    // Send a character.
    bool enter_pressed=false;
    unichar c = [theText characterAtIndex:0];
    /* A Line Separator that should be added. */
    if (c == '\n'){
        c = 0x2028;
        enter_pressed=true;
    }
//Remove verbose logging
//    NSLog(@"theText %@",theText);
//    NSLog(@"Add characters. %@ Core %s", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
//          linphone_core_get_version());
//    NSLog(@"insertText %@",self.localTextBuffer.msgString);
    LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
    if(!call){ return; }
    
    LinphoneChatRoom* room = linphone_call_get_chat_room(call);
    LinphoneChatMessage* msg = linphone_chat_room_create_message(room, "");

    
    int TEXT_MODE=[self getTextMode];
    
    if(TEXT_MODE==RTT){
            linphone_chat_message_put_char(msg, c);
    }else if(TEXT_MODE==SIP_SIMPLE){
        //NSLog(@"self.localTextBuffer.msgString %@",self.localTextBuffer.msgString);
        if(enter_pressed){
            NSLog(@"enter_pressed");
            for (int j = 0; j != self.localTextBuffer.msgString.length; j++){
                NSLog(@"Sending char %hu",[self.localTextBuffer.msgString characterAtIndex:j]);
                unichar c1 = [self.localTextBuffer.msgString characterAtIndex:j];
                if (c1 == '\n'){
                    c1 = 0x2028;
                }
                linphone_chat_message_put_char(msg, c1);
            }
        }
    }
    [self insertTextIntoBuffer:theText];
    
}
/* Called when backspace is inserted */
- (void)deleteBackward {
    
    // Send a backspace.
    NSLog(@"Remove one sign. %@ Core %s", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
          linphone_core_get_version());
    
    LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
    LinphoneChatRoom* room = linphone_call_get_chat_room(call);
    LinphoneChatMessage* msg = linphone_chat_room_create_message(room, "");
    linphone_chat_message_put_char(msg, (char)8);
    
    [self backspaceInLocalBuffer];
    }

#pragma mark Incoming Text Logic
/* Text is recevied and should be handled. */
- (void)textComposeEvent:(NSNotification *)notif {
    LinphoneChatRoom *room = [[[notif userInfo] objectForKey:@"room"] pointerValue];
    if (room) {
        uint32_t c = linphone_chat_room_get_char(room);
        
        if (c == 0x2028 || c == 10){ // In case of enter.
            [self performSelectorOnMainThread:@selector(runonmainthread:) withObject:@"\n" waitUntilDone:NO];
        }
        else if (c == '\b' || c == 8){ // In case of backspace.
            [self performSelectorOnMainThread:@selector(runonmainthreadremove) withObject:nil waitUntilDone:NO];
        }
        else// In case of everything else except empty.
        {
            NSLog(@"The logging: %d", c);
            NSString * string = [NSString stringWithFormat:@"%C", (unichar)c];
            [self performSelectorOnMainThread:@selector(runonmainthread:) withObject:string waitUntilDone:NO];
        }
    }
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
        return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (BOOL) shouldAutorotate
{
    return TRUE;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    //	Prefer (force) landscape if currently in landscape
    return UIInterfaceOrientationLandscapeRight;
}

#pragma mark Incoming Text Logic
NSMutableString *msgBuffer;

-(void) insertTextIntoMinimizedTextBuffer:(NSString*) text{
    if(!self.isChatMode){
        if(![text isEqualToString:@""]){
            if([self.incomingTextView isHidden]){
                [self.closeChatButton setEnabled:YES];
                
                [self.incomingTextView setHidden:NO];
                [self.closeChatButton setHidden:NO];
                
                msgBuffer = [[NSMutableString alloc] initWithString:@""];
                [self.incomingTextView setText:msgBuffer];
            }
            
            [msgBuffer appendString:text];
            [self.incomingTextView setText:msgBuffer];
            if(self.incomingTextView.text.length > 0 ) {
                NSRange range = NSMakeRange(self.incomingTextView.text.length-1, 1);
                [self.incomingTextView scrollRangeToVisible:range];

            }
        }
    }
    
}

-(void)createNewRemoteChatBuffer: (NSString*) text {
    self.remoteTextBuffer = [[RTTMessageModel alloc] initWithString:text];
    self.remoteTextBuffer.color = [UIColor lightGrayColor];
    self.remoteTextBuffer.modifiedTimeInterval = self.year2036TimeStamp;

    self.remoteTextBufferIndex = (int)self.chatEntries.count;
    
    [self.chatEntries addObject:self.remoteTextBuffer];
    [self.tableView setContentInset:UIEdgeInsetsMake(0, 0, 20, 0)];
   // [self sortChatEntriesArray];
    [self.tableView reloadData];
    [self showLatestMessage];
    [self insertTextIntoMinimizedTextBuffer:text];
}

-(void) insertTextIntoRemoteBuffer :(NSString*) text {
    
    int asciiCode = [text characterAtIndex:0];
    if (asciiCode == 0) {
        return;
    }
    int index = self.remoteTextBufferIndex;
//    if ((int)self.chatEntries.count == 0) {
//        index = 0;
//    } else if (self.localTextBufferIndex < 0) { // no local message
//        index = (int)self.chatEntries.count - 1;
//    } else {
//        index = (int)self.chatEntries.count - 2;
//    }

    if(!self.remoteTextBuffer|| [text isEqualToString:@"\n"] || [text isEqualToString:@"0x2028"]) {
        
        if (![self.remoteTextBuffer.msgString isEqualToString:@"\n"]) { // do not add row if previous is empty
            
            if (index == 0 && ((int)self.chatEntries.count == 0)) {
                [self createNewRemoteChatBuffer:text];
                return;
            }
            
            if (index >= 0) {
                self.remoteTextBuffer = [self.chatEntries objectAtIndex:index];
                self.remoteTextBuffer.modifiedTimeInterval = [[NSDate new] timeIntervalSince1970];
            }
            
            [self createNewRemoteChatBuffer:text];
            
        }
        return;
    }

    self.remoteTextBuffer = [self.chatEntries objectAtIndex:index];
    
    if(self.remoteTextBuffer){
        if(self.remoteTextBuffer.msgString.length + text.length >= RTT_MAX_PARAGRAPH_CHAR){
            [self createNewRemoteChatBuffer:text];
            return;
        }
        if(self.remoteTextBuffer.msgString.length + text.length >= RTT_SOFT_MAX_PARAGRAPH_CHAR && self.remoteTextBuffer.msgString.length + text.length < RTT_MAX_PARAGRAPH_CHAR){
          
            if([text isEqualToString:@"."] || [text isEqualToString:@"!"] || [text isEqualToString:@"?"] || [text isEqualToString:@","]){
                [self.remoteTextBuffer.msgString appendString: text];
                [self.chatEntries setObject:self.remoteTextBuffer atIndexedSubscript:index];
                [self createNewRemoteChatBuffer:@""];
                return;
            }
        }
       // [self.remoteTextBuffer.msgString appendString:text];
        self.remoteTextBuffer.msgString = [[self.remoteTextBuffer.msgString stringByAppendingString:text] mutableCopy];
        
        [self.chatEntries setObject:self.remoteTextBuffer atIndexedSubscript:index];
        
        //[self sortChatEntriesArray];
        [self.tableView reloadData];
        [self insertTextIntoMinimizedTextBuffer:text];
        [self showLatestMessage];
    }
}

-(void) backspaceInRemoteBuffer{
    if(!self.remoteTextBuffer){
        return;
    }
    self.remoteTextBuffer = [self.chatEntries objectAtIndex:self.remoteTextBufferIndex];
    if(self.remoteTextBuffer){
        if(self.remoteTextBuffer.msgString.length > 0){
            [self.remoteTextBuffer removeLast];
            [self.chatEntries setObject:self.remoteTextBuffer atIndexedSubscript:self.remoteTextBufferIndex];
            if(self.isChatMode){
               // [self sortChatEntriesArray];
                [self.tableView reloadData];
                [self showLatestMessage];
            }
           else if(!self.isChatMode && msgBuffer){
                if (msgBuffer.length == 0)
                    return;
                [msgBuffer deleteCharactersInRange:NSMakeRange(msgBuffer.length -1,1)];
                [self.incomingTextView setText:msgBuffer];
            }
        }
    }
}

/* We want the code to be optimal so running gui changes on gui thread is a good way to go. */

NSMutableString *minimizedTextBuffer;
-(void)runonmainthread:(NSString*)text{
    [self insertTextIntoRemoteBuffer:text];
}

/* We want the code to be optimal so running gui changes on gui thread is a good way to go. */
-(void)runonmainthreadremove{
    [self backspaceInRemoteBuffer];
}
- (IBAction)onCloseChatButton:(id)sender {
    [self.incomingTextView setHidden:YES];
    [self.closeChatButton setHidden:YES];
    msgBuffer = [[NSMutableString alloc] initWithString:@""];
    [self.incomingTextView setText:msgBuffer];
}

-(void) openChatMessage: (UITapGestureRecognizer *)sender{
    if(!self.isFirstResponder){
        [self becomeFirstResponder];
        msgBuffer = [[NSMutableString alloc] initWithString:@""];
        [self.incomingTextView setText:msgBuffer];
    }
}

- (void)videoModeUpdate:(NSNotification*)notif {
    NSString *videoMode = [notif.userInfo objectForKey: @"videoModeStatus"];
    if ([videoMode isEqualToString:@"camera_mute_off"]) {
        [_cameraStatusModeImageView setImage:[UIImage imageNamed:@"camera_mute.png"]];
        [_blackCurtain addSubview:_cameraStatusModeImageView];
        [self.videoGroup insertSubview:_blackCurtain belowSubview:self.videoPreview];
    }
    if ([videoMode isEqualToString:@"isCameraMuted"] || [videoMode isEqualToString:@"camera_mute_on"]) {
        [_blackCurtain removeFromSuperview];
    }
}

CGRect keyboardFrame;
CGFloat remote_video_delta;
CGFloat chat_delta;
CGPoint chat_center;
BOOL didChatResize = NO;
- (void)keyboardWillShow:(NSNotification *)notification {
    if(self.isRTTEnabled){
        keyboardFrame =  [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGFloat keyboardPos = keyboardFrame.origin.y;
        
        remote_video_delta = (self.videoView.frame.origin.y +
                              self.videoView.frame.size.height) - keyboardPos;
        chat_delta = (self.tableView.frame.origin.y + self.tableView.frame.size.height) - keyboardPos;
        
         self.tableView.frame = CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y,
                                     self.tableView.frame.size.width,
                                     self.tableView.frame.size.height - chat_delta);
        [self showLatestMessage];
        CGPoint remote_video_center = CGPointMake(self.videoView.center.x, self.videoView.center.y - remote_video_delta);
        [self.videoView setCenter:remote_video_center];
        
        self.incomingTextView.text = @"";
        [self.incomingTextView setHidden:YES];
        [self.closeChatButton setHidden:YES];
        
        self.isChatMode = YES;
        [self.tableView setHidden:NO];
        [self hideControls];
        //[self sortChatEntriesArray];
        [self.tableView reloadData];
    }
}

- (void)keyboardWillBeHidden:(NSNotification *) notification{
    keyboardFrame =  [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardPos = keyboardFrame.origin.y;
    remote_video_delta = (self.videoView.frame.origin.y +
                          self.videoView.frame.size.height) - keyboardPos;

    CGPoint remote_video_center = CGPointMake(self.videoView.center.x, self.videoView.center.y - remote_video_delta);
    [self.videoView setCenter:remote_video_center];

    [self.incomingTextView setHidden:YES];
    [self.closeChatButton setHidden:YES];
 
    self.isChatMode = NO;
}

- (CGFloat)textViewHeightForAttributedText: (NSAttributedString*)text andWidth: (CGFloat)width {
    UITextView *calculationView = [[UITextView alloc] init];
    [calculationView setAttributedText:text];
    CGSize size = [calculationView sizeThatFits:CGSizeMake(width, FLT_MAX)];
    return size.height;
}

#pragma mark UITableView Methods
- (void)loadRTTChatTableView
{
    CGRect chatSize = self.view.frame;
    chatSize.size.width -= chatSize.size.width / 5;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - chatSize.size.width)/2, 0, chatSize.size.width, chatSize.size.height) style:UITableViewStylePlain];
    
    self.chatEntries = [[NSMutableArray alloc] init];
    
    [self.view addSubview:self.tableView];
    
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.alpha = 0.7;
    [self.tableView setScrollEnabled:YES];
    [self.tableView setHidden:YES];
  
    self.isChatMode = NO;

    RTT_MAX_PARAGRAPH_CHAR = 250;
    RTT_SOFT_MAX_PARAGRAPH_CHAR = 200;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.chatEntries.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor clearColor];
    return headerView;
}

#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    CGSize size;

    RTTMessageModel *msg = [self.chatEntries objectAtIndex:indexPath.section];
    
    if ([msg.msgString isEqualToString:@"\n"] || [msg.msgString isEqualToString:@""]) {
        return [UIFont systemFontSize] + 4.0f;
    } else {
        
        size = [cell.textLabel.text boundingRectWithSize:CGSizeMake(self.tableView.frame.size.width - [self minInsetForCell:nil atIndexPath:indexPath] - 30.0f, CGFLOAT_MAX)
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:[UIFont systemFontSize] + 4.0f]}
                                                 context:nil].size;
    }
    return size.height;
}


-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
   
    NSString *CellIdentifier = @"ChatCell";
    BubbleTableViewCell *cell = (BubbleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[BubbleTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundColor = self.tableView.backgroundColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.dataSource = self;
    }
    
    RTTMessageModel *msg = [self.chatEntries objectAtIndex:indexPath.section];
    
    if ([msg.color isEqual:[UIColor colorWithRed:0 green:0.55 blue:0.6 alpha:0.8]]) {
        cell.authorType = BubbleTableViewCellTypeSelf;
        cell.bubbleColor = BubbleColorBlue;
    } else {
        cell.authorType = BubbleTableViewCellTypeOther;
        cell.bubbleColor = BubbleColorGray;
    }
    
    if (msg.msgString.length > 1) {
        [cell.textLabel setAdjustsFontSizeToFitWidth:NO];
        [cell.textLabel setFont:[UIFont systemFontOfSize:[UIFont systemFontSize] + 4]];
        NSString *firstCharacter = [msg.msgString substringToIndex:1];
        NSString *stringWithoutNewLine = [msg.msgString substringFromIndex:1];
        if ([firstCharacter isEqualToString:@"\n"]) {
            cell.textLabel.text = stringWithoutNewLine;
        } else {
            cell.textLabel.text = msg.msgString;
        }
    } else {
        cell.textLabel.text = msg.msgString;
    }
    
    return cell;
}

#pragma mark - BubbleTableViewCellDataSourfce methods

- (CGFloat)minInsetForCell:(BubbleTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if(UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
    {
        return 80.0f;
    }
    
    return 20.0f;
}

//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
//    
//    if(decelerate) return;
//    
//    [self scrollViewDidEndDecelerating:scrollView];
//}

-(void)updateViewConstraints {
        [super updateViewConstraints];
        [self.minimizedTextScrollView setScrollEnabled:YES];
        [self.minimizedTextScrollView setUserInteractionEnabled:YES];
}

#pragma mark Singleton
+(InCallViewController*) sharedInstance{
    return instance;
}

- (void)sortChatEntriesArray {
    
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"modifiedTimeInterval"
                                                               ascending:YES];
    NSArray *descriptors = [NSArray arrayWithObject:descriptor];
    NSMutableArray *reverseOrder = [[self.chatEntries sortedArrayUsingDescriptors:descriptors] mutableCopy];
    [self.chatEntries removeAllObjects];
    for (RTTMessageModel *msgModel in reverseOrder) {
        [self.chatEntries addObject:msgModel];
    }

}

- (void)getBiggestTimeStamps {
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init] ;
    [dateFormatter setDateFormat:@"yyyy-MM-dd"] ;
    NSDate *date2037 = [dateFormatter dateFromString:@"2037-01-01"];
    NSDate *date2036 = [dateFormatter dateFromString:@"2036-01-01"];
    self.year2037TimeStamp = [date2037 timeIntervalSince1970];
    self.year2036TimeStamp = [date2036 timeIntervalSince1970];
}

- (void) createCallQuality {
    if (!callQualityImageView) {
        UIImage *image = [UIImage imageNamed:@"RTPquality_medium.png"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(30, 30, 30, 30) resizingMode:UIImageResizingModeStretch];
        callQualityImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
        [callQualityImageView setImage:image];
        [callQualityImageView setBackgroundColor:[UIColor clearColor]];
        callQualityImageView.hidden = YES;
        
        PhoneMainView *phoneMainView = [PhoneMainView instance];
        [phoneMainView.view addSubview:callQualityImageView];
    }
}

- (void) hideCallQualityView {
    callQualityImageView.hidden = YES;
}

- (void) callQualityTimerBody {
    LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);

    if (!callQualityImageView || !call)
        return;

    float quality = linphone_call_get_current_quality(call);
    CallQualityStatus tmpCallQualityStatus;
    if (quality < 2) {
        tmpCallQualityStatus = CallQualityStatusBad;
    } else if (quality < 3) {
        tmpCallQualityStatus = CallQualityStatusMedium;
    } else {
        tmpCallQualityStatus = CallQualityStatusGood;
    }

    if (callQualityStatus != tmpCallQualityStatus) {
        callQualityStatus = tmpCallQualityStatus;
        UIImage *image = nil;

        switch (callQualityStatus) {
            case CallQualityStatusBad: {
                image = [UIImage imageNamed:@"RTPquality_bad.png"];
            }
                break;
            case CallQualityStatusMedium: {
                image = [UIImage imageNamed:@"RTPquality_medium.png"];
            }
                break;
            default:
                break;
        }

        if (!image) {
            [callQualityImageView setImage:image];
        } else {
            image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(20, 20, 20, 20) resizingMode:UIImageResizingModeStretch];
            [callQualityImageView setImage:image];
        }
    }
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction
{
    return UITextWritingDirectionLeftToRight;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    return CGRectZero;
}

- (void)unmarkText
{
    
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
    return nil;
}
- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction
{
    return nil;
}
- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
    return nil;
}
- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range
{
    return nil;
}
- (NSComparisonResult)comparePosition:(UITextPosition *)position toPosition:(UITextPosition *)other
{
    return NSOrderedDescending;
}
- (void)dictationRecognitionFailed
{
}
- (void)dictationRecordingDidEnd
{
//    LinphoneCall *c = linphone_core_get_current_call([LinphoneManager getLc]);
//    if (c && linphone_call_get_state(c) == LinphoneCallStreamsRunning) {
//        
//    }
}
- (CGRect)firstRectForRange:(UITextRange *)range
{
    return CGRectZero;
}

- (CGRect)frameForDictationResultPlaceholder:(id)placeholder
{
    return CGRectZero;
}
- (void)insertDictationResult:(NSArray *)dictationResult
{
    LinphoneCall *c = linphone_core_get_current_call([LinphoneManager getLc]);
    if (c && linphone_call_get_state(c) == LinphoneCallStreamsRunning) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        //String text_mode=prefs.getString(getString(R.string.pref_text_settings_send_mode_key), "RTT");
        [defaults setObject:@"SIP_SIMPLE" forKey:@"pref_text_settings_send_mode_key"];
        [defaults synchronize];
        for(UIDictationPhrase *phrase in dictationResult){
            [self insertText:[phrase text]];
        }
        [self insertText:@"\n"];
        [defaults setObject:@"RTT" forKey:@"pref_text_settings_send_mode_key"];
        [defaults synchronize];
    }
}
- (id)insertDictationResultPlaceholder
{
    return @"";
}

- (NSInteger)offsetFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition
{
    return 0;
}
- (UITextPosition *)positionFromPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset
{
    return nil;
}
- (UITextPosition *)positionFromPosition:(UITextPosition *)position offset:(NSInteger)offset
{
    return nil;
}

- (UITextPosition *)positionWithinRange:(UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction
{
    return nil;
}
- (void)removeDictationResultPlaceholder:(id)placeholder willInsertResult:(BOOL)willInsertResult
{
}
- (void)replaceRange:(UITextRange *)range withText:(NSString *)text
{
}
- (NSArray *)selectionRectsForRange:(UITextRange *)range
{
    return nil;
}
- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange *)range
{
}
- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange
{
}

- (NSString *)textInRange:(UITextRange *)range
{
    return @"";
}
- (UITextRange *)textRangeFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition
{
    return [[UITextRange alloc] init];
}

@end
