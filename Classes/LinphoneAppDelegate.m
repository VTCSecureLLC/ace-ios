/* LinphoneAppDelegate.m
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

#import "PhoneMainView.h"
#import "linphoneAppDelegate.h"
#import "AddressBook/ABPerson.h"

#import "CoreTelephony/CTCallCenter.h"
#import "CoreTelephony/CTCall.h"

#import "LinphoneCoreSettingsStore.h"
#import "LinphoneLocationManager.h"

#include "LinphoneManager.h"
#include "linphone/linphonecore.h"

#import <HockeySDK/HockeySDK.h>

@implementation LinphoneAppDelegate

@synthesize configURL;
@synthesize window;

#pragma mark - Lifecycle Functions

- (id)init {
	self = [super init];
	if (self != nil) {
		self->startedInBackground = FALSE;
	}
	return self;
}

#pragma mark -

- (void)applicationDidEnterBackground:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));
	[[LinphoneManager instance] enterBackgroundMode];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));
	LinphoneCore *lc = [LinphoneManager getLc];
	LinphoneCall *call = linphone_core_get_current_call(lc);

	if (call) {
		/* save call context */
		LinphoneManager *instance = [LinphoneManager instance];
		instance->currentCallContextBeforeGoingBackground.call = call;
		instance->currentCallContextBeforeGoingBackground.cameraIsEnabled = linphone_call_camera_enabled(call);

		const LinphoneCallParams *params = linphone_call_get_current_params(call);
		if (linphone_call_params_video_enabled(params)) {
			linphone_call_enable_camera(call, false);
		}
	}

	if (![[LinphoneManager instance] resignActive]) {
	}
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));

	if (startedInBackground) {
		startedInBackground = FALSE;
		[[PhoneMainView instance] startUp];
		[[PhoneMainView instance] updateStatusBar:nil];
	}
	LinphoneManager *instance = [LinphoneManager instance];

	[instance becomeActive];

	LinphoneCore *lc = [LinphoneManager getLc];
	LinphoneCall *call = linphone_core_get_current_call(lc);
    
    // Resume current call after accepting/declining incomming audio/video call.
    if (call == NULL) {
        const MSList *call_list = linphone_core_get_calls([LinphoneManager getLc]);
        if (call_list) {
            int count = ms_list_size(call_list);
            if (count) {
                LinphoneCall *currentCall = (LinphoneCall*)call_list->data;
                if (currentCall) {
                    LinphoneCallState call_state = linphone_call_get_state(currentCall);
                    if (call_state == LinphoneCallPaused) {
                        
                        if (currentCall == instance->currentCallContextBeforeGoingBackground.call) {
                            const LinphoneCallParams *params = linphone_call_get_current_params(currentCall);
                            if (linphone_call_params_video_enabled(params)) {
                                linphone_call_enable_camera(currentCall, instance->currentCallContextBeforeGoingBackground.cameraIsEnabled);
                            }
                            instance->currentCallContextBeforeGoingBackground.call = 0;
                        }
                        linphone_core_resume_call([LinphoneManager getLc], currentCall);
                    }
                }
            }
        }
        
    }
    
	if (call) {
		if (call == instance->currentCallContextBeforeGoingBackground.call) {
			const LinphoneCallParams *params = linphone_call_get_current_params(call);
			if (linphone_call_params_video_enabled(params)) {
				linphone_call_enable_camera(call, instance->currentCallContextBeforeGoingBackground.cameraIsEnabled);
			}
			instance->currentCallContextBeforeGoingBackground.call = 0;
		} else if (linphone_call_get_state(call) == LinphoneCallIncomingReceived) {
			//[[PhoneMainView instance] displayIncomingCall:call];
			// in this case, the ringing sound comes from the notification.
			// To stop it we have to do the iOS7 ring fix...
			[self fixRing];
		}
	}
}

