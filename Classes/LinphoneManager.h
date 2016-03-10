/* LinphoneManager.h
 *
 * Copyright (C) 2011  Belledonne Comunications, Grenoble, France
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

#import <Foundation/Foundation.h>
#import <AVFoundation/AVAudioSession.h>
#import <SystemConfiguration/SCNetworkReachability.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <CoreTelephony/CTCallCenter.h>

#import <sqlite3.h>

#import "IASKSettingsReader.h"
#import "IASKSettingsStore.h"
#import "IASKAppSettingsViewController.h"
#import "FastAddressBook.h"
#import "Utils.h"
#import "InAppProductsManager.h"

#include "linphone/linphonecore.h"
#include "linphone/linphone_tunnel.h"

#define kREAL_TIME_TEXT_ENABLED @"kREAL_TIME_TEXT_ENABLED"
extern NSString *const LINPHONERC_APPLICATION_KEY;

extern NSString *const kLinphoneCoreUpdate;
extern NSString *const kLinphoneDisplayStatusUpdate;
extern NSString *const kLinphoneTextReceived;
extern NSString *const kLinphoneTextComposeEvent;
extern NSString *const kLinphoneCallUpdate;
extern NSString *const kLinphoneRegistrationUpdate;
extern NSString *const kLinphoneMainViewChange;
extern NSString *const kLinphoneAddressBookUpdate;
extern NSString *const kLinphoneLogsUpdate;
extern NSString *const kLinphoneSettingsUpdate;
extern NSString *const kLinphoneBluetoothAvailabilityUpdate;
extern NSString *const kLinphoneConfiguringStateUpdate;
extern NSString *const kLinphoneGlobalStateUpdate;
extern NSString *const kLinphoneNotifyReceived;
extern NSString *const kLinphoneFileTransferSendUpdate;
extern NSString *const kLinphoneFileTransferRecvUpdate;
extern NSString *const kLinphoneVideModeUpdate;

typedef enum _NetworkType {
    network_none = 0,
    network_2g,
    network_3g,
    network_4g,
    network_lte,
    network_wifi
} NetworkType;

typedef enum _TunnelMode {
    tunnel_off = 0,
    tunnel_on,
    tunnel_wwan,
    tunnel_auto
} TunnelMode;

typedef enum _Connectivity {
	wifi,
	wwan,
    none
} Connectivity;

extern const int kLinphoneAudioVbrCodecDefaultBitrate;

/* Application specific call context */
typedef struct _CallContext {
    LinphoneCall* call;
    bool_t cameraIsEnabled;
} CallContext;

struct NetworkReachabilityContext {
    bool_t testWifi, testWWan;
    void (*networkStateChanged) (Connectivity newConnectivity);
};

@interface LinphoneCallAppData :NSObject {
    @public
	bool_t batteryWarningShown;
    UILocalNotification *notification;
    NSMutableDictionary *userInfos;
	bool_t videoRequested; /*set when user has requested for video*/
    NSTimer* timer;
};
@end

typedef struct _LinphoneManagerSounds {
    SystemSoundID vibrate;
} LinphoneManagerSounds;

@interface LinphoneManager : NSObject {
@protected
	SCNetworkReachabilityRef proxyReachability;
	
@private
	NSTimer* mIterateTimer;
    NSMutableArray*  pushCallIDs;
	Connectivity connectivity;
	UIBackgroundTaskIdentifier pausedCallBgTask;
	UIBackgroundTaskIdentifier incallBgTask;
	CTCallCenter* mCallCenter;
    NSDate *mLastKeepAliveDate;
@public
    CallContext currentCallContextBeforeGoingBackground;
}

+ (LinphoneManager*)instance;
+ (LinphoneManager*)instanceWithUsername:(NSString*)userName andDomain:(NSString*)domainName;
- (bool)coreIsRunning;

+ (void)instanceRelease;

+ (LinphoneCore*) getLc;
+ (BOOL)runningOnIpad;
+ (BOOL)isNotIphone3G;
+ (BOOL)isCodecSupported: (const char*)codecName;
+ (NSString *)getUserAgent;

//Remove Unread Messages Count on iPhone
//+ (int)unreadMessageCount;

