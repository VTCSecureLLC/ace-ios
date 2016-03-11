//
//  DefaultSettingsManager.m
//  linphone
//
//  Created by User on 17/12/15.
//
//

#import "DefaultSettingsManager.h"

#import <UIKit/UIKit.h>
#import "SRVResolver.h"

#define CONFIG_SETTINGS_URL @"http://cdn.vatrp.net/numbers.json"

@interface DefaultSettingsManager () <SRVResolverDelegate, NSURLConnectionDelegate>
{
    UIActivityIndicatorView *aiv;
}
@property (nonatomic, strong) SRVResolver *  resolver;

@end

@implementation DefaultSettingsManager

static DefaultSettingsManager *sharedInstance = nil;

+ (id)sharedInstance {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)parseDefaultConfigSettingsFromURL:(NSString*)configURL {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:configURL]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];

}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    if ([challenge previousFailureCount] == 0) {
        NSURLCredential *newCredential;
        if(self.sipRegisterUsernames && self.sipRegisterUsernames.count > 0 && self.sipAuthPassword){
        newCredential = [NSURLCredential credentialWithUser:self.sipRegisterUsernames[0]
                                                   password:self.sipAuthPassword
                                                persistence:NSURLCredentialPersistenceNone];
            [[challenge sender] useCredential:newCredential
                   forAuthenticationChallenge:challenge];
        }
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    [self storeToUserDefaults:jsonDict];
    [aiv stopAnimating];
    if ([self.delegate respondsToSelector:@selector(didFinishLoadingConfigData)]) {
        [self.delegate didFinishLoadingConfigData];
    }
}

- (void)parseDefaultConfigSettingsFromFile {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"config_defaults" ofType:@"json"];
    NSData *content = [[NSData alloc] initWithContentsOfFile:filePath];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:content options:kNilOptions error:nil];
    [self storeToUserDefaults:jsonDict];
}


- (void)parseDefaultConfigSettings:(NSString*)configAddress{
    //[self parseDefaultConfigSettingsFromURL];
    aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    aiv.center = [[[[UIApplication sharedApplication] delegate] window] rootViewController].view.center;
    [[[[[UIApplication sharedApplication] delegate] window] rootViewController].view addSubview:aiv];
    [aiv startAnimating];

    self.resolver = [[SRVResolver alloc] initWithSRVName:configAddress];
    self.resolver.delegate = self;
    [self.resolver start];
   // [self parseDefaultConfigSettingsFromFile];
}

- (void)clearDefaultConfigSettings {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
}