- (UIUserNotificationCategory *)getMessageNotificationCategory {

	UIMutableUserNotificationAction *reply = [[UIMutableUserNotificationAction alloc] init];
	reply.identifier = @"reply";
	reply.title = NSLocalizedString(@"Reply", nil);
	reply.activationMode = UIUserNotificationActivationModeForeground;
	reply.destructive = NO;
	reply.authenticationRequired = YES;

	UIMutableUserNotificationAction *mark_read = [[UIMutableUserNotificationAction alloc] init];
	mark_read.identifier = @"mark_read";
	mark_read.title = NSLocalizedString(@"Mark Read", nil);
	mark_read.activationMode = UIUserNotificationActivationModeBackground;
	mark_read.destructive = NO;
	mark_read.authenticationRequired = NO;

	NSArray *localRingActions = @[ mark_read, reply ];

	UIMutableUserNotificationCategory *localRingNotifAction = [[UIMutableUserNotificationCategory alloc] init];
	localRingNotifAction.identifier = @"incoming_msg";
	[localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextDefault];
	[localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextMinimal];

	return localRingNotifAction;
}

- (UIUserNotificationCategory *)getCallNotificationCategory {
	UIMutableUserNotificationAction *answer = [[UIMutableUserNotificationAction alloc] init];
	answer.identifier = @"answer";
	answer.title = NSLocalizedString(@"Answer", nil);
	answer.activationMode = UIUserNotificationActivationModeForeground;
	answer.destructive = NO;
	answer.authenticationRequired = YES;

	UIMutableUserNotificationAction *decline = [[UIMutableUserNotificationAction alloc] init];
	decline.identifier = @"decline";
	decline.title = NSLocalizedString(@"Decline", nil);
	decline.activationMode = UIUserNotificationActivationModeBackground;
	decline.destructive = YES;
	decline.authenticationRequired = NO;

	NSArray *localRingActions = @[ decline, answer ];

	UIMutableUserNotificationCategory *localRingNotifAction = [[UIMutableUserNotificationCategory alloc] init];
	localRingNotifAction.identifier = @"incoming_call";
	[localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextDefault];
	[localRingNotifAction setActions:localRingActions forContext:UIUserNotificationActionContextMinimal];

	return localRingNotifAction;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    #ifdef DEBUG
    NSLog(@"Debug: No crashes will be reported, %@ Core %s", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
          linphone_core_get_version());
    #else
        [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"387e68d79a17889131eed3ecf97effd7"];
        [[BITHockeyManager sharedHockeyManager] startManager];
        [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
    #endif
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    
    NSLog(@"Application Launching: %@ iPhone %@, %@ Core %s", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"], appVersion, [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
          linphone_core_get_version());
    
    UIApplication *app = [UIApplication sharedApplication];
	UIApplicationState state = app.applicationState;

    [[LinphoneLocationManager sharedManager] startMonitoring];
    
	LinphoneManager *instance = [LinphoneManager instance];
	BOOL background_mode = [instance lpConfigBoolForKey:@"backgroundmode_preference"];
	BOOL start_at_boot = [instance lpConfigBoolForKey:@"start_at_boot_preference"];

	if ([app respondsToSelector:@selector(registerUserNotificationSettings:)]) {
		/* iOS8 notifications can be actioned! Awesome: */
		UIUserNotificationType notifTypes =
			UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;

		NSSet *categories =
			[NSSet setWithObjects:[self getCallNotificationCategory], [self getMessageNotificationCategory], nil];
		UIUserNotificationSettings *userSettings =
			[UIUserNotificationSettings settingsForTypes:notifTypes categories:categories];
		[app registerUserNotificationSettings:userSettings];

		if (!instance.isTesting) {
			[app registerForRemoteNotifications];
		}
	} else {
		if (!instance.isTesting) {
			NSUInteger notifTypes =
				UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge;
			[app registerForRemoteNotificationTypes:notifTypes];
		}
	}

	if (state == UIApplicationStateBackground) {
		// we've been woken up directly to background;
		if (!start_at_boot || !background_mode) {
			// autoboot disabled or no background, and no push: do nothing and wait for a real launch
			/*output a log with NSLog, because the ortp logging system isn't activated yet at this time*/
            NSLog(@"Linphone launch doing nothing because start_at_boot or background_mode are not activated. %@ Core %s", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
                  linphone_core_get_version(), NULL);
			return YES;
		}
	}
	bgStartId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
	  LOGW(@"Background task for application launching expired.");
	  [[UIApplication sharedApplication] endBackgroundTask:bgStartId];
	}];

	[[LinphoneManager instance] startLinphoneCore];
	// initialize UI
	[self.window makeKeyAndVisible];
	[RootViewManager setupWithPortrait:(PhoneMainView *)self.window.rootViewController];
	[[PhoneMainView instance] startUp];
	[[PhoneMainView instance] updateStatusBar:nil];

	NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
	if (remoteNotif) {
		LOGI(@"PushNotification from launch received.");
		[self processRemoteNotification:remoteNotif];
	}
	if (bgStartId != UIBackgroundTaskInvalid)
		[[UIApplication sharedApplication] endBackgroundTask:bgStartId];

    
    // Make sure we set the default settings for text.
    if ([[LinphoneManager instance] lpConfigBoolForKey:@"defsettings" withDefault:YES]) {
        [[LinphoneManager instance] lpConfigSetBool:NO forKey:@"defsettings"];
        [[LinphoneManager instance] lpConfigSetBool:YES forKey:@"rtt"];
    }
    
     _logFileArray = [NSMutableArray new];
    
	return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
	LOGI(@"%@", NSStringFromSelector(_cmd));

	linphone_core_terminate_all_calls([LinphoneManager getLc]);

	// destroyLinphoneCore automatically unregister proxies but if we are using
	// remote push notifications, we want to continue receiving them
	if ([LinphoneManager instance].pushNotificationToken != nil) {
		//trick me! setting network reachable to false will avoid sending unregister
		linphone_core_set_network_reachable([LinphoneManager getLc], FALSE);
	}
	[[LinphoneManager instance] destroyLinphoneCore];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	NSString *scheme = [[url scheme] lowercaseString];
	if ([scheme isEqualToString:@"linphone-config"] || [scheme isEqualToString:@"linphone-config"]) {
		NSString *encodedURL =
			[[url absoluteString] stringByReplacingOccurrencesOfString:@"linphone-config://" withString:@""];
		self.configURL = [encodedURL stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		UIAlertView *confirmation = [[UIAlertView alloc]
				initWithTitle:NSLocalizedString(@"Remote configuration", nil)
					  message:NSLocalizedString(@"This operation will load a remote configuration. Continue ?", nil)
					 delegate:self
			cancelButtonTitle:NSLocalizedString(@"No", nil)
			otherButtonTitles:NSLocalizedString(@"Yes", nil), nil];
		confirmation.tag = 1;
		[confirmation show];
	} else {
		if ([[url scheme] isEqualToString:@"sip"]) {
			// remove "sip://" from the URI, and do it correctly by taking resourceSpecifier and removing leading and
			// trailing "/"
			NSString *sipUri = [[url resourceSpecifier]
				stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];

			DialerViewController *controller = DYNAMIC_CAST(
				[[PhoneMainView instance] changeCurrentView:[DialerViewController compositeViewDescription]],
				DialerViewController);
			if (controller != nil) {
				[controller setAddress:sipUri];
			}
		}
	}
	return YES;
}

