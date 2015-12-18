//
//  DefaultSettingsManager.m
//  linphone
//
//  Created by User on 17/12/15.
//
//

#import "DefaultSettingsManager.h"

#import <UIKit/UIKit.h>

#define CONFIG_SETTINGS_URL @"http://cdn.vatrp.net/numbers.json"

@implementation DefaultSettingsManager

static DefaultSettingsManager *sharedInstance = nil;

+ (id)sharedInstance {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)parseDefaultConfigSettingsFromURL {
    
    NSString *jsonUrlString = [NSString stringWithFormat:CONFIG_SETTINGS_URL];
    NSURL *url = [NSURL URLWithString:[jsonUrlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    UIActivityIndicatorView *aiv = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    aiv.center = [[[[UIApplication sharedApplication] delegate] window] rootViewController].view.center;
    [[[[[UIApplication sharedApplication] delegate] window] rootViewController].view addSubview:aiv];
    [aiv startAnimating];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        [self storeToUserDefaults:jsonDict];
        [aiv stopAnimating];
    }];

}

- (void)parseDefaultConfigSettingsFromFile {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"config_defaults" ofType:@"json"];
    NSData *content = [[NSData alloc] initWithContentsOfFile:filePath];
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:content options:kNilOptions error:nil];
    NSLog(@"CONFIG JSON ---- %@", jsonDict);
    [self storeToUserDefaults:jsonDict];
}

- (void)parseDefaultConfigSettings {
    //[self parseDefaultConfigSettingsFromURL];
    [self parseDefaultConfigSettingsFromFile];
}

- (void)clearDefaultConfigSettings {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
}

- (void)storeToUserDefaults:(NSDictionary*)dict {
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"version"] forKey:@"version"];
    
    [[NSUserDefaults standardUserDefaults] setInteger:[[dict objectForKey:@"expiration_time"] integerValue] forKey:@"expiration_time" ];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"configuration_auth_password"] forKey:@"configuration_auth_password"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"configuration_auth_expiration"] forKey:@"configuration_auth_expiration"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"sip_registration_maximum_threshold"] forKey:@"sip_registration_maximum_threshold"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"sip_register_usernames"]  forKey:@"sip_register_usernames"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"sip_auth_username"] forKey:@"sip_auth_username"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"sip_auth_password"] forKey:@"sip_auth_password"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"sip_register_domain"] forKey:@"sip_register_domain"];
    
    [[NSUserDefaults standardUserDefaults] setInteger:[[dict objectForKey:@"sip_register_port"] integerValue] forKey:@"sip_register_port"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"sip_register_transport"] forKey:@"sip_register_transport"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"enable_echo_cancellation"] forKey:@"enable_echo_cancellation"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"enable_video"] forKey:@"enable_video"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"enable_rtt"] forKey:@"enable_rtt"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"enable_adaptive_rate"] forKey:@"enable_adaptive_rate"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"enabled_codecs"] forKey:@"enabled_codecs"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"bwLimit"] forKey:@"bwLimit"];
    
    [[NSUserDefaults standardUserDefaults] setInteger:[[dict objectForKey:@"upload_bandwidth"] integerValue] forKey:@"upload_bandwidth" ];
    
    [[NSUserDefaults standardUserDefaults] setInteger:[[dict objectForKey:@"download_bandwidth"] integerValue] forKey:@"download_bandwidth" ];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"enable_stun"] forKey:@"enable_stun"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"stun_server"] forKey:@"stun_server"];

    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"enable_ice"] forKey:@"enable_ice"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"logging"] forKey:@"logging"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"sip_mwi_uri"] forKey:@"sip_mwi_uri"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"sip_videomail_uri"] forKey:@"sip_videomail_uri"];
    
    [[NSUserDefaults standardUserDefaults] setObject:[dict objectForKey:@"video_resolution_maximum"] forKey:@"video_resolution_maximum"];
    
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
    [[NSUserDefaults standardUserDefaults] setObject:sipRegisterDomain forKey:@"sip_register_domain"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setSipRegisterPort:(int)sipRegisterPort {
    [[NSUserDefaults standardUserDefaults] setInteger:sipRegisterPort forKey:@"sip_register_port"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setSipMwUri:(NSString *)sipMwiUri {
    [[NSUserDefaults standardUserDefaults] setObject:sipMwiUri forKey:@"sip_mwi_uri"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setSipVideomailUri:(NSString *)sipVideomailUri {
    [[NSUserDefaults standardUserDefaults] setObject:sipVideomailUri forKey:@"sip_videomail_uri"];
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
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_video"];
}

- (BOOL)enableRtt {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_rtt"];
}

- (BOOL)enableAdaptiveRate {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"enable_adaptive_rate"];
}

- (NSArray*)enabledCodecs {
    return (NSArray*)[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled_codecs"];
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
    return [[NSUserDefaults standardUserDefaults] stringForKey:@"video_resolution_maximum"];
}

@end
