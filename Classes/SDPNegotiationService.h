//
//  SDPNegotiationService.h
//  ACE
//
//  Created by Zack Matthews on 11/9/15.
//  Copyright © 2015 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LinphoneManager.h"
@interface SDPNegotiationService : NSObject

+(SDPNegotiationService*) sharedInstance;
+ (NSSet *)unsupportedCodecs;
+ (NSString *)getPreferenceForCodec: (const char*) name withRate: (int) rate;

-(void) initializeSDP: (LinphoneCore*) lc;
@end