- (void)storeToUserDefaults:(NSDictionary*)dict {
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"version"] forKey:@"version"];
    
    [[NSUserDefaults standardUserDefaults] setInteger:[[dict objectForKey:@"expiration_time"] integerValue] forKey:@"expiration_time" ];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"configuration_auth_password"] != [NSNull null])?[dict objectForKey:@"configuration_auth_password"]:@"" forKey:@"configuration_auth_password"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"configuration_auth_expiration"] != [NSNull null])?[dict objectForKey:@"configuration_auth_expiration"]:@"" forKey:@"configuration_auth_expiration"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"sip_registration_maximum_threshold"] != [NSNull null])?[dict objectForKey:@"sip_registration_maximum_threshold"]:@"" forKey:@"sip_registration_maximum_threshold"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"sip_register_usernames"] != [NSNull null])?[dict objectForKey:@"sip_register_usernames"]:@"" forKey:@"sip_register_usernames"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"sip_auth_username"] != [NSNull null])?[dict objectForKey:@"sip_auth_username"]:@"" forKey:@"sip_auth_username"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"sip_auth_password"] != [NSNull null])?[dict objectForKey:@"sip_auth_password"]:@"" forKey:@"sip_auth_password"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"sip_register_domain"] != [NSNull null])?[dict objectForKey:@"sip_register_domain"]:@"" forKey:@"sip_register_domain"];
    
    [[NSUserDefaults standardUserDefaults] setInteger:([dict objectForKey:@"sip_register_port"] != [NSNull null])?[[dict objectForKey:@"sip_register_port"] integerValue]:0 forKey:@"sip_register_port"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"sip_register_transport"] != [NSNull null])?[dict objectForKey:@"sip_register_transport"]:@"" forKey:@"sip_register_transport"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"enable_echo_cancellation"] != [NSNull null])? [dict objectForKey:@"enable_echo_cancellation"]:@"" forKey:@"enable_echo_cancellation"];

    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"enable_video"] != [NSNull null])?[dict objectForKey:@"enable_video"]:@"" forKey:@"enable_video"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"enable_rtt"] != [NSNull null])?[dict objectForKey:@"enable_rtt"]:@"" forKey:@"enable_rtt"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"enable_adaptive_rate"] != [NSNull null])?[dict objectForKey:@"enable_adaptive_rate"]:@"" forKey:@"enable_adaptive_rate"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"enabled_codecs"] != [NSNull null])?[dict objectForKey:@"enabled_codecs"]:@"" forKey:@"enabled_codecs"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"bwLimit"] != [NSNull null])?[dict objectForKey:@"bwLimit"]:@"" forKey:@"bwLimit"];
    
    [[NSUserDefaults standardUserDefaults] setInteger:([dict objectForKey:@"upload_bandwidth"] != [NSNull null])?[[dict objectForKey:@"upload_bandwidth"] integerValue]:0 forKey:@"upload_bandwidth" ];
    
    [[NSUserDefaults standardUserDefaults] setInteger:([dict objectForKey:@"download_bandwidth"] != [NSNull null])?[[dict objectForKey:@"download_bandwidth"] integerValue]:0 forKey:@"download_bandwidth" ];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"enable_stun"] != [NSNull null])?[dict objectForKey:@"enable_stun"]:@"" forKey:@"enable_stun"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"stun_server"] != [NSNull null])?[dict objectForKey:@"stun_server"] : ([dict objectForKey:@"sip_register_domain"] != [NSNull null]) ? [dict objectForKey:@"sip_register_domain"] : @"" forKey:@"stun_server"];

    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"enable_ice"] != [NSNull null])? [dict objectForKey:@"enable_ice"]:@"" forKey:@"enable_ice"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"logging"] != [NSNull null])? [dict objectForKey:@"logging"]:@"" forKey:@"logging"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"sip_mwi_uri"] != [NSNull null])? [dict objectForKey:@"sip_mwi_uri"]:@"" forKey:@"sip_mwi_uri"];
    
    [[NSUserDefaults standardUserDefaults] setObject:([dict objectForKey:@"sip_videomail_uri"] != [NSNull null])?[dict objectForKey:@"sip_videomail_uri"]:@"" forKey:@"sip_videomail_uri"];

    [[NSUserDefaults standardUserDefaults] synchronize];

}

#pragma mark set fields functions 