- (void)playMessageSound;
- (void)resetLinphoneCore;
- (void)startLinphoneCore;
- (void)destroyLinphoneCore;
- (BOOL)resignActive;
- (void)becomeActive;
- (BOOL)enterBackgroundMode;
- (void)addPushCallId:(NSString*) callid;
- (void)configurePushTokenForProxyConfig: (LinphoneProxyConfig*)cfg;
- (BOOL)popPushCallID:(NSString*) callId;
- (void)acceptCallForCallId:(NSString*)callid;
- (void)cancelLocalNotifTimerForCallId:(NSString*)callid;

+ (BOOL)langageDirectionIsRTL;
+ (void)kickOffNetworkConnection;
- (void)setupNetworkReachabilityCallback;

- (void)refreshRegisters;

- (bool)allowSpeaker;

- (void)configureVbrCodecs;
- (void)setLogsEnabled:(BOOL)enabled;

+ (BOOL)copyFile:(NSString*)src destination:(NSString*)dst override:(BOOL)override;
+ (NSString*)bundleFile:(NSString*)file;
+ (NSString*)documentFile:(NSString*)file;
+ (NSString*)cacheDirectory;

// Calls
- (void)acceptCall:(LinphoneCall *)call;
- (void)declineCall:(LinphoneCall *)call;
- (void)resumeCall:(LinphoneCall *)call;
- (void)call:(NSString *)address displayName:(NSString*)displayName transfer:(BOOL)transfer;

/**
 *  Terminates current call
 */
- (void)terminateCurrentCall;

/**
 *  Returns call log for call
 *
 *  @param call LinphoneCall object
 *
 *  @return LinphoneCallLog object
 */
- (LinphoneCallLog *)callLogForCall:(LinphoneCall *)call;

/**
 *  Returns callId string for call
 *
 *  @param call LinphoneCall object
 *
 *  @return callId string for call
 */
- (NSString *)callIdForCall:(LinphoneCall *)call;

/**
 *  Checks if video enabled for exact call
 *
 *  @param call LinphoneCall object
 *
 *  @return returns YES if video is enabled for exact call otherwise NO
 */
- (BOOL)isVideoEnabledForCall:(LinphoneCall *)call;

/**
 *  Returns call state for exact call
 *
 *  @param call LinphoneCall object
 *
 *  @return call state for given call
 */
- (LinphoneCallState)callStateForCall:(LinphoneCall *)call;

/**
 *  Returns current call for linphone core
 *
 *  @return LinphoneCall object
 */
- (LinphoneCall *)currentCall;


/**
 *  @brief Checks if chat enabled for exact call
 *
 *  @param call LinphoneCall object
 *
 *  @return returns YES if chat is enabled for exact call otherwise NO
 */
- (BOOL)isChatEnabledForCall:(LinphoneCall *)call;

/**
 *  @brief Enables or desables RTT messaging
 *
 *  @param call   LinphoneCall object
 *  @param avtive YES to enable RTT messaging NO otherwise
 */
- (void)changeRTTStateForCall:(LinphoneCall *)call avtive:(BOOL)avtive;

/**
 *  @brief Retruns call which in hold
 *
 *  @return LinphoneCall object
 */
- (LinphoneCall *)holdCall;

/**
 *  Takes view and sets makes it native video window
 *
 *  @param linphoneCore LinphoneCore object
 *  @param videoView    videoView which must be shown as partner's video screen
 */
- (void)setVideoWindowForLinphoneCore:(LinphoneCore *)linphoneCore toView:(UIView *)view;

/**
 *  Takes view and sets makes it native preview video window
 *
 *  @param linphoneCore LinphoneCore object
 *  @param videoView    videoView which must be shown as caller video screen
 */
- (void)setPreviewWindowForLinphoneCore:(LinphoneCore *)linphoneCore toView:(UIView *)view;

/**
 *  Returns calls count for LinphoneCore
 *
 *  @param linphoneCore LinphoneCore object
 *
 *  @return calls count for core
 */
- (NSUInteger)callsCountForLinphoneCore:(LinphoneCore *)linphoneCore;

/**
 *  Determines if camera is enabled for current call
 *
 *  @return YES if camera enabled, otherwise NO
 */
- (BOOL)isCameraEnabledForCurrentCall;

/**
 *  Enables camera for current call
 */
- (void)enableCameraForCurrentCall;

/**
 *  Disables camera for current call
 */
- (void)disableCameraForCurrentCall;

/**
 *  Tells whether the microphone is enabled
 *
 *  @return YES if the microphone is enabled, NO if disabled
 */
