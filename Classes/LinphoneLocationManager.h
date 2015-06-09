//
//  KILocationManager.h
//  Kireego
//
//  Created by Reshad Moussa on 06.08.12.
//  Copyright (c) 2012 Kireego SA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LinphoneLocationManager : NSObject <CLLocationManagerDelegate>


- (CLLocation*)recentLocation;

- (void)startMonitoring;

- (void)stopMonitoring;

-(BOOL)isAuthorized:(BOOL)askUserIfUnknown;

+(LinphoneLocationManager *)sharedManager;

-(BOOL)locationPlausible ;



@end