- (void)fixRing {
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7) {
		// iOS7 fix for notification sound not stopping.
		// see http://stackoverflow.com/questions/19124882/stopping-ios-7-remote-notification-sound
		[[UIApplication sharedApplication] setApplicationIconBadgeNumber:1];
		[[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
	}
}

- (void)processRemoteNotification:(NSDictionary *)userInfo {

	NSDictionary *aps = [userInfo objectForKey:@"aps"];

	if (aps != nil) {
		NSDictionary *alert = [aps objectForKey:@"alert"];
		if (alert != nil) {
			NSString *loc_key = [alert objectForKey:@"loc-key"];
			/*if we receive a remote notification, it is probably because our TCP background socket was no more working.
			 As a result, break it and refresh registers in order to make sure to receive incoming INVITE or MESSAGE*/
			LinphoneCore *lc = [LinphoneManager getLc];
			if (linphone_core_get_calls(lc) == NULL) { // if there are calls, obviously our TCP socket shall be working
				linphone_core_set_network_reachable(lc, FALSE);
				[LinphoneManager instance].connectivity = none; /*force connectivity to be discovered again*/
				[[LinphoneManager instance] refreshRegisters];
				if (loc_key != nil) {

					NSString *callId = [userInfo objectForKey:@"call-id"];
					if (callId != nil) {
						[[LinphoneManager instance] addPushCallId:callId];
					} else {
						LOGE(@"PushNotification: does not have call-id yet, fix it !");
					}

					if ([loc_key isEqualToString:@"IM_MSG"]) {

						[[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription]];

					} else if ([loc_key isEqualToString:@"IC_MSG"]) {

						[self fixRing];
					}
				}
			}
		}
	}
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	LOGI(@"%@ : %@", NSStringFromSelector(_cmd), userInfo);

	[self processRemoteNotification:userInfo];
}

- (LinphoneChatRoom *)findChatRoomForContact:(NSString *)contact {
	const MSList *rooms = linphone_core_get_chat_rooms([LinphoneManager getLc]);
	const char *from = [contact UTF8String];
	while (rooms) {
		const LinphoneAddress *room_from_address = linphone_chat_room_get_peer_address((LinphoneChatRoom *)rooms->data);
		char *room_from = linphone_address_as_string_uri_only(room_from_address);
		if (room_from && strcmp(from, room_from) == 0) {
			return rooms->data;
		}
		rooms = rooms->next;
	}
	return NULL;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {

	LOGI(@"%@ - state = %ld", NSStringFromSelector(_cmd), (long)application.applicationState);

//	[self fixRing];

	if ([notification.userInfo objectForKey:@"callId"] != nil) {
		// some local notifications have an internal timer to relaunch themselves at specified intervals
		if ([[notification.userInfo objectForKey:@"timer"] intValue] == 1) {
			[[LinphoneManager instance] cancelLocalNotifTimerForCallId:[notification.userInfo objectForKey:@"callId"]];
		}
        LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
        if(call != NULL){
            [[PhoneMainView instance] displayIncomingCall:call];
        }
        
	} else if ([notification.userInfo objectForKey:@"from_addr"] != nil) {
		NSString *remoteContact = (NSString *)[notification.userInfo objectForKey:@"from_addr"];
		// Go to ChatRoom view
		[[PhoneMainView instance] changeCurrentView:[ChatViewController compositeViewDescription]];
		LinphoneChatRoom *room = [self findChatRoomForContact:remoteContact];
		ChatRoomViewController *controller = DYNAMIC_CAST(
			[[PhoneMainView instance] changeCurrentView:[ChatRoomViewController compositeViewDescription] push:TRUE],
			ChatRoomViewController);
		if (controller != nil && room != nil) {
			[controller setChatRoom:room];
		}
	} else if ([notification.userInfo objectForKey:@"callLog"] != nil) {
		NSString *callLog = (NSString *)[notification.userInfo objectForKey:@"callLog"];
		// Go to HistoryDetails view
		[[PhoneMainView instance] changeCurrentView:[HistoryViewController compositeViewDescription]];
		HistoryDetailsViewController *controller = DYNAMIC_CAST(
			[[PhoneMainView instance] changeCurrentView:[HistoryDetailsViewController compositeViewDescription]
												   push:TRUE],
			HistoryDetailsViewController);
		if (controller != nil) {
			[controller setCallLogId:callLog];
		}
	}
}

// this method is implemented for iOS7. It is invoked when receiving a push notification for a call and it has
// "content-available" in the aps section.
- (void)application:(UIApplication *)application
	didReceiveRemoteNotification:(NSDictionary *)userInfo
		  fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
	LOGI(@"%@ : %@", NSStringFromSelector(_cmd), userInfo);
	LinphoneManager *lm = [LinphoneManager instance];

	// save the completion handler for later execution.
	// 2 outcomes:
	// - if a new call/message is received, the completion handler will be called with "NEWDATA"
	// - if nothing happens for 15 seconds, the completion handler will be called with "NODATA"
	lm.silentPushCompletion = completionHandler;
	[NSTimer scheduledTimerWithTimeInterval:15.0
									 target:lm
								   selector:@selector(silentPushFailed:)
								   userInfo:nil
									repeats:FALSE];

	LinphoneCore *lc = [LinphoneManager getLc];
	// If no call is yet received at this time, then force Linphone to drop the current socket and make new one to
	// register, so that we get
	// a better chance to receive the INVITE.
	if (linphone_core_get_calls(lc) == NULL) {
		linphone_core_set_network_reachable(lc, FALSE);
		lm.connectivity = none; /*force connectivity to be discovered again*/
		[lm refreshRegisters];
	}
}


#pragma mark - VCard Functions
-(BOOL)application:(UIApplication *)application
           openURL:(NSURL *)url
 sourceApplication:(NSString *)sourceApplication
        annotation:(id)annotation
{
    // Make sure url indicates a file (as opposed to, e.g., http://)
    if (url != nil && [url isFileURL]) {
        NSData *vcard = [[NSData alloc] initWithContentsOfURL:url];
        ABRecordRef person = nil;
     
        CFDataRef vCardData = CFDataCreate(NULL, [vcard bytes], [vcard length]);
        ABAddressBookRef book = ABAddressBookCreate();
        ABRecordRef defaultSource = ABAddressBookCopyDefaultSource(book);
        CFArrayRef vCardPeople = ABPersonCreatePeopleInSourceWithVCardRepresentation(defaultSource, vCardData);
        for (CFIndex index = 0; index < CFArrayGetCount(vCardPeople); index++) {
            person = CFArrayGetValueAtIndex(vCardPeople, index);
            ABAddressBookAddRecord(book, person, NULL);
            CFRelease(person);
        }
        ABAddressBookSave(book, NULL);
        
        person = ABAddressBookGetPersonWithRecordID(book, ABRecordGetRecordID(person));
        if(person){
            ContactDetailsViewController *controller = DYNAMIC_CAST(
                                                                    [[PhoneMainView instance] changeCurrentView:[ContactDetailsViewController compositeViewDescription] push:TRUE],
                                                                    ContactDetailsViewController);
            if (controller != nil) {
                [controller setContact:person];
            }
        }
        // Indicate that we have successfully opened the URL
    }
    return YES;
}

#pragma mark - PushNotification Functions

- (void)application:(UIApplication *)application
	didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	LOGI(@"%@ : %@", NSStringFromSelector(_cmd), deviceToken);
	[[LinphoneManager instance] setPushNotificationToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	LOGI(@"%@ : %@", NSStringFromSelector(_cmd), [error localizedDescription]);
	[[LinphoneManager instance] setPushNotificationToken:nil];
}

#pragma mark - User notifications

- (void)application:(UIApplication *)application
	didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
	LOGI(@"%@", NSStringFromSelector(_cmd));
}

