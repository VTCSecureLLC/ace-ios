//
//  AsyncProviderLookupOperation.h
//  linphone
//
//  Created by Zack Matthews on 1/21/16.
//
//

#import <Foundation/Foundation.h>


@protocol AsyncProviderLookupDelegate<NSObject>

- (void)onProviderLookupFinished:(NSMutableArray*)domains;

@end


@interface AsyncProviderLookupOperation : NSObject

@property (atomic, strong) id<AsyncProviderLookupDelegate> delegate;

#pragma mark - Instance Methods
- (void)reloadProviderDomains;

@end

