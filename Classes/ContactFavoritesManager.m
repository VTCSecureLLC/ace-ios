//
//  ContactFavoritesManager.m
//  linphone
//
//  Created by Zack Matthews on 3/15/16.
//
//

#import "ContactFavoritesManager.h"

@implementation ContactFavoritesManager

static NSString *favoritesID = @"ACE_FAVORITES";
+(NSArray*)getFavorites{
    NSArray *favorites = [[NSArray alloc] init];
    if([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:favoritesID]){
        favorites = [[NSUserDefaults standardUserDefaults] objectForKey:favoritesID];
    }
    return favorites;
}
+(BOOL)addFavorite:(ABRecordID)recordID{
    NSMutableArray *favorites = [[self getFavorites] mutableCopy];
    if([favorites containsObject:[NSNumber numberWithInt:recordID]]){
        return FALSE;
    }
    [favorites addObject:[NSNumber numberWithInt:(int)recordID]];
    [[NSUserDefaults standardUserDefaults] setObject:favorites forKey:favoritesID];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return TRUE;
}

+(BOOL)removeFavorite:(ABRecordID)recordID{
    NSMutableArray *favorites = [[self getFavorites] mutableCopy];
    if([favorites containsObject:[NSNumber numberWithInt:recordID]]){
        [favorites removeObject:[NSNumber numberWithInt:(int)recordID]];
        [[NSUserDefaults standardUserDefaults] setObject:favorites forKey:favoritesID];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return TRUE;
    }
    return FALSE;
}
@end
