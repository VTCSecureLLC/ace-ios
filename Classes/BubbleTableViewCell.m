//
//  BubbleTableViewCell.m
//  linphone
//
//  Created by User on 23/12/15.
//
//

#import "BubbleTableViewCell.h"



@implementation BubbleTableViewCell
{
    CGRect screenRect;
    CGFloat BubbleWidthOffset;
    CGFloat BubbleImageSize;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        _bubbleView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _bubbleView.userInteractionEnabled = YES;
        [self.contentView addSubview:_bubbleView];
        
        self.textLabel.backgroundColor = [UIColor clearColor];
        self.textLabel.numberOfLines = 0;
        self.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.textLabel.textColor = [UIColor blackColor];
        self.textLabel.font = [UIFont systemFontOfSize:14.0];
        
        self.imageView.userInteractionEnabled = YES;
//        self.imageView.layer.cornerRadius = 5.0;
//        self.imageView.layer.masksToBounds = NO;
//        self.imageView.layer.shouldRasterize = YES;
        
        screenRect = [[UIScreen mainScreen] bounds];
        BubbleWidthOffset = 30.0f;
        BubbleImageSize = 50.0f;
    }
    
    return self;
}

- (void)setAuthorType:(AuthorType)type {
    _authorType = type;
    [self updateFramesForAuthorType:_authorType];
}

- (void)setImageForBubbleColor:(BubbleColor)color {
    self.bubbleView.image = [[UIImage imageNamed:[NSString stringWithFormat:@"Bubble-%lu.png", (long)color]] resizableImageWithCapInsets:UIEdgeInsetsMake(12.0f, 15.0f, 16.0f, 18.0f)];
}

- (void)layoutSubviews {
    [self updateFramesForAuthorType:self.authorType];
}

- (UITableView *)tableView {
    
    UIView *tableView = self.superview;
    while(tableView) {
        if([tableView isKindOfClass:[UITableView class]]) {
            return (UITableView *)tableView;
        }
        
        tableView = tableView.superview;
    }
    
    return nil;
}


- (void)updateFramesForAuthorType:(AuthorType)type {
    [self setImageForBubbleColor:self.bubbleColor];
    
    CGFloat minInset = 0.0f;
    if([self.dataSource respondsToSelector:@selector(minInsetForCell:atIndexPath:)]) {
        minInset = [self.dataSource minInsetForCell:self atIndexPath:[[self tableView] indexPathForCell:self]];
    }
    
    CGSize size;
    if (self.imageView.image) {
        size = [self.textLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - minInset - BubbleWidthOffset - BubbleImageSize - 8.0f, CGFLOAT_MAX)
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              attributes:@{NSFontAttributeName:self.textLabel.font}
                                                 context:nil].size;
    } else {
        if ([self.textLabel.text isEqualToString:@"\n"] || [self.textLabel.text isEqualToString:@""]) {
            size = CGSizeMake(self.frame.size.width - minInset - BubbleWidthOffset, 17);
        } else {
            
            size = [self.textLabel.text boundingRectWithSize:CGSizeMake(self.frame.size.width - minInset - BubbleWidthOffset, CGFLOAT_MAX)
                                                     options:NSStringDrawingUsesLineFragmentOrigin
                                                  attributes:@{NSFontAttributeName:self.textLabel.font}
                                                     context:nil].size;
        }
        
    }
    
    if(type == BubbleTableViewCellTypeSelf) {
        // For the future if we have avatar image
        if(self.imageView.image) {
            self.bubbleView.frame = CGRectMake(self.frame.size.width - (size.width + BubbleWidthOffset) - BubbleImageSize - 8.0f, self.frame.size.height - (size.height + 15.0f), size.width + BubbleWidthOffset, size.height + 15.0f);
            self.imageView.frame = CGRectMake(self.frame.size.width - BubbleImageSize - 5.0f, self.frame.size.height - BubbleImageSize - 2.0f, BubbleImageSize, BubbleImageSize);
            self.textLabel.frame = CGRectMake(self.frame.size.width - (size.width + BubbleWidthOffset - 10.0f) - BubbleImageSize - 8.0f, self.frame.size.height - (size.height + 15.0f) + 6.0f, size.width + BubbleWidthOffset - 23.0f, size.height);
        } else {
            
            self.bubbleView.frame = CGRectMake(20,
                                               0.0f,
                                               screenRect.size.width * 0.75,
                                               size.height + 15.0f);
            self.imageView.frame = CGRectZero;
            self.textLabel.frame = CGRectMake(30, 6.0f, size.width + BubbleWidthOffset - 23.0f, size.height);
            self.textLabel.textAlignment = NSTextAlignmentLeft;
            
        }
        
        self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        self.bubbleView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        self.bubbleView.transform = CGAffineTransformIdentity;
    } else {
        // For the future if we have avatar image
        if (self.imageView.image) {
            self.bubbleView.frame = CGRectMake(BubbleImageSize + 8.0f, self.frame.size.height - (size.height + 15.0f), size.width + BubbleWidthOffset, size.height + 15.0f);
            self.imageView.frame = CGRectMake(5.0, self.frame.size.height - BubbleImageSize - 2.0f, BubbleImageSize, BubbleImageSize);
            self.textLabel.frame = CGRectMake(BubbleImageSize + 8.0f + 16.0f, self.frame.size.height - (size.height + 15.0f) + 6.0f, size.width + BubbleWidthOffset - 23.0f, size.height);
        } else {
            self.bubbleView.frame = CGRectMake(0.0f,
                                               0.0f,
                                               screenRect.size.width * 0.75,
                                               size.height + 15.0f);
            
            self.imageView.frame = CGRectZero;
            self.textLabel.frame = CGRectMake(16.0f, 6.0f, size.width + BubbleWidthOffset - 23.0f, size.height);
            self.textLabel.textAlignment = NSTextAlignmentNatural;
        }
        
        self.textLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        self.bubbleView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        self.bubbleView.transform = CGAffineTransformIdentity;
        self.bubbleView.transform = CGAffineTransformMakeScale(-1.0f, 1.0f);
    }
}

- (void)setBubbleColor:(BubbleColor)color {
    _bubbleColor = color;
    [self setImageForBubbleColor:_bubbleColor];
}

@end
