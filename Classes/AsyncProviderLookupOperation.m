//
//  AsyncProviderLookupOperation.m
//  linphone
//
//  Created by Zack Matthews on 1/21/16.
//
//

#import "AsyncProviderLookupOperation.h"
@interface AsyncProviderLookupOperation()
@property NSMutableArray *cdnResources;
@property NSURLRequest *cdnRequest;
@property NSURLSession *urlSession;
@end

@implementation AsyncProviderLookupOperation

const NSString *cdnProviderList = @"http://cdn.vatrp.net/domains.json";

//Load domains from provider and store them in NSUserDefaults
-(void) reloadProviderDomains{
    _urlSession = [NSURLSession sharedSession];
    [[_urlSession dataTaskWithURL:[NSURL URLWithString:(NSString*)cdnProviderList] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSError *jsonParsingError = nil;
        if(data){
            NSArray *resources = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:0 error:&jsonParsingError];
            if(!jsonParsingError){
                NSDictionary *resource;
                _cdnResources = [[NSMutableArray alloc] init];
                for(int i=0; i < [resources count];i++){
                    resource= [resources objectAtIndex:i];
                    [_cdnResources addObject:[resource objectForKey:@"name"]];
                    NSLog(@"Loaded CDN Resource: %@", [resource objectForKey:@"name"]);
                    [[NSUserDefaults standardUserDefaults] setObject:[resource objectForKey:@"name"] forKey:[NSString stringWithFormat:@"provider%d", i]];
                    
                    [[NSUserDefaults standardUserDefaults] setObject:[resource objectForKey:@"domain"] forKey:[NSString stringWithFormat:@"provider%d_domain", i]];
                }
                if ([self.delegate respondsToSelector:@selector(onProviderLookupFinished:)]) {
                    [self.delegate onProviderLookupFinished:_cdnResources];
                }
            }
        }
    }] resume];
}
@end
