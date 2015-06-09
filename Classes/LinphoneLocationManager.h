
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LinphoneLocationManager : NSObject <CLLocationManagerDelegate>


- (NSString*)currentLocationAsText;
- (void)startMonitoring;
-(BOOL)isAuthorized:(BOOL)askUserIfUnknown;
+(LinphoneLocationManager *)sharedManager;
-(BOOL)locationPlausible;

@end
