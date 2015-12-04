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
const NSInteger SECURE_BUTTON_TAG = 5;

@interface InCallViewController()
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
@property (weak, nonatomic) IBOutlet UILabel *incomingTextField;


@end

@implementation InCallViewController {
	BOOL hiddenVolume;
    int RTT_MAX_PARAGRAPH_CHAR;
    int RTT_SOFT_MAX_PARAGRAPH_CHAR;
}

@synthesize callTableController;
@synthesize callTableView;

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
		self->singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showControls:)];
		self->videoZoomHandler = [[VideoZoomHandler alloc] init];
	}
	return self;
}

- (void)dealloc {

	[[PhoneMainView instance].view removeGestureRecognizer:singleFingerTap];

	// Remove all observer
	[[NSNotificationCenter defaultCenter] removeObserver:self];

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
    
    if(self.incomingTextField){
        [self.incomingTextField setText:@""];
        [self.incomingTextField setHidden:YES];

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
        [self.tableView reloadData];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (hideControlsTimer != nil) {
		[hideControlsTimer invalidate];
		hideControlsTimer = nil;
	}

	if (hiddenVolume) {
		[[PhoneMainView instance] setVolumeHidden:FALSE];
		hiddenVolume = FALSE;
	}
    
    if(self.incomingTextField){
        self.incomingTextField.text = @"";
        [self.incomingTextField setHidden:YES];
    }

	// Remove observer
	[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneCallUpdate object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	// Set observer
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(callUpdateEvent:)
												 name:kLinphoneCallUpdate
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
    [self.incomingTextField setHidden:YES];
    [self.incomingTextField setText:@""];
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

CGRect remoteVideoFrame;
CGPoint incomingTextChatModePos;

- (void)viewDidLoad {
	[super viewDidLoad];

	[singleFingerTap setNumberOfTapsRequired:1];
	[singleFingerTap setCancelsTouchesInView:FALSE];
	[[PhoneMainView instance].view addGestureRecognizer:singleFingerTap];

	[videoZoomHandler setup:videoGroup];
	videoGroup.alpha = 0;

	[videoCameraSwitch setPreview:videoPreview];

	[callTableController.tableView setBackgroundColor:[UIColor clearColor]]; // Can't do it in Xib: issue with ios4
	[callTableController.tableView setBackgroundView:nil];					 // Can't do it in Xib: issue with ios4

	UIPanGestureRecognizer *dragndrop =
		[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveVideoPreview:)];
	dragndrop.minimumNumberOfTouches = 1;
	[self.videoPreview addGestureRecognizer:dragndrop];

    if(self.incomingTextField){
        self.incomingTextField.text = @"";
        self.incomingTextField.backgroundColor = [UIColor blackColor];
        self.incomingTextField.textColor = [UIColor whiteColor];
        [self.incomingTextField setTextAlignment:NSTextAlignmentLeft];
        self.incomingTextField.text = @"";
        self.incomingTextField.alpha = 0.7;
        [self.incomingTextField setUserInteractionEnabled:YES];
        [self.incomingTextField setEnabled:YES];

        UITapGestureRecognizer *singleFingerTappedIncomingChat = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openChatMessage:)];
        singleFingerTappedIncomingChat.numberOfTouchesRequired = 1;
        singleFingerTappedIncomingChat.numberOfTapsRequired = 1;
        [singleFingerTappedIncomingChat setCancelsTouchesInView:NO];
        [self.incomingTextField addGestureRecognizer:singleFingerTappedIncomingChat];
        
        [self.incomingTextField canBecomeFirstResponder];
        [self.incomingTextField enableClipboard:YES];
        
        [self.incomingTextField setHidden:YES];
    }
    if(!self.closeChatButton && self.incomingTextField){
        
        [self.closeChatButton setHidden:YES];
    }
    
    // We listen for incoming text.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textComposeEvent:) name:kLinphoneTextComposeEvent object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    instance = self;
    [self loadRTTChatTableView];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	[[PhoneMainView instance].view removeGestureRecognizer:singleFingerTap];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
										 duration:(NSTimeInterval)duration {
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	// in mode display_filter_auto_rotate=0, no need to rotate the preview
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

	switch (state) {
	case LinphoneCallIncomingReceived:
	case LinphoneCallOutgoingInit: {
		if (linphone_core_get_calls_nb(lc) > 1) {
			[callTableController minimizeAll];
		}
	}
	case LinphoneCallConnected:
	case LinphoneCallStreamsRunning: {
        // check realtime text.
        if (linphone_call_params_realtime_text_enabled(linphone_call_get_current_params(call))){
        }
		// check video
		if (linphone_call_params_video_enabled(linphone_call_get_current_params(call))) {
			[self displayVideoCall:animated];
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
        if(self.incomingTextField){
            self.incomingTextField.text = @"";
        }
//        if(self.outgoingTextLabel){
//            self.outgoingTextLabel.text = @"";
//        }
		if (linphone_core_get_calls_nb(lc) <= 2 && !videoShown) {
			[callTableController maximizeAll];
		}
		break;
	}
	default:
		break;
	}
}

BOOL isTabBarShown = NO;
- (void)showControls:(id)sender {
    if(self.isFirstResponder || ![self.tableView isHidden]){
        [self resignFirstResponder];
        [self.tableView setHidden:YES];
        return;
    }
	if (hideControlsTimer) {
		[hideControlsTimer invalidate];
		hideControlsTimer = nil;
	}

	if ([[[PhoneMainView instance] currentView] equal:[InCallViewController compositeViewDescription]] && videoShown && !isTabBarShown) {
		// show controls
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		[[PhoneMainView instance] showTabBar:true];
		[[PhoneMainView instance] showStateBar:true];
		[callTableView setAlpha:1.0];
		[videoCameraSwitch setAlpha:1.0];
		[UIView commitAnimations];
        isTabBarShown = YES;
		// hide controls in 5 sec
		hideControlsTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
															 target:self
														   selector:@selector(hideControls:)
														   userInfo:nil
															repeats:NO];
	}
    
    else if(isTabBarShown){
        hideControlsTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                             target:self
                                                           selector:@selector(hideControls:)
                                                           userInfo:nil
                                                            repeats:NO];
        isTabBarShown = NO;
    }
}