- (BOOL)isMicrophoneEnabled;

/**
 *  Enables microphone
 */
- (void)enableMicrophone;

/**
 *  Disables microphone
 */
- (void)disableMicrophone;

/**
 *  Tells whether the speaker is enabled
 *
 *  @return YES if speaker is enabled, NO if disabled
 */
- (BOOL)isSpeakerEnabled;

- (void)enableSpeaker;

- (void)disableSpeaker;

- (void)switchCamera;

- (void)fetchProfileImageWithCall:(LinphoneCall *)linphoneCall withCompletion:(void (^)(UIImage *image))completion;
- (NSString *)fetchAddressWithCall:(LinphoneCall *)linphoneCall;


+(id)getMessageAppDataForKey:(NSString*)key inMessage:(LinphoneChatMessage*)msg;
+(void)setValueInMessageAppData:(id)value forKey:(NSString*)key inMessage:(LinphoneChatMessage*)msg;

- (void)lpConfigSetString:(NSString*)value forKey:(NSString*)key;
- (void)lpConfigSetString:(NSString*)value forKey:(NSString*)key forSection:(NSString*)section;
- (NSString *)lpConfigStringForKey:(NSString *)key;
- (NSString*)lpConfigStringForKey:(NSString*)key forSection:(NSString*)section;
- (NSString *)lpConfigStringForKey:(NSString *)key withDefault:(NSString *)value;
- (NSString *)lpConfigStringForKey:(NSString *)key forSection:(NSString *)section withDefault:(NSString *)value;

- (void)lpConfigSetInt:(int)value forKey:(NSString *)key;
- (void)lpConfigSetInt:(int)value forKey:(NSString *)key forSection:(NSString *)section;
- (int)lpConfigIntForKey:(NSString *)key;
- (int)lpConfigIntForKey:(NSString *)key forSection:(NSString *)section;
- (int)lpConfigIntForKey:(NSString *)key withDefault:(int)value;
- (int)lpConfigIntForKey:(NSString *)key forSection:(NSString *)section withDefault:(int)value;

- (void)lpConfigSetBool:(BOOL)value forKey:(NSString*)key;
- (void)lpConfigSetBool:(BOOL)value forKey:(NSString*)key forSection:(NSString*)section;
- (BOOL)lpConfigBoolForKey:(NSString *)key;
- (BOOL)lpConfigBoolForKey:(NSString*)key forSection:(NSString*)section;
- (BOOL)lpConfigBoolForKey:(NSString *)key withDefault:(BOOL)value;
- (BOOL)lpConfigBoolForKey:(NSString *)key forSection:(NSString *)section withDefault:(BOOL)value;

- (float)lpConfigFloatForKey:(NSString*)key forSection:(NSString *)section;

- (void)silentPushFailed:(NSTimer*)timer;
void configH264HardwareAcell(bool encode, bool decode);
- (void)removeAllAccounts;
-(PayloadType*)findCodec:(NSString*)codec;
- (PayloadType*)findVideoCodec:(NSString*)codec;

@property (readonly) BOOL isTesting;
@property (readonly, strong) FastAddressBook* fastAddressBook;
@property Connectivity connectivity;
@property (readonly) NetworkType network;
@property (readonly) const char*  frontCamId;
@property (readonly) const char*  backCamId;
@property (strong, nonatomic) NSString* SSID;
@property (readonly) sqlite3* database;
@property (nonatomic, strong) NSData *pushNotificationToken;
@property (readonly) LinphoneManagerSounds sounds;
@property (readonly) NSMutableArray *logs;
@property (nonatomic, assign) BOOL speakerEnabled;
@property (nonatomic, assign) BOOL bluetoothAvailable;
@property (nonatomic, assign) BOOL bluetoothEnabled;
@property (readonly) ALAssetsLibrary *photoLibrary;
@property (nonatomic, assign) TunnelMode tunnelMode;
@property (readonly) NSString* contactSipField;
@property (readonly,copy) NSString* contactFilter;
@property (copy) void (^silentPushCompletion)(UIBackgroundFetchResult);
@property (readonly) BOOL wasRemoteProvisioned;
@property (readonly) LpConfig *configDb;
@property (readonly) InAppProductsManager *iapManager;
@property(strong, nonatomic) NSMutableArray *fileTransferDelegates;

@end