- (void)application:(UIApplication *)application
	handleActionWithIdentifier:(NSString *)identifier
		  forLocalNotification:(UILocalNotification *)notification
			 completionHandler:(void (^)())completionHandler {
	LOGI(@"%@", NSStringFromSelector(_cmd));
	if ([[UIDevice currentDevice].systemVersion floatValue] >= 8) {

		LinphoneCore *lc = [LinphoneManager getLc];
		LOGI(@"%@", NSStringFromSelector(_cmd));
		if ([notification.category isEqualToString:@"incoming_call"]) {
			if ([identifier isEqualToString:@"answer"]) {
				// use the standard handler
				[self application:application didReceiveLocalNotification:notification];
			} else if ([identifier isEqualToString:@"decline"]) {
				LinphoneCall *call = linphone_core_get_current_call(lc);
				if (call)
					linphone_core_decline_call(lc, call, LinphoneReasonDeclined);
			}
		} else if ([notification.category isEqualToString:@"incoming_msg"]) {
			if ([identifier isEqualToString:@"reply"]) {
				// use the standard handler
				[self application:application didReceiveLocalNotification:notification];
			} else if ([identifier isEqualToString:@"mark_read"]) {
				NSString *from = [notification.userInfo objectForKey:@"from_addr"];
				LinphoneChatRoom *room = linphone_core_get_chat_room_from_uri(lc, [from UTF8String]);
				if (room) {
					linphone_chat_room_mark_as_read(room);
					[[PhoneMainView instance] updateApplicationBadgeNumber];
				}
			}
		}
	}
	completionHandler();
}