- (void)hideControls:(id)sender {
	if (hideControlsTimer) {
		[hideControlsTimer invalidate];
		hideControlsTimer = nil;
	}

	if ([[[PhoneMainView instance] currentView] equal:[InCallViewController compositeViewDescription]] && videoShown) {
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		[videoCameraSwitch setAlpha:0.0];
		[callTableView setAlpha:0.0];
		[UIView commitAnimations];

		[[PhoneMainView instance] showTabBar:false];
		[[PhoneMainView instance] showStateBar:false];
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

	[videoZoomHandler resetZoom];

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

	if (hideControlsTimer != nil) {
		[hideControlsTimer invalidate];
		hideControlsTimer = nil;
	}

	[[PhoneMainView instance] fullScreen:false];
}

- (void)displayVideoCall:(BOOL)animated {
	[self enableVideoDisplay:animated];
}

- (void)displayTableCall:(BOOL)animated {
	[self disableVideoDisplay:animated];
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
-(void) showLatestMessage{
    if(self.tableView && self.chatEntries){
        NSUInteger indexArr[] = {self.chatEntries.count-1, 0};
        NSIndexPath *index = [[NSIndexPath alloc] initWithIndexes:indexArr length:2];
        [self.tableView scrollToRowAtIndexPath:index atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

-(void) showCurrentLocalTextBuffer{
    if(self.tableView && self.chatEntries){
        NSUInteger indexArr[] = {self.localTextBufferIndex, 0};
        NSIndexPath *index = [[NSIndexPath alloc] initWithIndexes:indexArr length:2];
        [self.tableView scrollToRowAtIndexPath:index atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }

}

#pragma mark Outgoing Text Logic
-(void)createNewLocalChatBuffer: (NSString*) text {
    self.localTextBuffer = [[RTTMessageModel alloc] initWithString:text];
    self.localTextBuffer.color = [UIColor colorWithRed:0 green:0 blue:150 alpha:0.6];
    self.localColor = self.localTextBuffer.color;
    self.localTextBufferIndex = (int)self.chatEntries.count;
    [self.chatEntries addObject:self.localTextBuffer];

    [self.tableView reloadData];
    [self showLatestMessage];
}
-(void) insertTextIntoBuffer :(NSString*) text{
    if(!self.localTextBuffer|| [text isEqualToString:@"\n"]){
        [self createNewLocalChatBuffer:text];
        return;
    }
    self.localTextBuffer = [self.chatEntries objectAtIndex:self.localTextBufferIndex];
    if(self.localTextBuffer){
        if(self.localTextBuffer.msgString.length + text.length >= RTT_MAX_PARAGRAPH_CHAR){
            [self createNewLocalChatBuffer:text];
            return;
        }
        if(self.localTextBuffer.msgString.length + text.length >= RTT_SOFT_MAX_PARAGRAPH_CHAR){
            if([text isEqualToString:@"."] || [text isEqualToString:@"!"] || [text isEqualToString:@"?"] || [text isEqualToString:@","]){
                [self.localTextBuffer.msgString appendString: text];
                [self.chatEntries setObject:self.localTextBuffer atIndexedSubscript:self.localTextBufferIndex];
                [self createNewLocalChatBuffer:@""];
                return;
            }
        }

            [self.localTextBuffer.msgString appendString: text];
            [self.chatEntries setObject:self.localTextBuffer atIndexedSubscript:self.localTextBufferIndex];
            [self.tableView reloadData];
            [self showCurrentLocalTextBuffer];
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
            [self.tableView reloadData];
            [self showLatestMessage];
        }
    }
}

/* Called when text is inserted */
- (void)insertText:(NSString *)theText {
    // Send a character.
    NSLog(@"Add characters. %@ Core %s", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
          linphone_core_get_version());
    
    LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
    LinphoneChatRoom* room = linphone_call_get_chat_room(call);
    LinphoneChatMessage* msg = linphone_chat_room_create_message(room, "");

    [self insertTextIntoBuffer:theText];
    
    for (int i = 0; i != theText.length; i++)
        linphone_chat_message_put_char(msg, [theText characterAtIndex:i]);
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

-(void)createNewRemoteChatBuffer: (NSString*) text {
    self.remoteTextBuffer = [[RTTMessageModel alloc] initWithString:text];
    self.remoteTextBuffer.color = [UIColor lightGrayColor];
    self.remoteTextBufferIndex = (int)self.chatEntries.count;
    
    [self.chatEntries addObject:self.remoteTextBuffer];
    [self.tableView reloadData];
    
    [self showLatestMessage];
}
-(void) insertTextIntoRemoteBuffer :(NSString*) text{
    if(!self.remoteTextBuffer|| [text isEqualToString:@"\n"]){
        [self createNewRemoteChatBuffer:text];
        return;
    }
    self.remoteTextBuffer = [self.chatEntries objectAtIndex:self.remoteTextBufferIndex];
    if(self.remoteTextBuffer){
        if(self.remoteTextBuffer.msgString.length + text.length >= RTT_MAX_PARAGRAPH_CHAR){
            [self createNewRemoteChatBuffer:text];
            return;
        }
        if(self.remoteTextBuffer.msgString.length + text.length >= RTT_SOFT_MAX_PARAGRAPH_CHAR && self.remoteTextBuffer.msgString.length + text.length < RTT_MAX_PARAGRAPH_CHAR){
          
            if([text isEqualToString:@"."] || [text isEqualToString:@"!"] || [text isEqualToString:@"?"] || [text isEqualToString:@","]){
                [self.remoteTextBuffer.msgString appendString: text];
                [self.chatEntries setObject:self.remoteTextBuffer atIndexedSubscript:self.remoteTextBufferIndex];
                [self createNewRemoteChatBuffer:@""];
                return;
            }
        }

            [self.remoteTextBuffer.msgString appendString:text];
            [self.chatEntries setObject:self.remoteTextBuffer atIndexedSubscript:self.remoteTextBufferIndex];
            [self.tableView reloadData];
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
            [self.tableView reloadData];
            [self showLatestMessage];
        }
    }
}

/* We want the code to be optimal so running gui changes on gui thread is a good way to go. */

NSMutableString *minimizedTextBuffer;
-(void)runonmainthread:(NSString*)text{
    [self insertTextIntoRemoteBuffer:text];
  
    if(!self.isChatMode){
        if([self.incomingTextField isHidden]){
            [self.incomingTextField setHidden:NO];

            [self.closeChatButton setHidden:NO];
            [self.closeChatButton setEnabled:YES];
             minimizedTextBuffer = [[NSMutableString alloc] init];
        }
        if(minimizedTextBuffer){
            [minimizedTextBuffer appendString:text];
            [self.incomingTextField setText:minimizedTextBuffer];
        }
    }
}

/* We want the code to be optimal so running gui changes on gui thread is a good way to go. */
-(void)runonmainthreadremove{
    [self backspaceInRemoteBuffer];
}
- (IBAction)onCloseChatButton:(id)sender {
    [self.incomingTextField setHidden:YES];
    [self.closeChatButton setHidden:YES];
}

-(void) openChatMessage: (UITapGestureRecognizer *)sender{
    if(!self.isFirstResponder){
        [self becomeFirstResponder];
    }
}

CGRect keyboardFrame;
- (void)keyboardWillShow:(NSNotification *)notification {
    if(self.videoView){ //set temp frames to restore view layout when keyboard is dismissed
        remoteVideoFrame = self.videoView.frame;
    }
    keyboardFrame =  [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardPos = keyboardFrame.origin.y;
    CGFloat delta = (self.videoView.frame.origin.y + self.videoView.frame.size.height) - keyboardPos;
    [self.videoView setFrame:CGRectMake(self.videoView.frame.origin.x,
                                            self.videoView.frame.origin.y - delta,
                                                self.videoView.frame.size.width,
                                                    self.videoView.frame.size.height)];

    self.incomingTextField.text = @"";
    [self.incomingTextField setHidden:YES];
    [self.closeChatButton setHidden:YES];
    
    self.isChatMode = YES;
    [self.tableView setHidden:NO];
    [self hideControls:self];
}

- (void)keyboardWillBeHidden:(NSNotification *) notification{
    [self.videoView setFrame:remoteVideoFrame];
    [self.incomingTextField setHidden:YES];
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
    CGRect chatSize = [[UIScreen mainScreen] applicationFrame];
    chatSize.size.height /= 3;
    chatSize.size.width = self.view.frame.size.width;
    self.tableView = [[UITableView alloc] initWithFrame:chatSize style:UITableViewStylePlain];
    self.chatEntries = [[NSMutableArray alloc] init];
    
    [self.view addSubview:self.tableView];
    
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView reloadData];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.alpha = 0.7;
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
    return 30;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = [UIColor clearColor];
    return headerView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

        RTTMessageModel *msg = [self.chatEntries objectAtIndex:indexPath.section];
    if(msg.attrMsgString){
            return [self textViewHeightForAttributedText:msg.attrMsgString andWidth:self.tableView.frame.size.width];
    }


    return [UIFont systemFontSize];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *MyIdentifier = [[NSString alloc] initWithFormat:@"%ld", (long)indexPath.section];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault  reuseIdentifier:MyIdentifier];
    }
    RTTMessageModel *msg = [self.chatEntries objectAtIndex:indexPath.section];
   
    cell.textLabel.text = msg.msgString;
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.textLabel.userInteractionEnabled = YES;
    cell.textLabel.numberOfLines = 0;

    if([msg.color isEqual:self.localColor]){
        cell.textLabel.textAlignment = NSTextAlignmentRight;
    }
    else{
        cell.textLabel.textAlignment = NSTextAlignmentLeft;
    }
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [cell.textLabel enableClipboard:YES];
    [cell.textLabel canBecomeFirstResponder];
    
    ((RTTMessageModel*)[self.chatEntries objectAtIndex:indexPath.section]).attrMsgString = cell.textLabel.attributedText;
    
    cell.backgroundColor = msg.color;
    cell.alpha = 0.6;
//    cell.autoresizesSubviews = YES;
//    cell.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    cell.userInteractionEnabled = YES;
    [cell canBecomeFirstResponder];

    return cell;
}

#pragma mark Singleton
+(InCallViewController*) sharedInstance{
    return instance;
}
@end
