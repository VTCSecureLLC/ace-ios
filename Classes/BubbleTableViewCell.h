//
//  BubbleTableViewCell.h
//  linphone
//
//  Created by User on 23/12/15.
//
//

#import <UIKit/UIKit.h>

@class BubbleTableViewCell;

@protocol BubbleTableViewCellDataSource <NSObject>
@optional
- (CGFloat)minInsetForCell:(BubbleTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

typedef NS_ENUM(NSUInteger, AuthorType) {
    BubbleTableViewCellTypeSelf = 0,
    BubbleTableViewCellTypeOther
};

typedef NS_ENUM(NSUInteger, BubbleColor) {
    BubbleColorBlue = 0,
    BubbleColorGray = 1
};

@interface BubbleTableViewCell : UITableViewCell

@property (nonatomic, strong, readonly) UIImageView *bubbleView;
@property (nonatomic, assign) AuthorType authorType;
@property (nonatomic, assign) BubbleColor bubbleColor;
@property (nonatomic, weak) id <BubbleTableViewCellDataSource> dataSource;

@end