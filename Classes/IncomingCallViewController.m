/* IncomingCallViewController.m
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

#import "IncomingCallViewController.h"
#import "LinphoneManager.h"
#import "FastAddressBook.h"
#import "PhoneMainView.h"
#import "UILinphone.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioServices.h>

@implementation IncomingCallViewController

@synthesize addressLabel;
@synthesize avatarImage;
@synthesize call;
@synthesize delegate;
@synthesize ringCountLabel;
@synthesize ringLabel;
@synthesize flashingView;
#pragma mark - Lifecycle Functions

- (id)init {
    return [super initWithNibName:@"IncomingCallViewController" bundle:[NSBundle mainBundle]];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - ViewController Functions
- (void)displayIncrementedRingCount {
    ringCountLabel.hidden = NO;
    ringLabel.hidden = NO;
    [UIView transitionWithView: ringCountLabel
                      duration:[[LinphoneManager instance] lpConfigFloatForKey:@"outgoing_ring_duration" forSection:@"vtcsecure"]
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                    }
                    completion:^(BOOL finished) {
                         ringCountLabel.text = [@(ringCountLabel.text.intValue + 1) stringValue];
                    }];
}

- (void)stopRingCount {
    ringCountLabel.hidden = YES;
    ringLabel.hidden = YES;
    ringCountLabel.text = @"1";
}

-(void) toggleBackgroundColor {
    self.view.backgroundColor = [UIColor whiteColor];
    [UIView animateKeyframesWithDuration:[[LinphoneManager instance] lpConfigFloatForKey:@"incoming_flashred_frequency" forSection:@"vtcsecure"]
                                   delay:0.0 options:UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat | UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
        self.view.backgroundColor = [UIColor redColor];
        self.flashingView.backgroundColor = [UIColor redColor];
    } completion:nil];
    
}

-(void) viewDidLoad {
    [super viewDidLoad];
    ringCountLabel.hidden = YES;
    ringLabel.hidden = YES;
    ringCountLabel.text = @"1";
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    self.device = nil;
    if (captureDeviceClass != nil) {
        self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (![self.device hasTorch] || ![self.device hasFlash]) self.device = nil;
    }
}

- (void) toggleCameraLed {
    if (self.device != nil){
        [self.device lockForConfiguration:nil];
        if (self.device.torchMode == AVCaptureTorchModeOff){
            [self.device setTorchMode:AVCaptureTorchModeOn];
            [self.device setFlashMode:AVCaptureFlashModeOn];
        } else {
            [self.device setTorchMode:AVCaptureTorchModeOff];
            [self.device setFlashMode:AVCaptureFlashModeOff];
        }
        [self.device unlockForConfiguration];
    }
}

- (void) vibrate {
    [self displayIncrementedRingCount];
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

- (void) stopFlashCameraLed {
    if (self.cameraLedFlasherTimer != nil) {
        [self.cameraLedFlasherTimer invalidate];
        self.cameraLedFlasherTimer = nil;
        Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
        if (captureDeviceClass != nil) {
            AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            if ([device hasTorch] && [device hasFlash]){
                [device lockForConfiguration:nil];
                if (device.torchMode == AVCaptureTorchModeOn) {
                    [device setTorchMode:AVCaptureTorchModeOff];
                    [device setFlashMode:AVCaptureFlashModeOff];            }
                [device unlockForConfiguration];
            }
        }
    }
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
  
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callUpdateEvent:)
                                                 name:kLinphoneCallUpdate
                                               object:nil];
    
    // VTC Secure -
    // Red flashing + Vibrate + Camera Flash if possible

    [self toggleBackgroundColor];

    self.cameraLedFlasherTimer = [NSTimer scheduledTimerWithTimeInterval:[[LinphoneManager instance] lpConfigFloatForKey:@"incoming_flashlight_frequency" forSection:@"vtcsecure"]
                                                                  target:self
                                                                selector:@selector(toggleCameraLed)
                                                                userInfo:nil
                                                                 repeats:YES];
    [self.cameraLedFlasherTimer fire];

    self.vibratorTimer = [NSTimer scheduledTimerWithTimeInterval:[[LinphoneManager instance] lpConfigFloatForKey:@"outgoing_ring_duration" forSection:@"vtcsecure"]
                                                          target:self
                                                        selector:@selector(vibrate)
                                                        userInfo:nil
                                                         repeats:YES];
    [self.vibratorTimer fire];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view.layer removeAllAnimations];
    [self stopFlashCameraLed];
    [self.vibratorTimer invalidate];
    [self.flashBackgroundColorTimer invalidate];
    [self stopRingCount];
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kLinphoneCallUpdate
                                                  object:nil];
}


#pragma mark - UICompositeViewDelegate Functions

static UICompositeViewDescription *compositeDescription = nil;

+ (UICompositeViewDescription *)compositeViewDescription {
	if (compositeDescription == nil) {
		compositeDescription = [[UICompositeViewDescription alloc] init:@"IncomingCall"
																content:@"IncomingCallViewController"
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

#pragma mark - Event Functions
- (void)callUpdateEvent:(NSNotification *)notif {
	LinphoneCall *acall = [[notif.userInfo objectForKey:@"call"] pointerValue];
	LinphoneCallState astate = [[notif.userInfo objectForKey:@"state"] intValue];
	[self callUpdate:acall state:astate];

}

#pragma mark -

- (void)callUpdate:(LinphoneCall *)acall state:(LinphoneCallState)astate {
    if(linphone_core_get_calls_nb([LinphoneManager getLc]) > 1 && acall && linphone_call_get_state(acall) == LinphoneCallIncoming){
        linphone_core_decline_call([LinphoneManager getLc], acall, LinphoneReasonBusy);
    }
	if (call == acall && (astate == LinphoneCallEnd || astate == LinphoneCallError)) {
		[delegate incomingCallAborted:call];
		[self dismiss];
    } else if ([LinphoneManager.instance lpConfigBoolForKey:@"auto_answer"]) {
        const MSList *call_list = linphone_core_get_calls([LinphoneManager getLc]);
        if (ms_list_size(call_list) <= 1) {
            LinphoneCallState state = linphone_call_get_state(call);
            if (state == LinphoneCallIncomingReceived) {
                [self onAcceptClick:nil];
            }
        }
    }

}

- (void)dismiss {
	if ([[[PhoneMainView instance] currentView] equal:[IncomingCallViewController compositeViewDescription]]) {
		[[PhoneMainView instance] popCurrentView];
	}
}

- (void)update {
	[self view]; // Force view load

	[avatarImage setImage:[UIImage imageNamed:@"avatar_unknown.png"]];

	NSString *address = nil;
	const LinphoneAddress *addr = linphone_call_get_remote_address(call);
	if (addr != NULL) {
		BOOL useLinphoneAddress = true;
		// contact name
		char *lAddress = linphone_address_as_string_uri_only(addr);
		if (lAddress) {
			NSString *normalizedSipAddress = [FastAddressBook normalizeSipURI:[NSString stringWithUTF8String:lAddress]];
			ABRecordRef contact = [[[LinphoneManager instance] fastAddressBook] getContact:normalizedSipAddress];
			if (contact) {
				UIImage *tmpImage = [FastAddressBook getContactImage:contact thumbnail:false];
				if (tmpImage != nil) {
					dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, (unsigned long)NULL),
								   ^(void) {
									 UIImage *tmpImage2 = [UIImage decodedImageWithImage:tmpImage];
									 dispatch_async(dispatch_get_main_queue(), ^{
									   avatarImage.image = tmpImage2;
									 });
								   });
				}
				address = [FastAddressBook getContactDisplayName:contact];
				useLinphoneAddress = false;
			}
			ms_free(lAddress);
		}
		if (useLinphoneAddress) {
			const char *lDisplayName = linphone_address_get_display_name(addr);
			const char *lUserName = linphone_address_get_username(addr);
			if (lDisplayName)
				address = [NSString stringWithUTF8String:lDisplayName];
			else if (lUserName)
				address = [NSString stringWithUTF8String:lUserName];
		}
	}

	// Set Address
	if (address == nil) {
		address = @"Unknown";
	}
	[addressLabel setText:address];
}

#pragma mark - Property Functions

- (void)setCall:(LinphoneCall *)acall {
	call = acall;
	[self update];
	[self callUpdate:call state:linphone_call_get_state(call)];
}

#pragma mark - Action Functions

- (IBAction)onAcceptClick:(id)event {
	[self dismiss];
	[delegate incomingCallAccepted:call];
}

- (IBAction)onDeclineClick:(id)event {
	[self dismiss];
	[delegate incomingCallDeclined:call];
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

@end
