#import <Foundation/Foundation.h>
#import "LinphoneManager.h"
@interface SDPNegotiationService : NSObject

+(SDPNegotiationService*) sharedInstance;
+ (NSSet *)unsupportedCodecs;
+ (NSString *)getPreferenceForCodec: (const char*) name withRate: (int) rate;

-(void) initializeSDP: (LinphoneCore*) lc;
@end
