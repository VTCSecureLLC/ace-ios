//
//  AsyncProviderLookupOperation.m
//  linphone
//
//  Created by Zack Matthews on 1/21/16.
//
//

#import "AsyncProviderLookupOperation.h"

const NSString *cdnProviderList = @"http://cdn.vatrp.net/domains.json";

@interface AsyncProviderLookupOperation()

@property NSMutableArray *cdnResources;
@property NSURLRequest *cdnRequest;
@property NSURLSession *urlSession;

@end


@implementation AsyncProviderLookupOperation

#pragma mark - Private Methods
- (NSString *)pathForImageCache {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *cachePath = [documentsDirectory stringByAppendingPathComponent:@"ImageCache"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return cachePath;
}

- (BOOL)cachedImageExistWithName:(NSString *)name {

    BOOL imageExist = NO;
    NSString *imagePath = [NSString stringWithFormat:@"%@/%@", [self pathForImageCache], name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
        imageExist = YES;
    }
    
    return imageExist;
}

- (void)downloadImageWithRemotePath:(NSString *)remotePath savePath:(NSString *)savePath {
    
    if (remotePath && savePath) {
        NSURL *imageURL = [NSURL URLWithString:remotePath];
        if (imageURL) {
            _urlSession = [NSURLSession sharedSession];
            [[_urlSession downloadTaskWithURL:imageURL
                           completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                               
                               if (!error && location) {
                                   NSURL *saveURL = [NSURL fileURLWithPath:savePath];
                                   if ([[NSFileManager defaultManager] fileExistsAtPath:savePath]) {
                                       [[NSFileManager defaultManager] removeItemAtURL:saveURL error:nil];
                                   }
                                   NSError *moveError = nil;
                                   [[NSFileManager defaultManager] moveItemAtURL:location toURL:saveURL error:&moveError];
                                   if (moveError) {
                                   }
                               }
                           }] resume];
        }
    }
}

- (void)downloadProviderImageWithPath:(NSString *)path domain:(NSString *)domain {

    NSString *namePart = [[domain lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    NSString *name = [NSString stringWithFormat:@"provider_%@.%@", namePart, [path pathExtension]];
    if (name) {
        BOOL imageExist = [self cachedImageExistWithName:name];
        if (!imageExist) {
            NSString *savePath = [[self pathForImageCache] stringByAppendingPathComponent:name];
            [self downloadImageWithRemotePath:path savePath:savePath];
        }
    }
}


#pragma mark - Instance Methods
//Load domains from provider and store them in NSUserDefaults
- (void)reloadProviderDomains {
    
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
                    
                    
                    [self downloadProviderImageWithPath:[resource objectForKey:@"icon2x"] domain:[resource objectForKey:@"name"]];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.delegate respondsToSelector:@selector(onProviderLookupFinished:)]) {
                        [self.delegate onProviderLookupFinished:_cdnResources];
                    }
                });
            }
        }
    }] resume];
}

@end
