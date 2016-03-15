//
//  ContactFavoritesManager.h
//  linphone
//
//  Created by Zack Matthews on 3/15/16.
//
//

#import <Foundation/Foundation.h>
#import "VSContactsManager.h"
@interface ContactFavoritesManager : NSObject
+(NSArray*)getFavorites;
+(BOOL)addFavorite:(ABRecordID)recordID;
+(BOOL)removeFavorite:(ABRecordID)recordID;
@end