- (void)setSipRegisterUserNames:(NSArray *)sipRegisterUsernames {
    [[NSUserDefaults standardUserDefaults] setObject:sipRegisterUsernames forKey:@"sip_register_usernames"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setSipAuthUsername:(NSString *)sipAuthUsername {
    [[NSUserDefaults standardUserDefaults] setObject:sipAuthUsername forKey:@"sip_auth_username"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setSipAuthPassword:(NSString *)sipAuthPassword {
    [[NSUserDefaults standardUserDefaults] setObject:sipAuthPassword forKey:@"sip_auth_password"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setSipRegisterDomain:(NSString *)sipRegisterDomain {
    [[NSUserDefaults standardUserDefaults] setObject:[sipRegisterDomain stringByReplacingOccurrencesOfString:@"\"" withString:@""] forKey:@"sip_register_domain"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setSipRegisterPort:(int)sipRegisterPort {
    [[NSUserDefaults standardUserDefaults] setInteger:sipRegisterPort forKey:@"sip_register_port"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setSipRegisterTransport:(NSString*)transport {
    [[NSUserDefaults standardUserDefaults] setObject:transport forKey:@"sip_register_transport"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setSipMwUri:(NSString *)sipMwiUri {
    [[NSUserDefaults standardUserDefaults] setObject:sipMwiUri forKey:@"mwi_uri_preference"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setSipVideomailUri:(NSString *)sipVideomailUri {
    [[NSUserDefaults standardUserDefaults] setObject:sipVideomailUri forKey:@"video_mail_uri_preference"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - get fields functions

- (NSNumber*)version {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"version"];
}

- (NSString*)configAuthPassword {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"configuration_auth_password"];
}

- (int)exparitionTime {
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"expiration_time"];
}

- (NSString*)configAuthExpiration {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"configuration_auth_expiration"];
}

- (NSString*)sipRegistrationMaximumThreshold {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"sip_registration_maximum_threshold"];
}

- (NSMutableArray*)sipRegisterUsernames {
    return (NSMutableArray*)[[NSUserDefaults standardUserDefaults] objectForKey:@"sip_register_usernames"];
}

- (NSString*)sipRegisterUsername {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"sip_register_username"];
}

- (NSString*)sipAuthUsername {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"sip_auth_username"];
}

- (NSString*)sipAuthPassword {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"sip_auth_password"];
}

- (NSString*)sipRegisterDomain {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"sip_register_domain"];
}

- (int)sipRegisterPort {
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"sip_register_port"];
}

- (NSString*)sipRegisterTransport {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"sip_register_transport"];
}

- (BOOL)enableEchoCancellation {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_echo_cancellation"];
}

- (BOOL)enableVideo {
    if(![[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"enable_video"]){
        return YES;
    }
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_video"];
}

- (BOOL)enableRtt {
    if(![[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"enable_rtt"]){
        return YES;
    }
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_rtt"];
}

- (BOOL)enableAdaptiveRate {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_adaptive_rate"];
}

- (NSArray*)enabledCodecs {
    return [[self removeDotsFromArray:(NSArray*)[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled_codecs"]] copy];
}

- (NSString*)bwLimit {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"bwLimit"];
}

- (int)uploadBandwidth {
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"upload_bandwidth"];
}

- (int)downloadBandwidth {
    return (int)[[NSUserDefaults standardUserDefaults] integerForKey:@"download_bandwidth"];
}

- (BOOL)enableStun {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_stun"];
}

- (NSString*)stunServer {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"stun_server"];
}

- (BOOL)enableIce {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_ice"];
}

- (NSString*)logging {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"logging"];
}

- (NSString*)sipMwiUri {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"sip_mwi_uri"];
}

- (NSString*)sipVideomailUri {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"sip_videomail_uri"];
}

- (NSString*)videoResolutionMaximum {
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"video_preferred_size_preference"];
}

#pragma mark - helper functions

- (NSMutableArray*)removeDotsFromArray:(NSArray*)arrayWithDots {
    NSMutableArray *arrayWithoutArray = [NSMutableArray new];
    
    for (NSString *str in arrayWithDots) {
        NSString *stringWithoutDot = [str stringByReplacingOccurrencesOfString:@"." withString:@""];
        [arrayWithoutArray addObject:stringWithoutDot];
    }
    
    
    return arrayWithoutArray;
}

#pragma mark - SRVResolver delegate methods

- (void)srvResolver:(SRVResolver *)resolver didReceiveResult:(NSDictionary *)result {
    assert(resolver == self.resolver);
    #pragma unused(resolver)
    assert(result != nil);
    NSString *configURL = [result objectForKey:@"target"];
    NSString *configURLPath = [[@"https://" stringByAppendingString:configURL] stringByAppendingString:@"/config/v1/config.json"];
    [self parseDefaultConfigSettingsFromURL:configURLPath];
}

- (void)srvResolver:(SRVResolver *)resolver didStopWithError:(NSError *)error {
    assert(resolver == self.resolver);
    #pragma unused(resolver)
    NSLog(@"didStopWithError %@", error);
    [aiv stopAnimating];

    if(self.delegate){
        [self.delegate didFinishWithError];
    }
}

@end
