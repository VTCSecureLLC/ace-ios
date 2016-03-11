//
//  DefaultSettingsManager.h
//  linphone
//
//  Created by User on 17/12/15.
//
//

#import <Foundation/Foundation.h>

@protocol DefaultSettingsManagerDelegate <NSObject>
- (void)didFinishLoadingConfigData;
-(void)didFinishWithError;
@end


@interface DefaultSettingsManager : NSObject <NSURLConnectionDelegate>

@property (readonly) NSNumber *version;
@property (readonly) int exparitionTime;
@property (readonly) NSString *configAuthPassword;
@property (readonly) NSString *configAuthExpiration;
@property (readonly) NSString *sipRegistrationMaximumThreshold;
@property (setter=setSipRegisterUserNames:, nonatomic) NSMutableArray *sipRegisterUsernames;
@property (setter=setSipAuthUsername:, nonatomic) NSString *sipAuthUsername;
@property (setter=setSipAuthPassword:, nonatomic) NSString *sipAuthPassword;
@property (setter=setSipRegisterDomain:, nonatomic) NSString *sipRegisterDomain;
@property (setter=setSipRegisterPort:, nonatomic) int sipRegisterPort;
@property (setter=setSipRegisterTransport:, nonatomic) NSString *sipRegisterTransport;
@property (readonly) BOOL enableEchoCancellation;
@property (readonly) BOOL enableVideo;
@property (readonly) BOOL enableRtt;
@property (readonly) BOOL enableAdaptiveRate;
@property (readonly) NSArray *enabledCodecs;
@property (readonly) NSString *bwLimit;
@property (readonly) int uploadBandwidth;
@property (readonly) int downloadBandwidth;
@property (readonly) BOOL enableStun;
@property (readonly) NSString *stunServer;
@property (readonly) BOOL enableIce;
@property (readonly) NSString *logging;
@property (setter=setSipMwUri:, nonatomic) NSString *sipMwiUri;
@property (setter=setSipVideomailUri:, nonatomic) NSString *sipVideomailUri;
@property (readonly) NSString *videoResolutionMaximum;

@property(nonatomic, weak) id<DefaultSettingsManagerDelegate> delegate;

+(DefaultSettingsManager*) sharedInstance;

- (void)parseDefaultConfigSettings:(NSString*)configAddress;
- (void)clearDefaultConfigSettings;

@end