- (void)application:(UIApplication *)application
	handleActionWithIdentifier:(NSString *)identifier
		 forRemoteNotification:(NSDictionary *)userInfo
			 completionHandler:(void (^)())completionHandler {
	LOGI(@"%@", NSStringFromSelector(_cmd));
	completionHandler();
}

#pragma mark - Remote configuration Functions (URL Handler)

- (void)ConfigurationStateUpdateEvent:(NSNotification *)notif {
	LinphoneConfiguringState state = [[notif.userInfo objectForKey:@"state"] intValue];
	if (state == LinphoneConfiguringSuccessful) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneConfiguringStateUpdate object:nil];
		[_waitingIndicator dismissWithClickedButtonIndex:0 animated:true];

		UIAlertView *error = [[UIAlertView alloc]
				initWithTitle:NSLocalizedString(@"Success", nil)
					  message:NSLocalizedString(@"Remote configuration successfully fetched and applied.", nil)
					 delegate:nil
			cancelButtonTitle:NSLocalizedString(@"OK", nil)
			otherButtonTitles:nil];
		[error show];
		[[PhoneMainView instance] startUp];
	}
	if (state == LinphoneConfiguringFailed) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:kLinphoneConfiguringStateUpdate object:nil];
		[_waitingIndicator dismissWithClickedButtonIndex:0 animated:true];
		UIAlertView *error =
			[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failure", nil)
									   message:NSLocalizedString(@"Failed configuring from the specified URL.", nil)
									  delegate:nil
							 cancelButtonTitle:NSLocalizedString(@"OK", nil)
							 otherButtonTitles:nil];
		[error show];
	}
}

- (void)showWaitingIndicator {
	_waitingIndicator = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Fetching remote configuration...", nil)
												   message:@""
												  delegate:self
										 cancelButtonTitle:nil
										 otherButtonTitles:nil];
	UIActivityIndicatorView *progress = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(125, 60, 30, 30)];
	progress.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
	if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
		[_waitingIndicator setValue:progress forKey:@"accessoryView"];
		[progress setColor:[UIColor blackColor]];
	} else {
		[_waitingIndicator addSubview:progress];
	}
	[progress startAnimating];
	[_waitingIndicator show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if ((alertView.tag == 1) && (buttonIndex == 1)) {
		[self showWaitingIndicator];
		[self attemptRemoteConfiguration];
	}
}

- (void)attemptRemoteConfiguration {

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(ConfigurationStateUpdateEvent:)
												 name:kLinphoneConfiguringStateUpdate
											   object:nil];
	linphone_core_set_provisioning_uri([LinphoneManager getLc], [configURL UTF8String]);
	[[LinphoneManager instance] destroyLinphoneCore];
	[[LinphoneManager instance] startLinphoneCore];
}

- (void)setLogArray:(NSMutableArray*)arrayToSet {
    _logFileArray = arrayToSet;
}

@end
